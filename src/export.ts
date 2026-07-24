import * as XLSX from 'xlsx'
import type { Area, ElementDef, MetrajDB, Tag } from './types'
import { pointInPolygon } from './geometry'

const round2 = (n: number) => Math.round(n * 100) / 100

/** Alan bazlı döküm + kat özeti içeren Excel üretir. */
export function exportExcel(db: MetrajDB, tags: Tag[], areas: Area[]) {
  const weightOf = (name: string, floorId: string) =>
    db.elements.find((e) => e.name === name)?.byFloor[floorId] ?? 0

  const wb = XLSX.utils.book_new()

  // 1) Alan özeti
  const summary: Record<string, string | number>[] = []
  for (const a of areas) {
    const inside = tags.filter(
      (t) => t.floorId === a.floorId && pointInPolygon(t.x, t.y, a.points),
    )
    const uniq = new Map<string, number>()
    for (const t of inside) uniq.set(t.elementName, weightOf(t.elementName, a.floorId))
    const total = [...uniq.values()].reduce((s, v) => s + v, 0)
    summary.push({
      Kat: a.floorId,
      Alan: a.name,
      'Eleman Sayısı': uniq.size,
      'Ağırlık (kg)': round2(total),
      'Ağırlık (ton)': round2(total / 1000),
    })
  }
  XLSX.utils.book_append_sheet(
    wb,
    XLSX.utils.json_to_sheet(summary.length ? summary : [{ Kat: '-', Alan: '-' }]),
    'Alan Özeti',
  )

  // 2) Detay
  const detail: Record<string, string | number>[] = []
  for (const a of areas) {
    const inside = tags.filter(
      (t) => t.floorId === a.floorId && pointInPolygon(t.x, t.y, a.points),
    )
    const seen = new Set<string>()
    for (const t of inside) {
      if (seen.has(t.elementName)) continue
      seen.add(t.elementName)
      const el = db.elements.find((e) => e.name === t.elementName) as ElementDef | undefined
      detail.push({
        Kat: a.floorId,
        Alan: a.name,
        Eleman: t.elementName,
        Tip: el?.type ?? '',
        'Ağırlık (kg)': round2(weightOf(t.elementName, a.floorId)),
      })
    }
  }
  XLSX.utils.book_append_sheet(
    wb,
    XLSX.utils.json_to_sheet(detail.length ? detail : [{ Kat: '-', Alan: '-', Eleman: '-' }]),
    'Eleman Dökümü',
  )

  // 3) Kat toplamları (tablodan)
  const ft: Record<string, string | number>[] = []
  for (const f of db.floors) {
    const t = db.floorTotals[f.id]
    if (!t) continue
    ft.push({
      Kat: f.label,
      ...Object.fromEntries(Object.entries(t).map(([k, v]) => [k + ' (kg)', round2(v)])),
    })
  }
  XLSX.utils.book_append_sheet(
    wb,
    XLSX.utils.json_to_sheet(ft.length ? ft : [{ Kat: '-' }]),
    'Kat Toplamları',
  )

  XLSX.writeFile(wb, 'donati-metraji.xlsx')
}
