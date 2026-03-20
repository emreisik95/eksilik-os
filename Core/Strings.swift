import Foundation

enum L10n {
    // MARK: - Tabs
    enum Tab {
        static let home = "anasayfa"
        static let search = "ara"
        static let messages = "mesajlar"
        static let profile = "profil"
        static let settings = "ayarlar"
    }

    // MARK: - Home
    enum Home {
        static let title = "ek$ilik"
        static let gundem = "gündem"
        static let bugun = "bugün"
        static let tarihte = "tarihte bugün"
        static let takip = "takip"
        static let son = "son"
        static let debe = "debe"
        static let kenar = "kenar"
        static let caylaklar = "çaylaklar"
        static let cop = "çöp"
        static let block = "başlığı engelle"
        static let blockContaining = "kelimeyi engelle"
    }

    // MARK: - Entry
    enum Entry {
        static let noEntries = "entry bulunamadı"
        static let send = "gönder"
        static let shareLink = "linki paylaş"
        static let shareScreenshot = "ekran görüntüsü olarak paylaş"
        static let copyEntry = "entry'i kopyala"
        static let sendMessage = "mesaj gönder"
        static let modlog = "modlog"
        static let blockAuthor = "yazarı engelle"
        static let whoFavorited = "favorileyenler"
        static let cancel = "vazgeç"
        static let favorites = "favorileyenler"
        static func favoriteUsers(id: String) -> String {
            "#\(id) numaralı entry'yi favorileyenler"
        }
        static func watermark(id: String) -> String {
            "ek$ilik - #\(id)"
        }
    }

    // MARK: - Compose
    enum Compose {
        static let bkz = "(bkz:)"
        static let hede = "hede"
        static let star = "*"
        static let spoiler = "-spoiler-"
        static let link = "http://"
    }

    // MARK: - Search
    enum Search {
        static let title = "ara"
        static let prompt = "başlık, @yazar veya #entry ara..."
        static let topics = "başlıklar"
        static let authors = "yazarlar"
    }

    // MARK: - Profile
    enum Profile {
        static let entries = "entry'ler"
        static let favorites = "favoriler"
        static let images = "görseller"
        static let stats = "istatistikler"
        static let filter = "filtre"
        static func entryCount(_ n: Int) -> String { "\(n) entry" }
        static func followerCount(_ n: Int) -> String { "\(n) takipçi" }
        static func followingCount(_ n: Int) -> String { "\(n) takip" }
    }

    // MARK: - Messages
    enum Message {
        static let title = "mesajlar"
        static let noMessages = "mesaj bulunamadı"
        static let newMessage = "yeni mesaj"
        static let to = "kime:"
        static let send = "gönder"
    }

    // MARK: - Settings
    enum Settings {
        static let title = "ayarlar"
        static let appearance = "görünüm"
        static let theme = "tema"
        static func fontSize(_ size: Int) -> String {
            "yazı boyutu: \(size)"
        }
        static let content = "içerik"
        static let blockedTopics = "engellenen başlıklar"
        static let noBlockedTopics = "engellenen başlık yok"
        static let noFilterRules = "filtre kuralı yok"
        static let addFilterRule = "filtre kuralı ekle"
        static let filterPattern = "desen"
        static let filterPatternPlaceholder = "engellenecek kelime veya desen..."
        static let filterType = "filtre tipi"
        static let invalidRegex = "geçersiz regex deseni"
        static let cancel = "vazgeç"
        static let save = "kaydet"
        static let login = "giriş yap"
        static let logout = "çıkış yap"
        static let about = "hakkında"
        static let version = "sürüm"
    }

    // MARK: - Common
    enum Common {
        static let retry = "tekrar dene"
        static let noTopics = "başlık bulunamadı"
        static let connecting = "bağlanıyor..."
        static let couldNotConnect = "bağlanılamadı"
    }

    // MARK: - Auth
    enum Auth {
        static let login = "giriş yap"
    }
}
