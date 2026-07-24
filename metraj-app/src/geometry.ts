import type { Point, DecimalSep } from './types'

/** Ray-casting: nokta polygon içinde mi? */
export function pointInPolygon(x: number, y: number, poly: Point[]): boolean {
  let inside = false
  const n = poly.length
  for (let i = 0, j = n - 1; i < n; j = i++) {
    const xi = poly[i].x
    const yi = poly[i].y
    const xj = poly[j].x
    const yj = poly[j].y
    const intersect =
      yi > y !== yj > y &&
      x < ((xj - xi) * (y - yi)) / (yj - yi + 1e-12) + xi
    if (intersect) inside = !inside
  }
  return inside
}

/** İki köşeden dikdörtgen polygon üretir. */
export function rectToPolygon(a: Point, b: Point): Point[] {
  return [
    { x: a.x, y: a.y },
    { x: b.x, y: a.y },
    { x: b.x, y: b.y },
    { x: a.x, y: b.y },
  ]
}

/**
 * Ham metinden sayısal değer çözer.
 * decimal = ',' (Türk formatı: 1.234,56) veya '.' (İngiliz: 1,234.56).
 */
export function parseNumber(raw: string, decimal: DecimalSep): number | null {
  const m = raw.match(/[-+]?\d[\d.,\s]*\d|\d/)
  if (!m) return null
  let s = m[0].replace(/\s/g, '')
  if (decimal === ',') {
    s = s.replace(/\./g, '').replace(',', '.')
  } else {
    s = s.replace(/,/g, '')
  }
  const n = parseFloat(s)
  return Number.isNaN(n) ? null : n
}

/** kg değerini Türk formatında (1.234,56) biçimler. */
export function formatKg(n: number): string {
  return n.toLocaleString('tr-TR', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  })
}

export function formatTon(n: number): string {
  return (n / 1000).toLocaleString('tr-TR', {
    minimumFractionDigits: 3,
    maximumFractionDigits: 3,
  })
}
