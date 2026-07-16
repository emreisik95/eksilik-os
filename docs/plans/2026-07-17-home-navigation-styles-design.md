# Ana Sayfa Navigasyon Stilleri Tasarımı

## Amaç

Ana sayfadaki “gündem, bugün, debe, tarihte bugün…” geçişlerini tek bir alt metin çubuğuna mahkûm etmemek; kullanıcıya Ayarlar'dan seçilebilen, gerçekten farklı beş navigasyon biçimi sunmak. Seçim anında canlı önizlemede görünmeli ve ana sayfaya dönüldüğünde içerik yeniden yüklenmeden uygulanmalıdır.

## Yaklaşım

Tek bir içerik ve seçim katmanı korunacak. Sekme verileri, oturum kuralları, tarih filtresi ve sağa/sola kaydırma bu katmanda yaşayacak; seçili `HomeNavigationStyle` yalnız navigasyon kabuğunu değiştirecek. Böylece her görünüm için ayrı ana ekran üretmekten kaynaklanacak yükleme, seçili sekme ve geri dönüş tutarsızlıkları oluşmayacak.

Yeni kurulumda varsayılan görünüm “yüzen dock” olacak. Eski `homeTabBarPosition` tercihi bulunan kullanıcılar için `bottom` klasik alt bara, `top` üst şeride taşınacak. Bilinmeyen kayıtlar güvenli biçimde yüzen dock'a düşecek.

## Stiller

1. **klasik alt bar** — metin ve ikonların ekran altında eşit ya da yatay kaydırılabilir dizildiği tanıdık görünüm.
2. **üst şerit** — seçili sekmeyi vurgu kapsülüyle gösteren, içerikten önce gelen yatay rail.
3. **yüzen dock** — alt güvenli alanın üzerinde duran, material yüzeyli ve ikon ağırlıklı yuvarlak dock.
4. **yan panel** — navigasyon başlığındaki menü düğmesiyle açılan, tüm sekmeleri ve seçili durumu gösteren iPhone uyumlu drawer.
5. **menü başlatıcı** — kalıcı geniş bar yerine seçili sekmeyi taşıyan tek elle erişilebilir kapsül ve açılır menü.

Tüm stiller mevcut tema renklerini ve SF Symbols ikonlarını kullanacak. Kalıcı kontrollerin dokunma alanı en az 44 punto olacak.

## Sekme Sırası ve Görünürlük

Görünürlük ile sıra ayrı kaydedilecek. Eski görünür sekme verisi korunacak; yeni `homeTabOrder` listesi bilinmeyen değerleri atıp eksik yeni sekmeleri varsayılan sıranın sonuna ekleyecek. Ayarlar ekranı checkmark ile görünürlüğü, taşıma tutamacı/Edit modu ile sıralamayı aynı yerde yönetecek. Ana ekran her iki tercihe de canlı tepki verecek ve gizlenen seçili sekme varsa ilk kullanılabilir sekmeye geçecek.

## Swipe ve Durum Akışı

İçerik üzerinde yatay ve dikey hareketi ayıran bir swipe politikası kullanılacak. Belirgin sola kaydırma sıradaki, sağa kaydırma önceki görünür sekmeyi seçer; listenin başında ve sonunda taşma olmaz. Dikey liste kaydırması ile yatay filtre şeritleri kısa/çapraz hareketlerde tetiklenmez. Sekme değişince “tarihte bugün” yılı yalnız o sekmenin kendi durumu olarak korunur.

## Doğrulama

Core harness; beş benzersiz stil, eski tercih göçü, sıra normalizasyonu, login/görünürlük filtresi ve swipe sınırlarını test edecek. XCTest, UserDefaults kalıcılığını doğrulayacak. CI cihaz build'i, XCTest ve SwiftLint çalışacak; imzalı artifact iPhone 17'ye kurulup paket bilgisi doğrulanacak.
