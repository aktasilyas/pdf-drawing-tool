/// ElyaNotes Design System - Icon Size Tokens
///
/// Tüm icon boyutları bu dosyadan alınmalıdır.
///
/// Kullanım:
/// ```dart
/// import 'package:example_app/core/theme/tokens/app_icon_sizes.dart';
///
/// Icon(Icons.home, size: AppIconSize.lg)
/// Icon(Icons.edit, size: AppIconSize.toolbar)
/// ```
library;

/// ElyaNotes icon boyutları.
///
/// Tutarlı icon boyutları için kullanılır.
/// Hardcoded icon size kullanımı yasaktır!
abstract class AppIconSize {
  // ══════════════════════════════════════════════════════════════════════════
  // BASE SIZES
  // ══════════════════════════════════════════════════════════════════════════

  /// 12dp - Ekstra küçük icon (badge içi, inline)
  static const double xs = 12;

  /// 16dp - Küçük icon
  static const double sm = 16;

  /// 20dp - Orta icon (standart)
  static const double md = 20;

  /// 24dp - Büyük icon (Material default)
  static const double lg = 24;

  /// 28dp - Ekstra büyük icon
  static const double xl = 28;

  /// 32dp - Çok büyük icon
  static const double xxl = 32;

  /// 48dp - Dev icon (empty state, splash)
  static const double huge = 48;

  // ══════════════════════════════════════════════════════════════════════════
  // SEMANTIC SIZES
  // ══════════════════════════════════════════════════════════════════════════

  /// Buton içi icon (20dp)
  static const double button = md;

  /// Liste item icon (24dp)
  static const double listTile = lg;

  /// Navigation bar icon (24dp)
  static const double navBar = lg;

  /// Toolbar icon (20dp)
  static const double toolbar = md;

  /// FAB icon (24dp)
  static const double fab = lg;

  /// Empty state icon (48dp)
  static const double emptyState = huge;
}
