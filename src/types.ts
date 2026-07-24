export interface Point {
  x: number
  y: number
}

export interface FloorDef {
  id: string
  label: string
  planFile: string | null
}

export interface ElementDef {
  name: string
  type: 'KOLON' | 'PERDE'
  byFloor: Record<string, number> // kat id -> kg
  totalKg: number
}

export interface MetrajDB {
  project: string
  source: string
  note: string
  floors: FloorDef[]
  elements: ElementDef[]
  floorTotals: Record<string, Record<string, number>> // kat id -> tip -> kg
}

/** Plan üzerine yerleştirilmiş bir eleman işareti (base=ölçek1 koordinat). */
export interface Tag {
  id: string
  floorId: string
  elementName: string
  x: number
  y: number
}

export interface Area {
  id: string
  floorId: string
  name: string
  points: Point[]
  color: string
}

export type Mode = 'pan' | 'rect' | 'polygon' | 'tag'
