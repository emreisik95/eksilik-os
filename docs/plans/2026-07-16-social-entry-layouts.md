# Social Entry Layouts Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Ayarlar'da canlı olarak seçilen, çevrimiçi ve indirilmiş entry'lerde gerçekten farklı kompozisyonlara dönüşen sekiz sosyal okuma düzeni sunmak.

**Architecture:** Saf Foundation katmanındaki `EntryLayoutStyle`, benzersiz yerleşim ailelerini ve eski tercih göçünü tanımlar. SwiftUI katmanı aynı entry içeriği ve aksiyonlarını koruyan aileye özel kompozisyonlar üretir; ayarlar seçicisi seçili aileyi büyük canlı önizlemede gösterir.

**Tech Stack:** Swift 5.9, SwiftUI, UserDefaults, Core test harness, XCTest, XcodeGen.

### Task 1: Yerleşim sözleşmesi ve tercih göçü

**Files:**
- Modify: `CoreTestHarness/main.swift`
- Modify: `EksilikTests/Settings/UserPreferencesTests.swift`
- Modify: `Core/Presentation/EntryLayoutStyle.swift`

1. Sekiz sosyal stilin benzersiz aileleri ve eski raw-value göçleri için başarısız testler yaz.
2. `swift run EksilikCoreHarness` ile testlerin beklenen nedenle kırmızı olduğunu gör.
3. Yeni stil/aile sözleşmesini ve geriye dönük çözümlemeyi en küçük değişiklikle uygula.
4. Harness'i yeniden çalıştırıp yeşil sonucu doğrula.

### Task 2: Canlı ve ayırt edilebilir ayar önizlemesi

**Files:**
- Modify: `Views/Settings/EntryLayoutPickerView.swift`

1. Seçili stile bağlı tek büyük canlı önizlemeyi ekranın üstüne yerleştir.
2. Sekiz aile için farklı avatar, metadata, kart, oy sütunu ve aksiyon kompozisyonları çiz.
3. Seçim kartlarını büyük dokunma hedefleri ve seçili durumuyla altta göster.
4. SwiftUI derlemesiyle önizleme anahtarlarının ve sembollerin geçerli olduğunu doğrula.

### Task 3: Çevrimiçi entry kompozisyonları

**Files:**
- Modify: `Views/Entry/EntryRowView.swift`
- Modify: `Views/Entry/EntryListView.swift`

1. Ortak yazar, metadata, içerik, medya ve aksiyon parçalarını davranış kaybetmeden yeniden kullan.
2. Klasik, X, Instagram, LinkedIn, Reddit, okuma, terminal ve minimal aileleri için ayrı gövde kompozisyonları kur.
3. Listeyi seçili stil kimliğine bağlayarak ayardan dönünce anında yeniden üret.
4. iOS hedefini derleyip tüm ailelerin tip kontrolünden geçtiğini doğrula.

### Task 4: Çevrimdışı eşleşme ve okundu hareketleri

**Files:**
- Modify: `Views/Offline/OfflineTopicView.swift`

1. Aynı sekiz aileyi indirilen entry satırlarına uygula.
2. Görsel açma, okundu opaklığı ve iki yönlü swipe aksiyonlarını koru.
3. Çevrimdışı listeyi stil kimliğine bağla.
4. Harness ve iOS derlemesini yeniden çalıştır.

### Task 5: Son doğrulama ve cihaza teslim

**Files:**
- Regenerate: `EksilikApp.xcodeproj/project.pbxproj` (yalnız gerekirse)

1. `swift run EksilikCoreHarness`, ilgili XCTest/build kontrolleri ve `git diff --check` çalıştır.
2. Değişiklikleri yalnız bu özellik kapsamında gözden geçir; `selfIdentity.plist` dosyasını dışarıda bırak.
3. Commit ve push yap, CI artifact'ini al.
4. Uygulamayı yerel geliştirme profiliyle imzala, iPhone 17'ye kur ve başlat.
