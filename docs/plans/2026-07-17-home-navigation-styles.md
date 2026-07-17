# Home Navigation Styles Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Ana sayfa iç sekmelerini Ayarlar'dan seçilebilen beş navigasyon kabuğu, kalıcı sıralama ve yatay swipe ile sunmak.

**Architecture:** Foundation tabanlı `HomeNavigationStyle`, sekme kataloğu, sıra normalizasyonu ve swipe politikası davranışın test edilebilir tek kaynağı olacak. `UserPreferences` seçimleri yayınlayacak; `HomeTabView` ortak içerik akışını koruyup yalnız seçili navigasyon kabuğunu değiştirecek.

**Tech Stack:** Swift 5.9, SwiftUI, UserDefaults, Core test harness, XCTest, XcodeGen, GitHub Actions.

### Task 1: Saf navigasyon sözleşmesi

**Files:**
- Create: `Core/Presentation/HomeNavigationStyle.swift`
- Modify: `CoreTestHarness/main.swift`
- Modify: `Package.swift`

1. Beş benzersiz stil, legacy konum göçü, sıra normalizasyonu, login filtresi ve swipe sınırları için başarısız harness kontrolleri yaz.
2. `swift run EksilikCoreHarness` çalıştırıp eksik API nedeniyle kırmızı sonucu gör.
3. Foundation modelini en küçük davranışla uygula ve SwiftPM kaynağına ekle.
4. Harness'i yeniden çalıştırıp kontrolleri yeşile getir.

### Task 2: Tercih kalıcılığı

**Files:**
- Modify: `EksilikTests/Settings/UserPreferencesTests.swift`
- Modify: `Core/Storage/UserPreferences.swift`

1. Stil, eski `top/bottom` göçü, görünür sekmeler ve sıra kalıcılığı için XCTest yaz.
2. CI testinin mevcut sınıfta eksik API nedeniyle kırılacağını doğrula; core kaynak derlemesini kırmızı kanıt olarak kullan.
3. `@Published` stil/sıra/görünürlük tercihlerini aynı enjekte edilen UserDefaults üzerinden uygula.
4. Bilinmeyen/eski veriyi saf modelle normalize et.

### Task 3: Canlı stil seçici

**Files:**
- Create: `Views/Settings/HomeNavigationStylePickerView.swift`
- Modify: `Views/Settings/SettingsView.swift`

1. Üstte seçili stilin büyük canlı telefon önizlemesini oluştur.
2. Beş stil için ayırt edilebilir alt bar, üst rail, dock, drawer ve menü maketlerini çiz.
3. Büyük dokunma hedefli seçim kartlarını ekle.
4. Eski konum Picker'ını yeni navigasyon seçicisiyle değiştir.

### Task 4: Ana ekran kabukları ve swipe

**Files:**
- Modify: `Views/Home/HomeTabView.swift`

1. Sekme listesini ortak katalog, görünürlük, sıra ve oturum filtresinden üret.
2. İçerik görünümünü seçili sekmeden bağımsız ortak bir builder'a ayır.
3. Klasik alt bar, üst rail, yüzen dock, yan panel ve menü başlatıcı kabuklarını ekle.
4. Saf `HomeNavigationPolicy` üzerinden yatay swipe ile önceki/sonraki sekmeye geç.
5. Gizlenen veya logout ile kullanılamayan seçimi ilk geçerli sekmeye düzelt.

### Task 5: Sıralama ve görünürlük ekranı

**Files:**
- Modify: `Views/Settings/TabCustomizationView.swift`

1. Katalogdaki tüm sekmeleri kalıcı sırayla göster.
2. Görünürlük toggle davranışını koru.
3. `onMove` ve EditButton ile drag sıralamasını kalıcılaştır.
4. En az bir sekmenin görünür kalmasını güvenceye al.

### Task 6: Doğrulama ve iPhone 17 teslimi

**Files:**
- Regenerate: `EksilikApp.xcodeproj/project.pbxproj` (yalnız CI/XcodeGen çıktısı gerektiğinde)

1. Swift parser, `swift run EksilikCoreHarness` ve `git diff --check` çalıştır.
2. Özellik kapsamını gözden geçir; `selfIdentity.plist` dosyasını stage etme.
3. Commit/push yap ve Build & Test ile Build Device Artifact işlerini bekle.
4. Artifact'i geliştirme profilleriyle imzala ve imzayı doğrula.
5. iPhone 17'ye kur, kurulu bundle bilgisini ve mümkünse açılışı doğrula.
