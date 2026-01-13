# Phase 2 Başlangıç - Cursor'a İlk Komut

Aşağıdaki metni Cursor'a kopyala-yapıştır:

---

## 🚀 BAŞLANGIÇ KOMUTU

```
Phase 2'ye başlıyoruz: Drawing Core

ADIM 0: Proje hazırlığı

1. Feature branch oluştur:
   git checkout -b feature/phase2-drawing-core

2. packages/drawing_core klasör yapısını oluştur:
   packages/drawing_core/
   ├── lib/
   │   ├── drawing_core.dart
   │   └── src/
   │       ├── models/
   │       ├── tools/
   │       ├── history/
   │       ├── input/
   │       └── rendering/
   ├── test/
   │   ├── models/
   │   ├── tools/
   │   ├── history/
   │   └── input/
   └── pubspec.yaml

3. pubspec.yaml içeriği:
   name: drawing_core
   description: UI-agnostic drawing engine core for Flutter
   version: 0.1.0
   
   environment:
     sdk: '>=3.0.0 <4.0.0'
   
   dependencies:
     meta: ^1.9.0
     equatable: ^2.0.5
   
   dev_dependencies:
     test: ^1.24.0

4. lib/drawing_core.dart boş placeholder:
   library drawing_core;
   // Exports will be added as we implement

Sadece yapıyı oluştur, kod YAZMA.
Tamamladığında bana bildir.
```

---

## 📋 ADIM 1 KOMUTU (Yapı oluştuktan sonra)

```
GÖREV: DrawingPoint model oluştur

Dosya: packages/drawing_core/lib/src/models/drawing_point.dart

Gereksinimler:
- x: double (zorunlu)
- y: double (zorunlu)  
- pressure: double (0.0-1.0, varsayılan 1.0)
- tilt: double (radyan, varsayılan 0.0)
- timestamp: int (milliseconds, varsayılan 0)

- Equatable extend et
- copyWith metodu ekle
- toJson / fromJson factory ekle
- Pressure 0.0-1.0 arasında clamp edilmeli

❌ FLUTTER IMPORT KULLANMA
✅ Sadece equatable ve dart:core

Test dosyası: test/models/drawing_point_test.dart
- Constructor testleri
- copyWith testleri
- Equality testleri
- JSON serialization testleri
- Pressure bounds testleri

Bittiğinde:
1. flutter analyze çalıştır
2. flutter test çalıştır
3. Sonuçları bana göster
4. Commit mesajı öner
```

---

## 🔄 HER ADIM SONRASI CURSOR'DAN BEKLENTİ

Cursor her görev sonunda şu formatı kullanmalı:

```
📁 Oluşturulan/Değiştirilen Dosyalar:
- packages/drawing_core/lib/src/models/drawing_point.dart (oluşturuldu)
- packages/drawing_core/test/models/drawing_point_test.dart (oluşturuldu)

🧪 Test Sonuçları:
flutter analyze: ✅ 0 hata, 0 uyarı
flutter test: ✅ 8 test geçti

📝 Önerilen Commit:
feat(core): add DrawingPoint model with full test coverage

- Immutable DrawingPoint class with x, y, pressure, tilt, timestamp
- Equatable for equality comparison
- JSON serialization support
- Comprehensive test coverage

Commit yapılsın mı? (y/n)
```

---

## ⚠️ CURSOR'A HATIRLATMALAR

Her yeni görevde şunu ekle:

```
KURALLAR:
1. Flutter import KULLANMA
2. Renkleri int olarak tut (0xFFRRGGBB)
3. Tüm modeller immutable olmalı
4. Her dosya için test YAZILMALI
5. 300 satırı geçme
6. Commit öncesi ONAY bekle
```
