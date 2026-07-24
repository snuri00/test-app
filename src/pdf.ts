import * as pdfjsLib from 'pdfjs-dist'
import workerUrl from 'pdfjs-dist/build/pdf.worker.min.mjs?url'

pdfjsLib.GlobalWorkerOptions.workerSrc = workerUrl

export type PdfDoc = pdfjsLib.PDFDocumentProxy

export async function loadPdf(data: ArrayBuffer): Promise<PdfDoc> {
  return await pdfjsLib.getDocument({ data }).promise
}

export async function loadPdfFromUrl(url: string): Promise<PdfDoc> {
  const res = await fetch(url)
  if (!res.ok) throw new Error('Plan PDF bulunamadı: ' + url)
  return loadPdf(await res.arrayBuffer())
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
