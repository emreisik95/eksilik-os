# Entry Layout Selector Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Entry satırı için Ayarlar'dan seçilip kalıcı olarak saklanan sekiz farklı görünüm eklemek.

**Architecture:** SwiftUI'dan bağımsız `EntryLayoutStyle` sunum kararlarının tek kaynağı olacak. `UserPreferences` seçimi yayınlayacak; Ayarlar önizleme ekranı ile çevrimiçi/çevrimdışı entry görünümleri aynı tercihi okuyacak.

**Tech Stack:** Swift 5.9, SwiftUI, `UserDefaults`, Core test harness, XcodeGen.

### Task 1: Stil sözleşmesi

**Files:**
- Create: `Core/Presentation/EntryLayoutStyle.swift`
- Modify: `CoreTestHarness/main.swift`
- Modify: `Package.swift`

1. Sekiz case, güvenli raw-value çözümleme ve sunum metrikleri için başarısız harness kontrollerini yaz.
2. `swift run EksilikCoreHarness` ile beklenen derleme/test hatasını gör.
3. Saf Foundation modelini ekle ve pakete dahil et.
4. Harness'i yeniden çalıştırıp yeşil olduğunu doğrula.

### Task 2: Kalıcı tercih ve seçici

**Files:**
- Modify: `Core/Storage/UserPreferences.swift`
- Create: `Views/Settings/EntryLayoutPickerView.swift`
- Modify: `Views/Settings/SettingsView.swift`

1. Seçili stili `UserDefaults` üzerinden yükleyen ve değişiklikte kaydeden yayınlanan tercihi ekle.
2. Sekiz seçeneği canlı mini önizlemeler ve seçili işaretiyle gösteren ekranı ekle.
3. Görünüm seçiciyi Ayarlar > Görünüm bölümüne bağla.

### Task 3: Entry görünümleri

**Files:**
- Modify: `Views/Entry/EntryRowView.swift`
- Modify: `Views/Offline/OfflineTopicView.swift`

1. İçerik, yazar, tarih ve aksiyon parçalarını ortak alt görünümlere ayır.
2. Seçili stilin sıralama, boşluk, avatar, kart ve aksiyon yoğunluğu kararlarını çevrimiçi satıra uygula.
3. Aynı metrik ve metadata kararlarını çevrimdışı satıra uygula; swipe/read davranışını koru.

### Task 4: Proje ve doğrulama

**Files:**
- Regenerate: `EksilikApp.xcodeproj/project.pbxproj`

1. `xcodegen generate` çalıştır.
2. Core harness'i çalıştır.
3. Kullanılabilir Xcode developer diziniyle iOS hedefini derle.
4. Değişiklik kapsamını ve git diff'ini kontrol et.
