# Entry Layout Selector Design

## Amaç

Entry ekranında aynı içerik ve aksiyonları koruyan sekiz farklı görünüm sunmak ve seçimi Ayarlar'dan kalıcı olarak değiştirebilmek.

## Yaklaşım

`EntryLayoutStyle`, SwiftUI'dan bağımsız ve test edilebilir tek kaynak olacak. Her stil; metadata konumu, avatar görünürlüğü, boşluk yoğunluğu, kart kullanımı ve aksiyon yoğunluğu gibi sunum kararlarını bir `EntryLayoutPresentation` değeriyle tarif edecek. Bilinmeyen veya eski bir kayıt güvenli biçimde `classic` stiline düşecek.

`UserPreferences` seçimi `UserDefaults` içinde saklayıp `@Published` olarak yayınlayacak. `EntryLayoutPickerView` sekiz stili küçük canlı önizlemelerle gösterecek. `EntryRowView` ortak içerik, yazar, tarih ve aksiyon alt görünümlerini yeniden kullanarak seçili stile göre yalnızca sıralama ve metrikleri değiştirecek. Çevrimdışı okuyucu da aynı metrik ve metadata tercihlerini kullanacak; okundu işaretleme hareketleri değişmeyecek.

## Stiller

1. Klasik — mevcut dengeli düzen.
2. Kompakt — daha fazla entry'yi ekranda tutar.
3. Ferah — büyük boşluklar ve rahat okuma.
4. Kart — ayrık, yuvarlatılmış kartlar.
5. Yazar üstte — kimliği içerikten önce gösterir.
6. Bilgi üstte — tarih ve entry numarası önde.
7. Odak — içeriği ve sade aksiyonları öne çıkarır.
8. Minimal — avatar ve kalın ayraçları kaldırır.

## Doğrulama

Core harness sekiz benzersiz stili, güvenli varsayılanı ve kritik sunum farklarını test edecek. Son olarak proje yeniden üretilecek, harness çalıştırılacak ve iOS hedefi derlenecek.
