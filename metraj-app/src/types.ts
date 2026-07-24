export interface Point {
  x: number
  y: number
}

/** Bir donatı/ağırlık etiketi. Konumlar ölçek=1 (base) piksel koordinatlarında tutulur. */
export interface Label {
  id: string
  text: string      // PDF'ten okunan ham metin
  value: number     // kg cinsinden çözümlenmiş değer
  x: number         // base koordinat
  y: number
  manual: boolean   // elle mi eklendi
  enabled: boolean  // hesaba katılsın mı
}

export interface Area {
  id: string
  name: string
  points: Point[]   // base koordinatlar
  color: string
}

export type Mode = 'pan' | 'rect' | 'polygon' | 'label'

export type DecimalSep = ',' | '.'
