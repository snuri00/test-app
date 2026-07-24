# Donatı Metrajı — Kat Planı Üzerinden Alan Seçimi

Hastane (HHA Ana Bina) projesinde **kat planı üzerinde bir bölge seçerek** o bölgedeki
kolon + perde donatı ağırlığını (ton / kg) anında hesaplayan görsel bir uygulama.

Ağırlıklar, projenin **kat bazlı metraj tablosundan** (`KAT BAZLI DONATI METRAJ TABLOSU.xlsx`)
otomatik okunur; her kat için doğru plan PDF'i uygulamaya gömülüdür. İnternet gerektirmez,
veriler bilgisayarınızdan dışarı çıkmaz.

---

## Windows'ta kurulum (yazılım bilmeyenler için, adım adım)

Sadece **bir kez** yapılır. Yaklaşık 5 dakika sürer.

### 1) Node.js'i kurun (tek seferlik)

1. Tarayıcıda şu adrese gidin: **https://nodejs.org**
2. Büyük yeşil **"LTS"** butonuna tıklayıp indirin (örn. "20.x.x LTS").
3. İnen dosyayı çalıştırın, açılan pencerelerde hep **Next → Next → Install** deyin.
   Hiçbir ayarı değiştirmenize gerek yok. Bitince **Finish**.

> Node.js, bu uygulamayı bilgisayarınızda çalıştırabilmek için gereken ücretsiz altyapıdır.

### 2) Uygulama klasörünü bilgisayarınıza indirin

- Bu depoda yukarıdaki yeşil **`< > Code`** butonuna tıklayın → **Download ZIP**.
- İnen ZIP dosyasına sağ tıklayıp **"Tümünü ayıkla / Extract All"** deyin.
- Ayıklanan klasörü kolay bir yere koyun, örneğin **Masaüstü**'ne. (Klasör adı: `test-app`)

### 3) Komut penceresini bu klasörde açın

1. Ayıkladığınız `test-app` klasörünü açın (içinde `package.json` dosyasını görmelisiniz).
2. Klasörün üstündeki **adres çubuğuna** tıklayın, yazıları silin, **`cmd`** yazıp **Enter**'a basın.
   → Siyah bir komut penceresi açılır. (Komutları bu pencereye yazacağız.)

### 4) İlk kurulum (tek seferlik)

Açılan siyah pencereye şunu yazıp **Enter**'a basın:

```
npm install
```

Birkaç dakika sürebilir, satırlar akar. Bittiğinde tekrar yazı yazabildiğiniz satıra dönersiniz.

### 5) Uygulamayı başlatın

Aynı pencereye şunu yazıp **Enter**:

```
npm run dev
```

Ekranda şuna benzer bir satır çıkar:

```
  ➜  Local:   http://localhost:5173/
```

**`Ctrl` tuşuna basılı tutup** o `http://localhost:5173/` bağlantısına tıklayın
(ya da tarayıcıya elle yazın). Uygulama tarayıcıda açılır. 🎉

> Uygulamayı kapatmak için: siyah pencerede **`Ctrl + C`**. Tekrar açmak için 3. ve 5. adımı
> yapın (`npm install` tekrar gerekmez, sadece `npm run dev`).

---

## Nasıl kullanılır

1. Sol üstteki **KAT** menüsünden bir kat seçin (örn. *7. Bodrum Kat*). Seçilen katın planı
   ekrana gelir; sağdaki panoda o katın **toplam** kolon/perde/kiriş/döşeme ağırlığı görünür.
2. Sağdaki **Elemanlar** listesinden bir kolon/perde adına tıklayın (örn. `S28`), sonra plan
   üzerinde o elemanın yerine tıklayın → oraya işaret konur. (İşaretleme **bir kez** yapılır,
   otomatik kaydedilir.)
3. Üstten **▭ Dikdörtgen** veya **⬠ Polygon** seçip plan üzerinde bir **alan** çizin.
4. O alandaki işaretli elemanların **toplam ağırlığı** sağ üstte ve alan listesinde anında görünür.
5. **⭳ Excel** ile alan bazlı raporu indirin.

**Kısayollar**
- Yakınlaştır/uzaklaştır: **Ctrl + fare tekerleği** (veya üstteki `+ / −`).
- Planda gezinme: **✋ Kaydır** modu.
- Bir işareti silme: plan üzerindeki noktaya **çift tıklayın**.
- Çalışmayı başka bilgisayara taşıma: **⭳ Kaydet** → diğerinde **⭱ Yükle**.

---

## Sık sorulanlar

**"npm tanınmıyor / is not recognized" hatası alıyorum.**
Node.js kurulmadan önce komut penceresi açık kaldıysa olur. Pencereyi kapatıp 3. adımdan
yeniden açın.

**Ağırlıklar nasıl hesaplanıyor?**
`KAT BAZLI DONATI METRAJ TABLOSU.xlsx` dosyasındaki kat bazlı değerlerden. `5-15. NK` grubu
11 kata eşit bölünmüştür. Kaynak veriler `public/metraj-db.json` içinde tutulur.

**Çift tıklayınca açılan kalıcı bir sürüm istiyorum.**
`npm run build` komutu `dist` klasörü üretir; bu klasör herhangi bir web sunucusunda ya da
şirket içi paylaşımda yayınlanabilir. İstenirse tek `.exe` paketi de hazırlanabilir.

---

## Teknik özet (geliştiriciler için)

| Katman | Teknoloji |
|--------|-----------|
| Arayüz | React 18 + TypeScript + Vite |
| Plan render | pdf.js (`pdfjs-dist`) |
| Alan geometrisi | Ray-casting nokta-polygon testi (`src/geometry.ts`) |
| Metraj verisi | `public/metraj-db.json` (ana tablodan üretildi) |
| Rapor | SheetJS (`xlsx`) |

Komutlar: `npm run dev` (geliştirme), `npm run build` (statik derleme → `dist/`),
`npm run preview` (derlemeyi önizleme).

### Yol haritası
- [ ] İşaretleri paylaşılabilir proje şablonu olarak dışa aktarma
- [ ] Kiriş/döşeme için alan bazlı dağıtım (şu an sadece kat toplamı)
- [ ] PDF rapor çıktısı (seçili alanın görüntüsüyle)
- [ ] Taranmış planlar için ölçekli uzunluk/alan ölçümü
