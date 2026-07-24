import type { Point } from './types'

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

/** kg değerini Türk formatında biçimler. */
export function formatKg(n: number): string {
  return n.toLocaleString('tr-TR', { minimumFractionDigits: 0, maximumFractionDigits: 0 })
}

export function formatTon(n: number): string {
  return (n / 1000).toLocaleString('tr-TR', {
    minimumFractionDigits: 3,
    maximumFractionDigits: 3,
  })
}
