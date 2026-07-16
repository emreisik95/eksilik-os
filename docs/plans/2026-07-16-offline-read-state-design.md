# Çevrimdışı Entry Okuma Durumu Tasarımı

## Amaç

İndirilen başlıklardaki entry'ler kullanıcı tarafından manuel olarak okundu veya okunmadı işaretlenebilecek. Okunan entry'ler isteğe bağlı olarak listeden gizlenecek ve bu durum uygulama yeniden açıldığında ya da indirme arka planda devam ettiğinde korunacak.

## Etkileşim

Çevrimdışı okuyucudaki her entry hem sağa hem sola kaydırılabilir. Tam kaydırma, entry'nin okundu durumunu tersine çevirir. Okunmuş bir entry listede gösteriliyorsa daha düşük opaklık ve `checkmark.circle.fill` işaretiyle ayırt edilir. Navigasyon çubuğundaki göz düğmesi okunanları gizler veya yeniden gösterir. Filtre açıkken son okunmamış entry de işaretlenirse liste, "okunmamış entry kalmadı" durumu ve okunanları geri gösteren bir düğme sunar.

İlk kez indirilen bir başlık açıldığında orta boy bir tanıtım kartı gösterilir. Kart, iki yönlü kaydırmayı ve göz düğmesini açıklar. Kullanıcı kartı kapattığında bu tercih `AppStorage` içinde saklanır ve tanıtım tekrar gösterilmez.

## Veri ve hata davranışı

Okuma durumu `manifest.json` ve sayfa dosyalarından ayrı bir `read-state.json` dosyasında tutulur. Dosya; okunan entry kimliklerini ve okunanları gizleme tercihini içerir. Ayrı dosya seçimi, eski indirmelerle geriye uyumluluğu korur ve arka planda yeni sayfa kaydedilmesinin okuma durumunu ezmesini önler. Eksik dosya boş durum olarak değerlendirilir. Yazma işlemleri atomik yapılır; hata oluşursa arayüz mevcut durumu korur ve kullanıcıya hata metni gösterir.

## Doğrulama

Depolama testleri okundu işaretinin kalıcılığını, okunmadıya dönüşü ve gizleme tercihinin yeniden yüklenmesini kapsar. Çekirdek kontrol paketi görünür entry filtrelemesini doğrular. iOS XCTest, derleme ve SwiftLint hattı tamamlandıktan sonra imzalı uygulama iPhone 17'ye kurulacaktır.
