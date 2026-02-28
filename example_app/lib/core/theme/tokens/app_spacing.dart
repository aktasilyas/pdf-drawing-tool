/// ElyaNotes Design System - Spacing Tokens
///
/// 4dp grid sistemi kullanır.
/// Tüm spacing değerleri bu dosyadan alınmalıdır.
///
/// Kullanım:
/// ```dart
/// import 'package:example_app/core/theme/tokens/app_spacing.dart';
///
/// Padding(padding: EdgeInsets.all(AppSpacing.lg))
/// SizedBox(height: AppSpacing.sm)
/// ```
library;

/// ElyaNotes spacing değerleri.
///
/// 4dp grid sistemine dayalı tutarlı boşluk değerleri.
/// Hardcoded spacing kullanımı yasaktır!
abstract class AppSpacing {
  // ══════════════════════════════════════════════════════════════════════════
  // BASE SPACING (4dp Grid)
  // ══════════════════════════════════════════════════════════════════════════

  /// 2dp - Çok küçük boşluk (icon içi padding vb.)
  static const double xxs = 2;

  /// 4dp - Ekstra küçük boşluk
  static const double xs = 4;

  /// 8dp - Küçük boşluk (element içi)
  static const double sm = 8;

  /// 12dp - Orta boşluk
  static const double md = 12;

  /// 16dp - Büyük boşluk (standart padding)
  static const double lg = 16;

  /// 24dp - Ekstra büyük boşluk
  static const double xl = 24;

  /// 32dp - Çok büyük boşluk
  static const double xxl = 32;

  /// 48dp - Dev boşluk
  static const double xxxl = 48;

  /// 64dp - En büyük boşluk
  static const double huge = 64;

  // ══════════════════════════════════════════════════════════════════════════
  // SEMANTIC SPACING
  // ══════════════════════════════════════════════════════════════════════════

  /// Mobil ekran kenar boşluğu (16dp)
  static const double screenPaddingMobile = 16;

  /// Tablet ekran kenar boşluğu (24dp)
  static const double screenPaddingTablet = 24;

  /// Card iç boşluğu (16dp)
  static const double cardPadding = 16;

  /// Liste elemanları arası boşluk (12dp)
  static const double listItemSpacing = 12;

  /// Bölümler arası boşluk (24dp)
  static const double sectionSpacing = 24;

  /// Butonlar arası boşluk (8dp)
  static const double buttonSpacing = 8;

  // ══════════════════════════════════════════════════════════════════════════
  // COMPONENT SIZES
  // ══════════════════════════════════════════════════════════════════════════

  /// Toolbar yüksekliği (56dp)
  static const double toolbarHeight = 56;

  /// Bottom navigation bar yüksekliği (80dp)
  static const double bottomNavHeight = 80;

  /// Floating action button boyutu (56dp)
  static const double fabSize = 56;

  /// Sidebar genişliği - tablet (280dp)
  static const double sidebarWidth = 280;

  /// Navigation rail genişliği (80dp)
  static const double navigationRailWidth = 80;

  // ══════════════════════════════════════════════════════════════════════════
  // TOUCH TARGETS
  // ══════════════════════════════════════════════════════════════════════════

  /// Minimum dokunma alanı (48dp) - Material Design guideline
  ///
  /// ⚠️ Tüm interaktif elementler en az bu boyutta olmalı!
  static const double minTouchTarget = 48;
}
