# ek$ilik

[![Build & Test](https://github.com/emreisik95/eksilik-os/actions/workflows/build.yml/badge.svg)](https://github.com/emreisik95/eksilik-os/actions/workflows/build.yml)
[![CodeQL](https://github.com/emreisik95/eksilik-os/actions/workflows/codeql.yml/badge.svg)](https://github.com/emreisik95/eksilik-os/actions/workflows/codeql.yml)

Reklamsız, açık kaynak ekşi sözlük iOS istemcisi.

> Ad-free, open source [ekşi sözlük](https://eksisozluk.com) iOS client built with SwiftUI.

## Özellikler / Features

- **9 sekme** — gündem, bugün, debe, tarihte bugün, son, takip, kenar, çaylaklar, çöp
- **DEBE** — accordion görünüm, tıklayarak entry genişletme
- **Profil** — avatar, rozetler, istatistikler, entry listesi (favori/şükela/eksi/silme)
- **5 tema** — gece, gündüz, klasik, x, oled
- **Gelişmiş filtreleme** — tam eşleşme, içeren, regex ile başlık engelleme
- **Entry filtreleri** — bugün, şükela (zamanlı), ekşi şeyler, linkler, görseller, çaylaklar, başlıkta arama
- **Filtre güvenli sayfalama** — bugün/şükela/yazar/arama kapsamı sayfa değiştirirken korunur
- **Görsel galeri** — önbellekli ön yükleme, tam ekran görüntüleme, kaydırma ve yakınlaştırma
- **Çevrimdışı okuma** — normal veya şükela içerikten ilk 5, ilk 10 ya da tüm sayfaları arka planda indirme
- **Kanal listesi** — arama sayfasında kanallar ve takip etme
- **Entry aksiyonları** — paylaş, mesaj gönder, modlog, yazar engelle
- **Alternatif ikonlar** — varsayılan, açık, klasik
- **Cookie kalıcılığı** — oturum yeniden başlatmalarda korunur
- **Widget** — ana ekranda gündem başlıkları (küçük/orta/büyük)
- **Reklam yok, analitik yok, takip yok**

## Kurulum / Setup

### Gereksinimler / Requirements

- Xcode 15+
- iOS 16.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) 2.46+

### Adımlar / Steps

```bash
# Repoyu klonla / Clone the repo
git clone https://github.com/emreisik95/eksilik-os.git
cd eksilik-os

# Xcode projesini oluştur / Generate Xcode project
xcodegen generate

# Xcode'da aç / Open in Xcode
open EksilikApp.xcodeproj
```

SPM bağımlılıkları Xcode tarafından otomatik çözülür.
SPM dependencies are resolved automatically by Xcode.

### Bağımlılıklar / Dependencies

- [Kanna](https://github.com/tid-kijyun/Kanna) 5.3.0 — HTML parsing
- [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess) 4.2.2 — Secure storage

## Mimari / Architecture

```
App → Views → ViewModels → Services → Core (Network/Parsing/Auth/Theme/Nav/Storage) → Models
```

- **SwiftUI** + **MVVM**
- **async/await** ağ katmanı / network layer
- **Kanna** ile HTML parsing (web API yok, HTML scraping)
- **WKWebView** Cloudflare bypass + cookie yönetimi
- **NavigationStack** (iOS 16+) ile programatik navigasyon
- Atomik dosya deposu + arka plan `URLSession` ile devam edebilir çevrimdışı indirmeler

## Doğrulama / Verification

Çekirdek ayrıştırıcı, URL, sayfalama ve çevrimdışı depolama kontrolleri Xcode olmadan da çalıştırılabilir:

```bash
swift run EksilikCoreHarness
```

Tam uygulama derlemesi ve simülatör testleri için eksiksiz Xcode kurulumu gerekir.

Katkılar test güdümlü ilerler: üretim Swift değişiklikleri karşılık gelen test değişikliğiyle birlikte gelmeli ve coverage mevcut tabanın altına düşmemelidir. Ayrıntılar için [CONTRIBUTING.md](CONTRIBUTING.md), güvenlik bildirimleri için [SECURITY.md](SECURITY.md) dosyasına bakın.

## Temalar / Themes

| gece | gündüz | klasik | x | oled |
|------|--------|--------|---|------|
| Koyu yeşil | Açık yeşil | Mavi klasik | Twitter mavi | Saf siyah + turuncu |

## Lisans / License

MIT

---

*Bu uygulama ekşi sözlük ile resmi bir bağlantısı olmayan bağımsız bir açık kaynak projesidir.*
*This is an independent open source project with no official affiliation with ekşi sözlük.*
