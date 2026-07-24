import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import type { Area, MetrajDB, Mode, Point, Tag } from './types'
import { renderPage, loadPdfFromUrl, type PdfDoc } from './pdf'
import { loadDB, planUrl } from './db'
import { pointInPolygon, rectToPolygon, formatKg, formatTon } from './geometry'
import { exportExcel } from './export'

const AREA_COLORS = ['#0ea5e9', '#f59e0b', '#ec4899', '#14b8a6', '#8b5cf6', '#ef4444']
const TYPE_COLOR: Record<string, string> = { KOLON: '#2563eb', PERDE: '#7c3aed' }
const STORAGE_KEY = 'metraj-project-v1'

let idSeq = 0
const nextId = (p: string) => `${p}-${++idSeq}-${Date.now().toString(36)}`

export default function App() {
  const [db, setDb] = useState<MetrajDB | null>(null)
  const [err, setErr] = useState('')
  const [floorId, setFloorId] = useState('')
  const [pdf, setPdf] = useState<PdfDoc | null>(null)
  const [planMsg, setPlanMsg] = useState('')
  const [scale, setScale] = useState(1.4)
  const [canvasSize, setCanvasSize] = useState({ w: 0, h: 0 })

  const [tags, setTags] = useState<Tag[]>([])
  const [areas, setAreas] = useState<Area[]>([])
  const [mode, setMode] = useState<Mode>('rect')
  const [activeElement, setActiveElement] = useState<string | null>(null)
  const [search, setSearch] = useState('')

  const [draft, setDraft] = useState<Point[]>([])
  const [rectStart, setRectStart] = useState<Point | null>(null)
  const [rectCur, setRectCur] = useState<Point | null>(null)
  const [hoverTag, setHoverTag] = useState<Tag | null>(null)

  const canvasRef = useRef<HTMLCanvasElement>(null)
  const containerRef = useRef<HTMLDivElement>(null)
  const svgRef = useRef<SVGSVGElement>(null)
  const chainRef = useRef<Promise<void>>(Promise.resolve())
  const panRef = useRef<{ sx: number; sy: number; l: number; t: number } | null>(null)
  const dragStartRef = useRef<Point | null>(null)
  const dragCurRef = useRef<Point | null>(null)

  // ---- DB yükle ----
  useEffect(() => {
    loadDB()
      .then((d) => {
        setDb(d)
        setFloorId(d.floors.find((f) => f.planFile)?.id ?? d.floors[0]?.id ?? '')
      })
      .catch((e) => setErr(String(e)))
    // Kaydedilmiş projeyi geri yükle
    try {
      const raw = localStorage.getItem(STORAGE_KEY)
      if (raw) {
        const p = JSON.parse(raw)
        if (Array.isArray(p.tags)) setTags(p.tags)
        if (Array.isArray(p.areas)) setAreas(p.areas)
      }
    } catch {
      /* yok say */
    }
  }, [])

  // ---- Otomatik kaydet ----
  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({ tags, areas }))
  }, [tags, areas])

  // ---- Plan PDF yükle ----
  useEffect(() => {
    if (!db || !floorId) return
    const floor = db.floors.find((f) => f.id === floorId)
    if (!floor?.planFile) {
      setPdf(null)
      setPlanMsg('Bu kata ait plan PDF bulunamadı. Panodaki kat toplamları yine de geçerlidir.')
      return
    }
    let cancelled = false
    setPlanMsg('Plan yükleniyor…')
    loadPdfFromUrl(planUrl(floor.planFile))
      .then((doc) => {
        if (cancelled) return
        setPdf(doc)
        setPlanMsg('')
      })
      .catch((e) => !cancelled && setPlanMsg(String(e)))
    return () => {
      cancelled = true
    }
  }, [db, floorId])

  // ---- Sayfa render (seri) ----
  useEffect(() => {
    if (!pdf) return
    let cancelled = false
    chainRef.current = chainRef.current
      .then(async () => {
        if (cancelled || !canvasRef.current) return
        const r = await renderPage(pdf, 1, scale, canvasRef.current)
        if (!cancelled) setCanvasSize({ w: r.width, h: r.height })
      })
      .catch(() => {})
    return () => {
      cancelled = true
    }
  }, [pdf, scale])

  const floor = db?.floors.find((f) => f.id === floorId)

  // Bu kata ait elemanlar
  const floorElements = useMemo(() => {
    if (!db) return []
    return db.elements
      .filter((e) => e.byFloor[floorId] != null)
      .sort((a, b) => a.name.localeCompare(b.name, 'tr'))
  }, [db, floorId])

  const filteredElements = useMemo(() => {
    const q = search.trim().toLowerCase()
    return q ? floorElements.filter((e) => e.name.toLowerCase().includes(q)) : floorElements
  }, [floorElements, search])

  const floorTags = useMemo(() => tags.filter((t) => t.floorId === floorId), [tags, floorId])
  const floorAreas = useMemo(() => areas.filter((a) => a.floorId === floorId), [areas, floorId])
  const taggedNames = useMemo(() => new Set(floorTags.map((t) => t.elementName)), [floorTags])

  const weightOf = useCallback(
    (name: string) => db?.elements.find((e) => e.name === name)?.byFloor[floorId] ?? 0,
    [db, floorId],
  )

  const tagInAnyArea = useCallback(
    (t: Tag) => floorAreas.some((a) => pointInPolygon(t.x, t.y, a.points)),
    [floorAreas],
  )

  const areaStats = useMemo(() => {
    return floorAreas.map((a) => {
      const inside = floorTags.filter((t) => pointInPolygon(t.x, t.y, a.points))
      const uniq = new Map<string, number>()
      for (const t of inside) uniq.set(t.elementName, weightOf(t.elementName))
      const total = [...uniq.values()].reduce((s, v) => s + v, 0)
      return { area: a, count: uniq.size, total }
    })
  }, [floorAreas, floorTags, weightOf])

  const grand = useMemo(() => {
    const uniq = new Map<string, number>()
    for (const t of floorTags) if (tagInAnyArea(t)) uniq.set(t.elementName, weightOf(t.elementName))
    return [...uniq.values()].reduce((s, v) => s + v, 0)
  }, [floorTags, tagInAnyArea, weightOf])

  // ---- Koordinat ----
  const toBase = (cx: number, cy: number): Point => {
    const rect = svgRef.current!.getBoundingClientRect()
    return { x: (cx - rect.left) / scale, y: (cy - rect.top) / scale }
  }

  const onPointerDown = (e: React.PointerEvent) => {
    if (!pdf) return
    const p = toBase(e.clientX, e.clientY)
    if (mode === 'rect') {
      dragStartRef.current = p
      dragCurRef.current = p
      setRectStart(p)
      setRectCur(p)
      ;(e.target as Element).setPointerCapture(e.pointerId)
    } else if (mode === 'pan') {
      const c = containerRef.current!
      panRef.current = { sx: e.clientX, sy: e.clientY, l: c.scrollLeft, t: c.scrollTop }
      ;(e.target as Element).setPointerCapture(e.pointerId)
    }
  }

  const onPointerMove = (e: React.PointerEvent) => {
    if (mode === 'rect' && dragStartRef.current) {
      const q = toBase(e.clientX, e.clientY)
      dragCurRef.current = q
      setRectCur(q)
    } else if (mode === 'pan' && panRef.current) {
      const c = containerRef.current!
      c.scrollLeft = panRef.current.l - (e.clientX - panRef.current.sx)
      c.scrollTop = panRef.current.t - (e.clientY - panRef.current.sy)
    }
  }

  const onPointerUp = () => {
    const s = dragStartRef.current
    const c = dragCurRef.current
    if (mode === 'rect' && s && c) {
      if (Math.abs(s.x - c.x) > 4 && Math.abs(s.y - c.y) > 4) addArea(rectToPolygon(s, c))
      dragStartRef.current = null
      dragCurRef.current = null
      setRectStart(null)
      setRectCur(null)
    }
    panRef.current = null
  }

  const onSvgClick = (e: React.MouseEvent) => {
    if (!pdf) return
    const p = toBase(e.clientX, e.clientY)
    if (mode === 'polygon') setDraft((d) => [...d, p])
    else if (mode === 'tag' && activeElement) {
      setTags((t) => [...t, { id: nextId('tag'), floorId, elementName: activeElement, x: p.x, y: p.y }])
    }
  }

  const finishPolygon = () => {
    if (draft.length >= 3) addArea(draft)
    setDraft([])
  }

  const addArea = (points: Point[]) =>
    setAreas((a) => [
      ...a,
      {
        id: nextId('area'),
        floorId,
        name: `Alan ${floorAreas.length + 1}`,
        points,
        color: AREA_COLORS[floorAreas.length % AREA_COLORS.length],
      },
    ])

  const removeArea = (id: string) => setAreas((a) => a.filter((x) => x.id !== id))
  const renameArea = (id: string, name: string) =>
    setAreas((a) => a.map((x) => (x.id === id ? { ...x, name } : x)))
  const removeTag = (id: string) => setTags((t) => t.filter((x) => x.id !== id))

  const pickElement = (name: string) => {
    setActiveElement(name)
    setMode('tag')
  }

  const clearFloor = () => {
    setTags((t) => t.filter((x) => x.floorId !== floorId))
    setAreas((a) => a.filter((x) => x.floorId !== floorId))
    setDraft([])
  }

  const onWheel = (e: React.WheelEvent) => {
    if (!e.ctrlKey && !e.metaKey) return
    e.preventDefault()
    setScale((s) => Math.min(6, Math.max(0.3, s * (e.deltaY < 0 ? 1.1 : 0.9))))
  }

  // Proje kaydet/yükle (dosya)
  const saveProject = () => {
    const blob = new Blob([JSON.stringify({ tags, areas }, null, 1)], { type: 'application/json' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = 'metraj-projesi.json'
    a.click()
    URL.revokeObjectURL(url)
  }
  const loadProject = async (file: File) => {
    const p = JSON.parse(await file.text())
    if (Array.isArray(p.tags)) setTags(p.tags)
    if (Array.isArray(p.areas)) setAreas(p.areas)
  }

  const rectPreview = rectStart && rectCur ? rectToPolygon(rectStart, rectCur) : null
  const cursor = mode === 'pan' ? 'grab' : mode === 'tag' ? 'cell' : 'crosshair'
  const dash = floor && db?.floorTotals[floor.id]

  if (err)
    return (
      <div className="fatal">
        <h2>Veri yüklenemedi</h2>
        <p>{err}</p>
        <p>Uygulamayı <code>npm run dev</code> ile başlattığınızdan emin olun.</p>
      </div>
    )
  if (!db) return <div className="loading">Metraj verisi yükleniyor…</div>

  return (
    <div className="app">
      <header className="toolbar">
        <div className="brand">
          <span className="logo">▦</span>
          <div>
            <div className="title">Donatı Metrajı</div>
            <div className="subtitle">{db.project}</div>
          </div>
        </div>

        <div className="group">
          <label className="floor-label">KAT</label>
          <select className="floor-select" value={floorId} onChange={(e) => setFloorId(e.target.value)}>
            {db.floors.map((f) => (
              <option key={f.id} value={f.id}>
                {f.label} {f.planFile ? '' : '(plan yok)'}
              </option>
            ))}
          </select>
        </div>

        {pdf && (
          <>
            <div className="group">
              <button className="btn" onClick={() => setScale((s) => Math.max(0.3, s - 0.2))}>−</button>
              <span className="page">%{Math.round(scale * 100)}</span>
              <button className="btn" onClick={() => setScale((s) => Math.min(6, s + 0.2))}>+</button>
            </div>
            <div className="group modes">
              {(
                [
                  ['rect', '▭ Dikdörtgen'],
                  ['polygon', '⬠ Polygon'],
                  ['tag', '📍 İşaretle'],
                  ['pan', '✋ Kaydır'],
                ] as [Mode, string][]
              ).map(([m, label]) => (
                <button key={m} className={`btn ${mode === m ? 'active' : ''}`} onClick={() => setMode(m)}>
                  {label}
                </button>
              ))}
            </div>
            {mode === 'polygon' && draft.length > 0 && (
              <button className="btn ok" onClick={finishPolygon}>
                Alanı kapat ({draft.length})
              </button>
            )}
          </>
        )}

        <div className="spacer" />
        <button className="btn" onClick={saveProject}>⭳ Kaydet</button>
        <label className="btn">
          ⭱ Yükle
          <input type="file" accept="application/json" hidden onChange={(e) => e.target.files?.[0] && loadProject(e.target.files[0])} />
        </label>
        <button className="btn primary" onClick={() => exportExcel(db, tags, areas)} disabled={!areas.length}>
          ⭳ Excel
        </button>
      </header>

      <div className="body">
        <main className="stage" ref={containerRef} onWheel={onWheel} style={{ cursor: pdf ? cursor : 'default' }}>
          {!pdf ? (
            <div className="empty">
              <div className="empty-card">
                <div className="empty-icon">▤</div>
                <h2>{planMsg || 'Plan yükleniyor…'}</h2>
                <p>Üstteki <b>KAT</b> menüsünden bir kat seçin. Plan yüklendiğinde kolon/perdeleri işaretleyip alan seçebilirsiniz.</p>
              </div>
            </div>
          ) : (
            <div className="canvas-wrap" style={{ width: canvasSize.w, height: canvasSize.h }}>
              <canvas ref={canvasRef} />
              <svg
                ref={svgRef}
                className="overlay"
                width={canvasSize.w}
                height={canvasSize.h}
                onPointerDown={onPointerDown}
                onPointerMove={onPointerMove}
                onPointerUp={onPointerUp}
                onClick={onSvgClick}
              >
                {floorAreas.map((a) => (
                  <polygon
                    key={a.id}
                    points={a.points.map((p) => `${p.x * scale},${p.y * scale}`).join(' ')}
                    fill={a.color}
                    fillOpacity={0.12}
                    stroke={a.color}
                    strokeWidth={2}
                  />
                ))}
                {draft.length > 0 && (
                  <polyline
                    points={draft.map((p) => `${p.x * scale},${p.y * scale}`).join(' ')}
                    fill="none"
                    stroke="#0ea5e9"
                    strokeWidth={2}
                    strokeDasharray="6 4"
                  />
                )}
                {draft.map((p, i) => (
                  <circle key={i} cx={p.x * scale} cy={p.y * scale} r={4} fill="#0ea5e9" />
                ))}
                {rectPreview && (
                  <polygon
                    points={rectPreview.map((p) => `${p.x * scale},${p.y * scale}`).join(' ')}
                    fill="#0ea5e9"
                    fillOpacity={0.1}
                    stroke="#0ea5e9"
                    strokeWidth={2}
                    strokeDasharray="6 4"
                  />
                )}
                {floorTags.map((t) => {
                  const inside = tagInAnyArea(t)
                  const base = TYPE_COLOR[db.elements.find((e) => e.name === t.elementName)?.type ?? ''] ?? '#64748b'
                  return (
                    <g
                      key={t.id}
                      onMouseEnter={() => setHoverTag(t)}
                      onMouseLeave={() => setHoverTag(null)}
                      onDoubleClick={() => removeTag(t.id)}
                      style={{ cursor: 'pointer' }}
                    >
                      <circle
                        cx={t.x * scale}
                        cy={t.y * scale}
                        r={6}
                        fill={base}
                        stroke={inside ? '#16a34a' : '#fff'}
                        strokeWidth={inside ? 3 : 1.5}
                      />
                      <text x={t.x * scale + 9} y={t.y * scale + 4} fontSize={11} fontWeight={700} fill={base} stroke="#fff" strokeWidth={0.5}>
                        {t.elementName}
                      </text>
                    </g>
                  )
                })}
                {hoverTag && (
                  <g pointerEvents="none">
                    <rect x={hoverTag.x * scale + 8} y={hoverTag.y * scale - 24} width={130} height={20} rx={4} fill="#0f172a" opacity={0.92} />
                    <text x={hoverTag.x * scale + 14} y={hoverTag.y * scale - 10} fill="#fff" fontSize={11}>
                      {hoverTag.elementName}: {formatKg(weightOf(hoverTag.elementName))} kg
                    </text>
                  </g>
                )}
              </svg>
            </div>
          )}
          {planMsg && pdf === null && floor?.planFile && <div className="toast">{planMsg}</div>}
        </main>

        <aside className="sidebar">
          <section className="panel total-panel">
            <div className="total-label">SEÇİLİ ALANLARDAKİ TOPLAM (Kolon+Perde)</div>
            <div className="total-kg">{formatTon(grand)} ton</div>
            <div className="total-ton">{formatKg(grand)} kg</div>
          </section>

          {dash && (
            <section className="panel">
              <h3>{floor?.label} · Kat Toplamı</h3>
              <div className="dash">
                {Object.entries(dash).map(([k, v]) => (
                  <div className="dash-card" key={k}>
                    <span className="dash-t">{k}</span>
                    <span className="dash-v">{formatTon(v)}<small>ton</small></span>
                  </div>
                ))}
              </div>
              <div className="hint">Kaynak: {db.source} (kat bazlı ana tablo)</div>
            </section>
          )}

          <section className="panel">
            <div className="panel-head">
              <h3>Elemanlar · {floorElements.length}</h3>
              <span className="hint" style={{ margin: 0 }}>{taggedNames.size} işaretli</span>
            </div>
            <input className="srch" placeholder="Eleman ara (ör. S28, P6)…" value={search} onChange={(e) => setSearch(e.target.value)} />
            {mode === 'tag' && activeElement && (
              <div className="active-el">📍 Yerleştiriliyor: <b>{activeElement}</b> — plana tıklayın</div>
            )}
            <div className="el-list">
              {filteredElements.map((e) => (
                <button
                  key={e.name}
                  className={`el-item ${activeElement === e.name ? 'sel' : ''}`}
                  onClick={() => pickElement(e.name)}
                >
                  <span className="dot" style={{ background: TYPE_COLOR[e.type] }} />
                  <span className="el-name">{e.name}</span>
                  {taggedNames.has(e.name) && <span className="chk">✓</span>}
                  <span className="el-w">{formatKg(e.byFloor[floorId])} kg</span>
                </button>
              ))}
            </div>
          </section>

          <section className="panel">
            <div className="panel-head">
              <h3>Alanlar · {floorAreas.length}</h3>
              <button className="link" onClick={clearFloor}>Katı temizle</button>
            </div>
            {areaStats.length === 0 && <div className="hint">Dikdörtgen/Polygon ile plan üzerinde alan çizin.</div>}
            {areaStats.map(({ area, count, total }) => (
              <div className="area-row" key={area.id}>
                <span className="dot" style={{ background: area.color }} />
                <input className="area-name" value={area.name} onChange={(e) => renameArea(area.id, e.target.value)} />
                <span className="area-val">
                  {formatTon(total)} ton<small>{count} eleman</small>
                </span>
                <button className="x" onClick={() => removeArea(area.id)}>×</button>
              </div>
            ))}
          </section>

          <div className="foot-hint">
            İşareti silmek için plan üzerindeki noktaya çift tıklayın · Çalışmanız tarayıcıda otomatik kaydedilir.
          </div>
        </aside>
      </div>
    </div>
  )
}
