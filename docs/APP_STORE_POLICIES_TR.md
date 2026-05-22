# ForeWiz — App Store Politikaları & Uyumluluk Kılavuzu

> **Amaç:** Bu belge, App Store gönderim gereksinimlerinin referans kaynağıdır.
> App Store Connect'e gönderim yaparken ilgili bölümleri uygun alanlara kopyalayın.

---

## 📜 Gizlilik Politikası

**App Store Connect → Uygulama Gizliliği → Gizlilik Politikası URL'si için**
Bu belgeyi web sitenizde barındırın (örn. `https://forewiz.app/privacy`) veya bir
gizlilik politikası oluşturma hizmeti kullanın.

---

### ForeWiz Gizlilik Politikası

**Son güncelleme:** 22 Mayıs 2026

#### 1. Veri Toplama ve Kullanım

ForeWiz, **varsayılan olarak gizlilik** ilkesiyle tasarlanmıştır. Uygulama, hava durumuna uyarlanmış karar önerileri sunmak için yalnızca gerekli minimum veriyi toplar.

| Veri Türü | Toplanan | Amaç | Üçüncü Taraflarla Paylaşım |
|-----------|----------|------|---------------------------|
| **Konum** | Evet (yalnızca ön planda) | Yerel hava durumu, güzergah havası, haritalar ve yakın güzergah noktaları için | Apple WeatherKit / MapKit |
| **Tercihler** | Evet | Uygulama ayarları (dil, vurgu rengi, bildirim tercihleri, kayıtlı konumlar) — yalnızca cihazda/uygulama grubunda saklanır | Asla |
| **Kullanım Verisi / Analitik** | Sınırlı | Yerel uygulama/reklam performans olayları; üçüncü taraf analitik SDK'sı yok | Satılmaz; AdMob, reklam sunumu için reklam etkileşim verisi alır |
| **Reklam Kimliği (IDFA)** | Evet (onay ile) | Google AdMob tarafından kişiselleştirilmiş reklam sunumu için kullanılır | Google (AdMob SDK aracılığıyla) |
| **Kilitlenme Raporları** | **Hayır** | Kilitlenme raporlama SDK'sı entegre edilmemiştir | Yok |
| **Tanılama** | **Hayır** | Tanılama verisi toplanmaz | Yok |

#### 2. Reklamcılık ve Onay

ForeWiz, gelir modeli için **Google AdMob** kullanmaktadır. Aşağıdakiler geçerlidir:

- **ATT (Uygulama İzleme Şeffaflığı):** iOS 14.5 ve üzerinde uygulama, ilk açılışta ATT onay iletişim kutusunu gösterir. Reklam kişiselleştirme yalnızca kullanıcı açıkça izleme izni verirse etkinleştirilir.
- **GDPR Onayı:** Avrupa Ekonomik Alanı'ndaki (AEA) kullanıcılar için ForeWiz, herhangi bir reklam yüklemeden önce GDPR onayı almak amacıyla Google'ın UMP (Kullanıcı Mesajlaşma Platformu) SDK'sını kullanır.
- **Reklam Formatları:** Banner, yerel satır içi, geçiş reklamı (uygulama açılışı) ve isteğe bağlı ödüllü video reklamlar.
- **Kişiselleştirilmemiş Reklamlar:** Onay reddedilirse ForeWiz yalnızca kişiselleştirilmemiş reklamlar sunar.

#### 3. Veri Depolama ve Güvenlik

- **Konum Verisi:** Yalnızca hava durumu verisi talep etmek için geçici olarak kullanılır. Depolanmaz, kaydedilmez.
- **Tercihler:** Tüm kullanıcı tercihleri Apple'ın SwiftData çerçevesi kullanılarak **cihazda** saklanır. Hiçbir tercih verisi cihaz dışına aktarılmaz.
- **Hava Durumu Verisi:** 15 dakikalık TTL ile yerel olarak önbelleğe alınır. Paylaşılmaz.
- **Ağ Bağlantıları:** Uygulama yalnızca şunlara bağlanır:
  - Apple WeatherKit (hava durumu verisi)
  - Google AdMob (kullanıcı onayı ile reklam sunumu)
  - Google UMP (reklam onay formları/gizlilik seçenekleri)
  - Apple MapKit (harita karoları, güzergah planlama, WizPath için yerel arama)

#### 4. Çocukların Gizliliği

ForeWiz, 13 yaşın altındaki çocuklardan bilerek veri toplamaz. Uygulama çocuklara yönelik değildir ve reşit olmayanlara yönelik içerik sunmaz.

#### 5. Veri Silme

Tüm kullanıcı verileri cihazda saklandığından:
- **Uygulamayı kaldırmak**, yerel olarak depolanan tüm verileri siler.
- Sunucu tarafında silinecek herhangi bir veri bulunmamaktadır.
- Reklama ilişkin tanımlayıcılar (IDFA), iOS Ayarlar → Gizlilik → İzleme yolundan sıfırlanabilir.

#### 6. İletişim

Gizlilik ile ilgili sorularınız için: [support@forewiz.app]

---

## 🛡️ App Store Gizlilik Ayrıntıları (Kontrol Listesi)

**App Store Connect → Uygulama Gizliliği → Veri Türleri için**

App Store Connect gizlilik anketini doldururken bu kontrol listesini kullanın:

### Kullanıcıyla İlişkilendirilen Toplanan Veriler

| Veri Türü | Toplanan? | Amaç | Kullanıcıyla İlişkilendirildi mi? |
|-----------|-----------|------|----------------------------------|
| **Ad** | ❌ Hayır | — | — |
| **E-posta** | ❌ Hayır | — | — |
| **Telefon Numarası** | ❌ Hayır | — | — |
| **Fiziksel Adres** | ❌ Hayır | — | — |
| **Hassas Konum** | ✅ Evet | Uygulama İşlevselliği | Hayır |
| **Yaklaşık Konum** | ✅ Evet | Uygulama İşlevselliği | Hayır |
| **Sağlık / Fitness** | ❌ Hayır | — | — |
| **Ödeme Bilgisi** | ❌ Hayır | — | — |
| **İletişim Bilgisi** | ❌ Hayır | — | — |
| **Kullanıcı İçeriği** | ❌ Hayır | — | — |
| **Arama Geçmişi** | ❌ Hayır | — | — |
| **Tarama Geçmişi** | ❌ Hayır | — | — |
| **Cihaz Kimliği** | ✅ Evet (IDFA) | Üçüncü Taraf Reklamcılık | Evet (AdMob) |
| **Satın Alma Geçmişi** | ❌ Hayır | — | — |
| **Ürün Etkileşimi** | ✅ Evet | Uygulama İşlevselliği / Reklam Performansı | Hayır |
| **Kilitlenme Verisi** | ❌ Hayır | — | — |
| **Performans Verisi** | ❌ Hayır | — | — |
| **Tanılama** | ❌ Hayır | — | — |

### Kullanıcıyla İlişkilendirilmeyen Veriler

| Veri Türü | Toplanan? | Amaç |
|-----------|-----------|------|
| **Hassas Konum** | ✅ Evet | Yerel hava durumu gösterimi (saklanmaz, paylaşılmaz) |
| **Yaklaşık Konum** | ✅ Evet | Yerel hava durumu gösterimi (saklanmaz, paylaşılmaz) |

---

## ✅ App Review Gönderim Kontrol Listesi

### 1.0 — Zorunlu Öğeler

| Öğe | Durum | Notlar |
|-----|-------|--------|
| Geçerli Apple Developer hesabı (yıllık $99) | ✅ | — |
| Doğru paket tanımlayıcıyla App ID | ✅ | — |
| App Store Connect kaydı oluşturuldu | ⬜ | Göndermeden önce oluşturulmalı |
| Uygulama simgesi (tüm gerekli boyutlar) | ✅ | Assets.xcassets'e dahil |
| Ekran görüntüleri (6.7" + 5.5" + iPad) | ⬜ | Bkz. Bölüm 3 |
| Uygulama önizleme videosu (isteğe bağlı) | ⬜ | Karar motoru demosu için önerilir |
| Gizlilik politikası URL'si | ✅ | Bölüm 1'deki belgeyi barındırın |
| Yaş derecelendirmesi | ⬜ | Bkz. Bölüm 2.3 |
| İhracat uyumu (ITSAppUsesNonExemptEncryption) | ✅ | Yalnızca muaf şifreleme için NO olarak ayarlandı |
| İçerik hakları (varsa üçüncü taraf içerik) | ✅ | Apple'dan hava durumu verisi, Apple'dan haritalar |

### 2.0 — Teknik Gereksinimler

#### 2.1 Özellikler ve Yetkiler

| Özellik | Zorunlu | Durum |
|---------|---------|-------|
| WeatherKit | Evet | ✅ Eklendi |
| MapKit | Evet | ✅ Eklendi |
| Push Bildirimleri | Evet (hava durumu uyarıları için) | ✅ |
| Arka Plan Modları | Evet (hava durumu yenileme) | ✅ |
| Uygulama Grupları (Widget'lar) | Evet | ✅ |
| Apple ile Giriş | Hayır | ⬜ İsteğe bağlı |
| iCloud | Hayır | Gerekli değil |
| Wallet | Hayır | Gerekli değil |

#### 2.2 Info.plist Anahtarları

| Anahtar | Değer | Durum |
|---------|-------|-------|
| `NSLocationWhenInUseUsageDescription` | "Konumunuzu yalnızca bulunduğunuz yere özel hava durumu önerileri sunmak için kullanıyoruz." | ✅ |
| `NSUserTrackingUsageDescription` | "İzniniz, ForeWiz ve reklam ortağımız Google AdMob'un daha alakalı reklamlar göstermek ve uygulamayı ücretsiz tutmaya yardımcı olmak için cihaz tanımlayıcılarını kullanmasına olanak tanır." | ✅ |
| `CFBundleDisplayName` | ForeWiz | ✅ |
| `BGTaskSchedulerPermittedIdentifiers` | Arka plan hava durumu yenileme | ✅ |

#### 2.3 App Store Yaş Derecelendirmesi

AdMob içerik politikaları ve uygulamanın içeriğine göre:

| Kategori | Derecelendirme |
|----------|---------------|
| **Çizgi Film veya Fantezi Şiddetinin Sıklığı/Yoğunluğu** | Yok |
| **Gerçekçi Şiddet** | Yok |
| **Uzun Süreli Grafik/Sadistik Gerçekçi Şiddet** | Yok |
| **Küfür veya Kaba Mizah** | Yok |
| **Olgun/Müstehcen Temalar** | Yok |
| **Korku/Dehşet Temaları** | Yok |
| **Tıbbi/Tedavi Bilgisi** | Seyrek/Hafif (sağlık-hava durumu ilişkisi) |
| **Alkol, Tütün veya Uyuşturucu Kullanımı** | Yok |
| **Kumar** | Yok |
| **Simüle Kumar** | Yok |
| **Cinsel İçerik veya Çıplaklık** | Yok |
| **Kısıtsız Web Erişimi** | Hayır |
| **Yarışmalar** | Hayır |

**Önerilen Yaş Derecelendirmesi:** **4+** (kısıtlı kategori yok)

### 3.0 — Ekran Görüntüsü Gereksinimleri

| Cihaz | Boyut | Yön | Adet |
|-------|-------|-----|------|
| iPhone 6.7" (iPhone 15 Pro Max) | 1290 × 2796 px | Dikey | 3–5 |
| iPhone 6.5" (iPhone 15 Pro) | 1242 × 2688 px | Dikey | 3–5 |
| iPhone 5.5" (iPhone 8 Plus) | 1242 × 2208 px | Dikey | 3–5 |
| iPad Pro (12.9") — isteğe bağlı | 2048 × 2732 px | Dikey | 3–5 |

**Önerilen Ekranlar:**

1. **Ana Ekran** — Açık hava puanı + hava durumu verisini içeren ana kart (değer önerisini kanıtlar)
2. **Hava Durumu Brifing** — Anlatı + sağlık analizi + karşılaştırmalı veri (yapay zeka derinliğini gösterir)
3. **WizPath Haritası** — Hava durumu katmanlarıyla güzergah (benzersiz özelliği gösterir)
4. **WizPath Panosu** — Kalkış optimizörü ile yolculuk HUD'u (planlama kapasitesini gösterir)
5. **Widget'lar** — Kilit ekranı + ana ekran widget'ları (ekosistem entegrasyonunu gösterir)

---

## 🔐 App Store Connect İhracat Uyumu

App Store Connect → Uygulama Bilgileri → İhracat Uyumu bölümünde:

| Soru | Yanıt | Gerekçe |
|------|-------|---------|
| Uygulamanız şifreleme kullanıyor mu? | **Evet, yalnızca muaf** | Widget uygulama grubu verisi için HTTPS artı yerel AES-GCM şifrelemesi |
| Uygulamanız muafiyete hak kazanıyor mu? | Evet | Standart ağ şifrelemesi ve cihaz üzerinde veri koruma, muaf/muaf olmayan kullanım durumlarıdır |
| Uygulamanız şifreleme için yetkilendirildi mi? | Yok | Muaf olmayan şifreleme yok |

**`ITSAppUsesNonExemptEncryption` değerini Info.plist'te `NO` olarak bırakın;** uygulama muaf olmayan şifreleme kullanmamaktadır.

---

## 📝 App Store Connect için Meta Veriler

### Uygulama Adı
**ForeWiz** — Hava Durumu Karar Asistanı

### Alt Başlık
Hava durumundan daha akıllı. Kararlar için ideal.

### Açıklama
**Birinci paragraf (en önemli — "devamı" olmadan gösterilen):**

> ForeWiz size sadece hava durumunu söylemez. Ne yapmanız gerektiğini söyler.
>
> Apple WeatherKit tarafından desteklenen ForeWiz; kişiselleştirilmiş bir açık hava puanı (0–100), aktiviteleriniz için en iyi zamanı, ne giyeceğinizi ve havanın sağlığınızı nasıl etkileyebileceğini üretmek için sıcaklık, nem, UV, rüzgar ve yağışı analiz eder — hepsi reklamlarla desteklenen güzel bir uygulamada.

**Sonraki paragraflar:**

> **🧠 Akıllı Karar Motoru** — 7 özel motorumuz, yerel tahminize göre net bir açık hava puanı, optimum aktivite pencereleri ve kıyafet önerileri sunmak için her hava durumu parametresini analiz eder.
>
> **🏥 Sağlık-Hava Durumu Takibi** — Bugünkü havanın migreninizi, uyku kalitenizi, eklem ağrınızı, solunum konforunuzu ve dayanıklılığınızı nasıl etkileyebileceğini görün. ForeWiz, tam bir sağlık tablosu için 6'dan fazla hava faktörünü 5 sağlık boyutuyla ilişkilendirir.
>
> **🗺️ WizPath Güzergah Planlama** — İklim odaklı rota planlama ile yolculuğunuzu planlayın. Her segmentteki hava koşullarını görün, kalkış süresi optimizasyonu alın ve hava + trafik bir rotayı riskli kıldığında sentinel uyarıları alın.
>
> **🌍 Tam Yerelleştirme** — Resmi üslupla İngilizce ve Türkçe. Çalışma anında dinamik dil geçişi. VoiceOver ve Dinamik Tür desteğiyle erişilebilirlik optimizasyonu.
>
> **💚 Önce Gizlilik** — Sıfır analitik, sıfır telemetri. Tüm tercihler cihazda saklanır. Konum yalnızca hava durumu için kullanılır — asla takip edilmez, asla paylaşılmaz.

### Anahtar Kelimeler
`hava durumu, tahmin, açık hava, karar, planlayıcı, işe gidiş, sağlık, migren, polen, UV, puan, öneri, aktivite, koşu, bisiklet, yürüyüş, seyahat, güzergah, iklim, WizPath, yerelleştirme, Turkish`

### Destek URL'si
`https://bilgenworks.com/forewiz/support`

### Pazarlama URL'si (isteğe bağlı)
`https://bilgenworks.com/forewiz`

---

## ⚠️ Yaygın App Store Ret Riskleri

| Risk | Önlem | Durum |
|------|-------|-------|
| **4.0 — Tasarım: Yer tutucu içerik yok** | Tüm bölümler gerçek hava durumu verisi veya net yükleme/hata durumları gösterir | ✅ |
| **2.1 — Uygulama Eksiksizliği** | Başlatmada çöküş yok, tüm özellikler işlevsel | ✅ |
| **2.3.10 — Gizli özellik yok** | Hata ayıklama menüsü yok, belgelenmemiş API yok | ✅ |
| **3.1.1 — Uygulama İçi Satın Alma (eklenirse)** | Yok — ForeWiz reklamlarla destekleniyor, şu an IAP yok | Yok |
| **3.2.1 — Kabul Edilebilir (AdMob)** | Reklam içeriği 4+ derecelendirmesi için uygun, göze batmayan yerleşim | ✅ |
| **5.1.1 — Konum Gizliliği** | Konum izni açıklandı, yalnızca ön planda kullanılıyor | ✅ |
| **5.1.2 — Veri Toplama Onayı** | IDFA için ilk başlatmada ATT iletişim kutusu gösteriliyor | ✅ |

---

## 📄 İhracat Uyumu Belgelendirmesi

Muaf olmayan ihracat uyumu belgesi gerekmemektedir; çünkü:
- ForeWiz, widget uygulama grubu verisi için standart HTTPS/TLS artı yerel AES-GCM koruması kullanmaktadır
- Şifreleme, standart ağ güvenliği ve cihaz üzerinde veri koruma içindir
- Apple'ın otomatik şifreleme muafiyeti bu kullanım durumu için geçerlidir (CAT5NOTE3)

---

*Bu belgeyi yeni özellikler eklendikçe güncelleyin. Her App Store gönderimine önce gözden geçirin.*
