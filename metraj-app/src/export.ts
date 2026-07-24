import * as XLSX from 'xlsx'
import type { Area, Label } from './types'
import { pointInPolygon } from './geometry'

const round2 = (n: number) => Math.round(n * 100) / 100

/** Alan bazlı özet + etiket dökümü içeren Excel dosyası üretir ve indirir. */
export function exportExcel(areas: Area[], labels: Label[], fileName = 'donati-metraji.xlsx') {
  const enabled = labels.filter((l) => l.enabled)
  const wb = XLSX.utils.book_new()

  const summaryRows = areas.map((a) => {
    const inside = enabled.filter((l) => pointInPolygon(l.x, l.y, a.points))
    const total = inside.reduce((s, l) => s + l.value, 0)
    return {
      Alan: a.name,
      'Eleman Sayısı': inside.length,
      'Ağırlık (kg)': round2(total),
      'Ağırlık (ton)': round2(total / 1000),
    }
  })
  const grand = summaryRows.reduce((s, r) => s + (r['Ağırlık (kg)'] as number), 0)
  summaryRows.push({
    Alan: 'GENEL TOPLAM',
    'Eleman Sayısı': summaryRows.reduce((s, r) => s + (r['Eleman Sayısı'] as number), 0),
    'Ağırlık (kg)': round2(grand),
    'Ağırlık (ton)': round2(grand / 1000),
  })
  const ws1 = XLSX.utils.json_to_sheet(summaryRows)
  XLSX.utils.book_append_sheet(wb, ws1, 'Özet')

  const detailRows: Record<string, string | number>[] = []
  for (const a of areas) {
    const inside = enabled.filter((l) => pointInPolygon(l.x, l.y, a.points))
    for (const l of inside) {
      detailRows.push({
        Alan: a.name,
        'Ham Metin': l.text,
        'Değer (kg)': round2(l.value),
        Kaynak: l.manual ? 'Elle' : 'Otomatik',
      })
    }
  }
  const ws2 = XLSX.utils.json_to_sheet(
    detailRows.length ? detailRows : [{ Alan: '-', 'Ham Metin': '-', 'Değer (kg)': 0, Kaynak: '-' }],
  )
  XLSX.utils.book_append_sheet(wb, ws2, 'Detay')

  XLSX.writeFile(wb, fileName)
}
