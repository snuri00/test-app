import type { MetrajDB } from './types'

const BASE = import.meta.env.BASE_URL || './'

export async function loadDB(): Promise<MetrajDB> {
  const res = await fetch(`${BASE}metraj-db.json`)
  if (!res.ok) throw new Error('metraj-db.json yüklenemedi')
  return (await res.json()) as MetrajDB
}

export function planUrl(planFile: string): string {
  return `${BASE}plans/${encodeURIComponent(planFile)}`
}
