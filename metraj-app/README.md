# Donatı Metrajı — Kat Planı Üzerinden İnteraktif Alan Seçimi

Hastane (veya herhangi bir) projesinde **kat planı PDF'i** üzerinden bir bölge seçerek o
bölgedeki toplam **donatı ağırlığını** (kg / ton) otomatik hesaplayan web uygulaması.

ChatGPT'nin ürettiği tkinter tabanlı ilk sürümün aksine bu uygulama:

- **Otomatik etiket algılama** — PDF'in metin katmanındaki ağırlık yazılarını
  (`getTextContent`) konumlarıyla birlikte okur. Yüzlerce etiketi elle tıklamaya gerek yok.
- **Profesyonel & görsel arayüz** — zoom / pan, dikdörtgen **ve** polygon seçim, çoklu alan,
  canlı görsel geri bildirim (seçime giren etiketler yeşile döner).
- **Tamamen tarayıcıda** çalışır (backend yok) — veri dışarı çıkmaz, statik olarak yayınlanır.
- **Excel raporu** — alan bazında özet + etiket dökümü.

## Çalıştırma

```bash
cd metraj-app
npm install
npm run dev      # geliştirme sunucusu (http://localhost:5173)
npm run build    # dist/ altına statik derleme
npm run preview  # derlemeyi önizle
```

## Kullanım akışı

1. **PDF Aç** — kat planını yükleyin. Metin katmanındaki sayısal etiketler otomatik algılanır
   (kırmızı = otomatik, mor = elle eklenen nokta).
2. **Etiket Algılama** panelinden ondalık ayırıcıyı (Türk `1.234,56` / İngiliz `1,234.56`),
   metin filtresini (ör. `kg`) ve minimum değeri ayarlayın.
3. Bir seçim modu seçin:
   - **▭ Dikdörtgen** — sürükleyerek alan çizin.
   - **⬠ Polygon** — köşelere tıklayın, "Alanı kapat" ile bitirin.
   - **＋ Etiket** — taranmış PDF veya eksik etiket için elle nokta+değer ekleyin.
   - **✋ Kaydır** — planda gezinin (Ctrl + tekerlek ile zoom).
4. Seçilen alandaki toplam **sağ üstte ve alan listesinde** anlık görünür.
5. **⭳ Excel** ile alan bazlı raporu indirin.

## Metin katmanı yoksa (taranmış PDF)

Yazılar mouse ile seçilemiyorsa otomatik algılama boş kalır. Bu durumda:

- **＋ Etiket** modu ile değerleri elle işaretleyebilirsiniz, veya
- Sonraki aşamada bir OCR adımı (Tesseract.js) eklenerek taranmış planlar da desteklenebilir.

## Mimari

| Katman | Teknoloji |
|--------|-----------|
| Arayüz | React 18 + TypeScript + Vite |
| PDF render & metin | pdf.js (`pdfjs-dist`) |
| Geometri | Ray-casting nokta-polygon testi (`src/geometry.ts`) |
| Rapor | SheetJS (`xlsx`) |

Backend gerektirmez; `dist/` çıktısı herhangi bir statik sunucuda (Netlify, Vercel, IIS, nginx)
barındırılabilir.

## Yol haritası (sonraki aşamalar)

- [ ] OCR desteği (taranmış planlar için Tesseract.js)
- [ ] Proje kaydet/yükle (JSON — alanlar + elle etiketler)
- [ ] PDF rapor çıktısı (görsel ek: seçilen alanların görüntüsü)
- [ ] Ağırlık formatı/desen şablonları (Ø çapı, poz no ile eşleştirme)
- [ ] Ölçekli gerçek uzunluk/alan ölçümü (m², m)
