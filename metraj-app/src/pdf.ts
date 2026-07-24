import * as pdfjsLib from 'pdfjs-dist'
import workerUrl from 'pdfjs-dist/build/pdf.worker.min.mjs?url'

pdfjsLib.GlobalWorkerOptions.workerSrc = workerUrl

export type PdfDoc = pdfjsLib.PDFDocumentProxy

export async function loadPdf(data: ArrayBuffer): Promise<PdfDoc> {
  return await pdfjsLib.getDocument({ data }).promise
}

export interface RenderResult {
  width: number
  height: number
}

/** Sayfayı verilen ölçekte canvas'a çizer. */
export async function renderPage(
  pdf: PdfDoc,
  pageNum: number,
  scale: number,
  canvas: HTMLCanvasElement,
): Promise<RenderResult> {
  const page = await pdf.getPage(pageNum)
  const viewport = page.getViewport({ scale })
  const ctx = canvas.getContext('2d')!
  canvas.width = Math.floor(viewport.width)
  canvas.height = Math.floor(viewport.height)
  await page.render({ canvasContext: ctx, viewport }).promise
  return { width: canvas.width, height: canvas.height }
}

export interface RawToken {
  text: string
  x: number // base (ölçek=1) koordinat
  y: number
}

/** Metin katmanını konumlarıyla birlikte çıkarır (ölçek=1). */
export async function extractTokens(pdf: PdfDoc, pageNum: number): Promise<RawToken[]> {
  const page = await pdf.getPage(pageNum)
  const viewport = page.getViewport({ scale: 1 })
  const content = await page.getTextContent()
  const tokens: RawToken[] = []
  for (const item of content.items) {
    const it = item as { str?: string; transform?: number[] }
    if (!it.str || !it.str.trim() || !it.transform) continue
    const tx = pdfjsLib.Util.transform(viewport.transform, it.transform)
    tokens.push({ text: it.str.trim(), x: tx[4], y: tx[5] })
  }
  return tokens
}
