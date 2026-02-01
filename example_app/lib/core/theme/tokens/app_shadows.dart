/// StarNote Design System - Shadow Tokens
///
/// Tüm gölge değerleri bu dosyadan alınmalıdır.
///
/// Kullanım:
/// ```dart
/// import 'package:example_app/core/theme/tokens/app_shadows.dart';
///
/// Container(
///   decoration: BoxDecoration(
///     boxShadow: AppShadows.md,
///   ),
/// )
/// ```
library;

import 'package:flutter/material.dart';

/// StarNote gölge stilleri.
///
/// Tutarlı elevation/gölge efektleri için kullanılır.
/// Hardcoded shadow kullanımı yasaktır!
abstract class AppShadows {
  // ══════════════════════════════════════════════════════════════════════════
  // BASE SHADOWS
  // ══════════════════════════════════════════════════════════════════════════

  /// Küçük gölge - Subtle elevation
  ///
  /// Opacity: 0.05, Blur: 4, Offset: (0, 2)
  static List<BoxShadow> get sm => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  /// Orta gölge - Standart elevation
  ///
  /// Opacity: 0.08, Blur: 8, Offset: (0, 4)
  static List<BoxShadow> get md => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  /// Büyük gölge - Elevated components
  ///
  /// Opacity: 0.1, Blur: 16, Offset: (0, 8)
  static List<BoxShadow> get lg => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  /// Ekstra büyük gölge - Floating elements
  ///
  /// Opacity: 0.12, Blur: 24, Offset: (0, 12)
  static List<BoxShadow> get xl => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];

  // ══════════════════════════════════════════════════════════════════════════
  // SEMANTIC SHADOWS
  // ══════════════════════════════════════════════════════════════════════════

  /// Card gölgesi (sm)
  static List<BoxShadow> get card => sm;

  /// Modal/Dialog gölgesi (lg)
  static List<BoxShadow> get modal => lg;

  /// FAB gölgesi (md)
  static List<BoxShadow> get fab => md;

  /// Dropdown/Popup gölgesi (md)
  static List<BoxShadow> get dropdown => md;

  // ══════════════════════════════════════════════════════════════════════════
  // SPECIAL SHADOWS
  // ══════════════════════════════════════════════════════════════════════════

  /// Gölge yok
  static List<BoxShadow> get none => [];
}
