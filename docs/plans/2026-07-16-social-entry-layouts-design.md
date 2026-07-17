# Sosyal Entry Yerleşimleri Tasarımı

## Amaç

Entry görünümü seçimini yalnızca boşluk ve metadata farkı olmaktan çıkarıp, kullanıcıya ilk bakışta ayırt edilebilen sekiz gerçek okuma düzeni sunmak. Ayarlar ekranındaki seçim anında büyük bir canlı önizlemede görünmeli; aynı seçim çevrimiçi ve indirilmiş entry'lerde uygulanmalı.

## Yerleşimler

1. **klasik ekşi** — mevcut içerik, yazar ve aksiyon hiyerarşisini korur.
2. **X** — solda avatar, üstte kullanıcı/tarih, altta yatay ve hafif aksiyonlar.
3. **Instagram** — belirgin yazar başlığı, medya odaklı gövde, içeriğin altında sosyal aksiyon şeridi.
4. **LinkedIn** — kimlik ve tarih başlığı bulunan, ayrık ve yuvarlatılmış profesyonel kart.
5. **Reddit** — solda oy sütunu, sağda entry gövdesi ve forum tipi metadata.
6. **okuma** — geniş boşluklu, aksiyonları geri planda tutan sakin okuyucu görünümü.
7. **terminal** — monospace metadata, vurgu çizgisi ve kompakt komut benzeri aksiyonlar.
8. **minimal** — avatar ve ağır ayraçlar olmadan sade içerik ve tek satır metadata.

## Mimari

`EntryLayoutStyle`, her seçeneği benzersiz bir `EntryLayoutFamily` ile eşleştiren SwiftUI'dan bağımsız sözleşme olmaya devam edecek. Eski kayıt değerleri karşılık gelen yeni stile taşınacak; bilinmeyen değerler güvenle klasik stile düşecek.

Çevrimiçi `EntryRowView` ve çevrimdışı `OfflineTopicView`, ortak içerik ve gerçek aksiyon davranışlarını koruyacak; ancak yalnız metrik değiştirmek yerine seçili aileye göre farklı SwiftUI kompozisyonları kuracak. Böylece favori, oy, paylaşım, profil, görsel açma ve okundu hareketleri yerleşim değişirken kaybolmayacak.

`EntryLayoutPickerView` üstte yalnız seçili stilin büyük canlı örneğini, altta sekiz stilin kolay dokunulan seçim kartlarını gösterecek. `UserPreferences` zaten `@Published` olduğu için seçim aynı anda önizlemeyi değiştirir; entry listeleri de stil kimliğini izleyerek ekrana geri dönüldüğünde eski görünümü önbellekten taşımayacak.

## Görsel Kurallar

- Renkler mevcut tema ve iOS semantik renklerinden gelir; sabit açık/koyu hex değerleri kullanılmaz.
- İkonlar SF Symbols adlarıyla kullanılır.
- Marka adları yalnız düzeni tarif eder; üçüncü taraf logo varlıkları kullanılmaz.
- Dokunma hedefleri en az 44 punto tutulur ve Dynamic Type ile metin kırılması engellenmez.

## Doğrulama

Core harness; sekiz benzersiz aileyi, eski seçimlerin göçünü ve güvenli varsayılanı test edecek. SwiftUI kaynakları derlenecek, çevrimiçi ve çevrimdışı stillerin aynı tercih üzerinden yenilendiği kontrol edilecek. Son sürüm imzalanıp iPhone 17'ye kurulacak.
