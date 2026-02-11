/// StarNote Design System - Border Radius Tokens
///
/// Standart radius değeri: 10dp (md)
/// Tüm radius değerleri bu dosyadan alınmalıdır.
///
/// Kullanım:
/// ```dart
/// import 'package:example_app/core/theme/tokens/app_radius.dart';
///
/// BorderRadius.circular(AppRadius.md)
/// BorderRadius.circular(AppRadius.card)
/// ```
library;

/// StarNote border radius değerleri.
///
/// Tutarlı köşe yuvarlaklığı için kullanılır.
/// Hardcoded radius kullanımı yasaktır!
abstract class AppRadius {
  // ══════════════════════════════════════════════════════════════════════════
  // BASE RADIUS
  // ══════════════════════════════════════════════════════════════════════════

  /// 0dp - Köşe yuvarlaklığı yok
  static const double none = 0;

  /// 4dp - Ekstra küçük radius
  static const double xs = 4;

  /// 8dp - Küçük radius
  static const double sm = 8;

  /// 10dp - Orta radius (STANDART - Onaylı)
  ///
  /// ✅ Bu değer varsayılan olarak kullanılmalıdır.
  static const double md = 10;

  /// 12dp - Büyük radius
  static const double lg = 12;

  /// 16dp - Ekstra büyük radius
  static const double xl = 16;

  /// 20dp - Çok büyük radius
  static const double xxl = 20;

  /// 999dp - Tam yuvarlak (pill shape)
  static const double full = 999;

  // ══════════════════════════════════════════════════════════════════════════
  // SEMANTIC RADIUS
  // ══════════════════════════════════════════════════════════════════════════

  /// Button köşe radius'u (10dp)
  static const double button = md;

  /// Card köşe radius'u (12dp)
  static const double card = lg;

  /// Modal/Dialog köşe radius'u (16dp)
  static const double modal = xl;

  /// Bottom sheet köşe radius'u (20dp - sadece üst köşeler)
  static const double bottomSheet = xxl;

  /// TextField köşe radius'u (10dp)
  static const double textField = md;
}
