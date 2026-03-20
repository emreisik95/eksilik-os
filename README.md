# ek$ilik

Reklamsız, açık kaynak ekşi sözlük iOS istemcisi.

> Ad-free, open source [ekşi sözlük](https://eksisozluk.com) iOS client built with SwiftUI.

## Özellikler / Features

- **9 sekme** — gündem, bugün, debe, tarihte bugün, son, takip, kenar, çaylaklar, çöp
- **DEBE** — accordion görünüm, tıklayarak entry genişletme
- **Profil** — avatar, rozetler, istatistikler, entry listesi (favori/şükela/eksi/silme)
- **5 tema** — gece, gündüz, klasik, x, oled
- **Gelişmiş filtreleme** — tam eşleşme, içeren, regex ile başlık engelleme
- **Entry filtreleri** — bugün, şükela (zamanlı), ekşi şeyler, linkler, görseller, çaylaklar, başlıkta arama
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
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

### Adımlar / Steps

```bash
# Repoyu klonla / Clone the repo
git clone https://github.com/emreisik95/eksilik-os.git
cd eksilik-os/EksilikApp

# Xcode projesini oluştur / Generate Xcode project
xcodegen generate

# Xcode'da aç / Open in Xcode
open EksilikApp.xcodeproj
```

SPM bağımlılıkları Xcode tarafından otomatik çözülür.
SPM dependencies are resolved automatically by Xcode.

### Bağımlılıklar / Dependencies
- [Kanna](https://github.com/tid-kijyun/Kanna) 5.3+ — HTML parsing
- [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess) 4.2+ — Secure storage

## Mimari / Architecture

```
App → Views → ViewModels → Services → Core (Network/Parsing/Auth/Theme/Nav/Storage) → Models
```

- **SwiftUI** + **MVVM**
- **async/await** ağ katmanı / network layer
- **Kanna** ile HTML parsing (web API yok, HTML scraping)
- **WKWebView** Cloudflare bypass + cookie yönetimi
- **NavigationStack** (iOS 16+) ile programatik navigasyon

## Temalar / Themes

| gece | gündüz | klasik | x | oled |
|------|--------|--------|---|------|
| Koyu yeşil | Açık yeşil | Mavi klasik | Twitter mavi | Saf siyah + turuncu |

## Lisans / License

MIT

---

*Bu uygulama ekşi sözlük ile resmi bir bağlantısı olmayan bağımsız bir açık kaynak projesidir.*
*This is an independent open source project with no official affiliation with ekşi sözlük.*
