import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import type { Area, DecimalSep, Label, Mode, Point } from './types'
import { loadPdf, renderPage, extractTokens, type PdfDoc, type RawToken } from './pdf'
import { pointInPolygon, rectToPolygon, parseNumber, formatKg, formatTon } from './geometry'
import { exportExcel } from './export'

const AREA_COLORS = ['#22c55e', '#3b82f6', '#f59e0b', '#ec4899', '#8b5cf6', '#14b8a6']

let idSeq = 0
const nextId = (p: string) => `${p}-${++idSeq}`

export default function App() {
  const [pdf, setPdf] = useState<PdfDoc | null>(null)
  const [fileName, setFileName] = useState('')
  const [pageNum, setPageNum] = useState(1)
  const [numPages, setNumPages] = useState(1)
  const [scale, setScale] = useState(1.4)
  const [canvasSize, setCanvasSize] = useState({ w: 0, h: 0 })

  const [tokens, setTokens] = useState<RawToken[]>([])
  const [manualLabels, setManualLabels] = useState<Label[]>([])
  const [disabledAuto, setDisabledAuto] = useState<Set<string>>(new Set())

  // Etiket algılama filtreleri
  const [decimal, setDecimal] = useState<DecimalSep>(',')
  const [textFilter, setTextFilter] = useState('')
  const [requireKg, setRequireKg] = useState(false)
  const [minValue, setMinValue] = useState(0)

  const [mode, setMode] = useState<Mode>('rect')
  const [areas, setAreas] = useState<Area[]>([])
  const [draft, setDraft] = useState<Point[]>([])
  const [rectStart, setRectStart] = useState<Point | null>(null)
  const [rectCur, setRectCur] = useState<Point | null>(null)
  const [hoverLabel, setHoverLabel] = useState<Label | null>(null)

  const canvasRef = useRef<HTMLCanvasElement>(null)
  const containerRef = useRef<HTMLDivElement>(null)
  const svgRef = useRef<SVGSVGElement>(null)
  const chainRef = useRef<Promise<void>>(Promise.resolve())

  // ---- PDF yükle ----
  const onFile = async (file: File) => {
    const buf = await file.arrayBuffer()
    const doc = await loadPdf(buf)
    setPdf(doc)
    setFileName(file.name)
    setNumPages(doc.numPages)
    setPageNum(1)
    setManualLabels([])
    setDisabledAuto(new Set())
    setAreas([])
    setDraft([])
  }

  // ---- Sayfa render (seri) ----
  useEffect(() => {
    if (!pdf) return
    let cancelled = false
    chainRef.current = chainRef.current
      .then(async () => {
        if (cancelled || !canvasRef.current) return
        const r = await renderPage(pdf, pageNum, scale, canvasRef.current)
        if (!cancelled) setCanvasSize({ w: r.width, h: r.height })
      })
      .catch(() => {})
    return () => {
      cancelled = true
    }
  }, [pdf, pageNum, scale])

  // ---- Metin çıkar ----
  useEffect(() => {
    if (!pdf) return
    let cancelled = false
    extractTokens(pdf, pageNum).then((t) => {
      if (!cancelled) setTokens(t)
    })
    return () => {
      cancelled = true
    }
  }, [pdf, pageNum])

  // ---- Otomatik etiketler ----
  const autoLabels = useMemo<Label[]>(() => {
    const f = textFilter.trim().toLowerCase()
    const out: Label[] = []
    tokens.forEach((t, i) => {
      if (!/\d/.test(t.text)) return
      if (f && !t.text.toLowerCase().includes(f)) return
      if (requireKg && !/kg/i.test(t.text)) return
      const v = parseNumber(t.text, decimal)
      if (v == null || v < minValue || v <= 0) return
      const id = `auto-${i}`
      out.push({ id, text: t.text, value: v, x: t.x, y: t.y, manual: false, enabled: !disabledAuto.has(id) })
    })
    return out
  }, [tokens, textFilter, requireKg, minValue, decimal, disabledAuto])

  const labels = useMemo(() => [...autoLabels, ...manualLabels], [autoLabels, manualLabels])

  // Aktif seçim (henüz kapanmamış çizim) veya kaydedilmiş alanlar için sayım
  const insideAnyArea = useCallback(
    (l: Label) => areas.some((a) => pointInPolygon(l.x, l.y, a.points)),
    [areas],
  )

  const areaStats = useMemo(() => {
    return areas.map((a) => {
      const inside = labels.filter((l) => l.enabled && pointInPolygon(l.x, l.y, a.points))
      const total = inside.reduce((s, l) => s + l.value, 0)
      return { area: a, count: inside.length, total }
    })
  }, [areas, labels])

  const grand = useMemo(() => {
    const seen = labels.filter((l) => l.enabled && insideAnyArea(l))
    return seen.reduce((s, l) => s + l.value, 0)
  }, [labels, insideAnyArea])

  // ---- Koordinat dönüşümü ----
  const toBase = (clientX: number, clientY: number): Point => {
    const rect = svgRef.current!.getBoundingClientRect()
    return { x: (clientX - rect.left) / scale, y: (clientY - rect.top) / scale }
  }

  // ---- Pointer olayları ----
  const panRef = useRef<{ sx: number; sy: number; l: number; t: number } | null>(null)

  const onPointerDown = (e: React.PointerEvent) => {
    if (!pdf) return
    const p = toBase(e.clientX, e.clientY)
    if (mode === 'rect') {
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
    if (mode === 'rect' && rectStart) {
      setRectCur(toBase(e.clientX, e.clientY))
    } else if (mode === 'pan' && panRef.current) {
      const c = containerRef.current!
      c.scrollLeft = panRef.current.l - (e.clientX - panRef.current.sx)
      c.scrollTop = panRef.current.t - (e.clientY - panRef.current.sy)
    }
  }

  const onPointerUp = () => {
    if (mode === 'rect' && rectStart && rectCur) {
      const dx = Math.abs(rectStart.x - rectCur.x)
      const dy = Math.abs(rectStart.y - rectCur.y)
      if (dx > 4 && dy > 4) {
        addArea(rectToPolygon(rectStart, rectCur))
      }
      setRectStart(null)
      setRectCur(null)
    }
    panRef.current = null
  }

  const onClick = (e: React.MouseEvent) => {
    if (!pdf) return
    const p = toBase(e.clientX, e.clientY)
    if (mode === 'polygon') {
      setDraft((d) => [...d, p])
    } else if (mode === 'label') {
      const raw = window.prompt('Bu noktadaki donatı ağırlığını girin (kg):', '')
      if (raw == null) return
      const v = parseNumber(raw, decimal)
      if (v == null || v <= 0) return
      setManualLabels((m) => [
        ...m,
        { id: nextId('man'), text: raw.trim(), value: v, x: p.x, y: p.y, manual: true, enabled: true },
      ])
    }
  }

  const finishPolygon = () => {
    if (draft.length >= 3) addArea(draft)
    setDraft([])
  }

  const addArea = (points: Point[]) => {
    setAreas((a) => [
      ...a,
      { id: nextId('area'), name: `Alan ${a.length + 1}`, points, color: AREA_COLORS[a.length % AREA_COLORS.length] },
    ])
  }

  const removeArea = (id: string) => setAreas((a) => a.filter((x) => x.id !== id))
  const renameArea = (id: string, name: string) =>
    setAreas((a) => a.map((x) => (x.id === id ? { ...x, name } : x)))

  const toggleLabel = (l: Label) => {
    if (l.manual) {
      setManualLabels((m) => m.map((x) => (x.id === l.id ? { ...x, enabled: !x.enabled } : x)))
    } else {
      setDisabledAuto((s) => {
        const n = new Set(s)
        n.has(l.id) ? n.delete(l.id) : n.add(l.id)
        return n
      })
    }
  }

  const clearAll = () => {
    setAreas([])
    setDraft([])
    setManualLabels([])
    setDisabledAuto(new Set())
  }

  // Ctrl+tekerlek ile zoom
  const onWheel = (e: React.WheelEvent) => {
    if (!e.ctrlKey && !e.metaKey) return
    e.preventDefault()
    setScale((s) => Math.min(6, Math.max(0.3, s * (e.deltaY < 0 ? 1.1 : 0.9))))
  }

  const rectPreview = rectStart && rectCur ? rectToPolygon(rectStart, rectCur) : null
  const cursor = mode === 'pan' ? 'grab' : mode === 'label' ? 'cell' : 'crosshair'

  return (
    <div className="app">
      <header className="toolbar">
        <div className="brand">
          <span className="logo">▦</span>
          <div>
            <div className="title">Donatı Metrajı</div>
            <div className="subtitle">Kat Planı · İnteraktif Alan Seçimi</div>
          </div>
        </div>

        <label className="btn primary">
          PDF Aç
          <input
            type="file"
            accept="application/pdf"
            hidden
            onChange={(e) => e.target.files?.[0] && onFile(e.target.files[0])}
          />
        </label>

        {pdf && (
          <>
            <div className="group">
              <button className="btn" onClick={() => setPageNum((n) => Math.max(1, n - 1))} disabled={pageNum <= 1}>
                ‹
              </button>
              <span className="page">
                {pageNum} / {numPages}
              </span>
              <button
                className="btn"
                onClick={() => setPageNum((n) => Math.min(numPages, n + 1))}
                disabled={pageNum >= numPages}
              >
                ›
              </button>
            </div>

            <div className="group">
              <button className="btn" onClick={() => setScale((s) => Math.max(0.3, s - 0.2))}>
                −
              </button>
              <span className="page">%{Math.round(scale * 100)}</span>
              <button className="btn" onClick={() => setScale((s) => Math.min(6, s + 0.2))}>
                +
              </button>
            </div>

            <div className="group modes">
              {(
                [
                  ['rect', '▭ Dikdörtgen'],
                  ['polygon', '⬠ Polygon'],
                  ['label', '＋ Etiket'],
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
        {pdf && (
          <button className="btn" onClick={() => exportExcel(areas, labels)} disabled={!areas.length}>
            ⭳ Excel
          </button>
        )}
      </header>

      <div className="body">
        <main
          className="stage"
          ref={containerRef}
          onWheel={onWheel}
          style={{ cursor: pdf ? cursor : 'default' }}
        >
          {!pdf ? (
            <div className="empty">
              <div className="empty-card">
                <div className="empty-icon">▤</div>
                <h2>Kat planı PDF'i açın</h2>
                <p>
                  PDF yüklendiğinde metin katmanındaki ağırlık etiketleri otomatik algılanır. Ardından bir alan
                  seçerek o bölgedeki toplam donatı ağırlığını anında hesaplayın.
                </p>
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
                onClick={onClick}
              >
                {/* Kaydedilmiş alanlar */}
                {areas.map((a) => (
                  <polygon
                    key={a.id}
                    points={a.points.map((p) => `${p.x * scale},${p.y * scale}`).join(' ')}
                    fill={a.color}
                    fillOpacity={0.12}
                    stroke={a.color}
                    strokeWidth={2}
                  />
                ))}
                {/* Polygon taslağı */}
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
                {/* Dikdörtgen önizleme */}
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
                {/* Etiketler */}
                {labels.map((l) => {
                  const inside = l.enabled && insideAnyArea(l)
                  const color = !l.enabled ? '#94a3b8' : inside ? '#16a34a' : l.manual ? '#7c3aed' : '#ef4444'
                  return (
                    <circle
                      key={l.id}
                      cx={l.x * scale}
                      cy={l.y * scale}
                      r={inside ? 5 : 3.5}
                      fill={color}
                      fillOpacity={0.85}
                      stroke="#fff"
                      strokeWidth={1}
                      onMouseEnter={() => setHoverLabel(l)}
                      onMouseLeave={() => setHoverLabel(null)}
                    />
                  )
                })}
                {hoverLabel && (
                  <g pointerEvents="none">
                    <rect
                      x={hoverLabel.x * scale + 8}
                      y={hoverLabel.y * scale - 20}
                      width={Math.max(70, hoverLabel.text.length * 8 + 20)}
                      height={22}
                      rx={4}
                      fill="#0f172a"
                      opacity={0.92}
                    />
                    <text x={hoverLabel.x * scale + 14} y={hoverLabel.y * scale - 5} fill="#fff" fontSize={12}>
                      {formatKg(hoverLabel.value)} kg
                    </text>
                  </g>
                )}
              </svg>
            </div>
          )}
        </main>

        <aside className="sidebar">
          <section className="panel total-panel">
            <div className="total-label">SEÇİLİ ALAN TOPLAMI</div>
            <div className="total-kg">{formatKg(grand)} kg</div>
            <div className="total-ton">{formatTon(grand)} ton</div>
          </section>

          <section className="panel">
            <h3>Etiket Algılama</h3>
            <div className="field">
              <span>Ondalık ayırıcı</span>
              <div className="seg">
                <button className={decimal === ',' ? 'on' : ''} onClick={() => setDecimal(',')}>
                  1.234,56
                </button>
                <button className={decimal === '.' ? 'on' : ''} onClick={() => setDecimal('.')}>
                  1,234.56
                </button>
              </div>
            </div>
            <div className="field">
              <span>Metin filtresi</span>
              <input
                type="text"
                placeholder="ör. kg"
                value={textFilter}
                onChange={(e) => setTextFilter(e.target.value)}
              />
            </div>
            <div className="field">
              <span>Min. değer (kg)</span>
              <input
                type="number"
                value={minValue}
                onChange={(e) => setMinValue(Number(e.target.value) || 0)}
              />
            </div>
            <label className="check">
              <input type="checkbox" checked={requireKg} onChange={(e) => setRequireKg(e.target.checked)} />
              Sadece "kg" içeren yazılar
            </label>
            <div className="hint">
              {autoLabels.length} otomatik · {manualLabels.length} elle etiket algılandı
            </div>
          </section>

          <section className="panel">
            <div className="panel-head">
              <h3>Alanlar ({areas.length})</h3>
              <button className="link" onClick={clearAll}>
                Tümünü temizle
              </button>
            </div>
            {areaStats.length === 0 && <div className="hint">Henüz alan seçilmedi. Bir mod seçip plan üzerinde çizin.</div>}
            {areaStats.map(({ area, count, total }) => (
              <div className="area-row" key={area.id}>
                <span className="dot" style={{ background: area.color }} />
                <input
                  className="area-name"
                  value={area.name}
                  onChange={(e) => renameArea(area.id, e.target.value)}
                />
                <span className="area-val">
                  {formatKg(total)} kg
                  <small>{count} eleman</small>
                </span>
                <button className="x" onClick={() => removeArea(area.id)}>
                  ×
                </button>
              </div>
            ))}
          </section>

          {hoverLabel && (
            <section className="panel">
              <h3>Etiket</h3>
              <div className="hint">
                "{hoverLabel.text}" → {formatKg(hoverLabel.value)} kg
                <br />
                <button className="link" onClick={() => toggleLabel(hoverLabel)}>
                  {hoverLabel.enabled ? 'Hesaptan çıkar' : 'Hesaba kat'}
                </button>
              </div>
            </section>
          )}
        </aside>
      </div>
    </div>
  )
}
