/// StarNote Design System - Animation Duration & Curve Tokens
///
/// Tüm animasyon süreleri ve eğrileri bu dosyadan alınmalıdır.
///
/// Kullanım:
/// ```dart
/// import 'package:example_app/core/theme/tokens/app_durations.dart';
///
/// AnimatedContainer(
///   duration: AppDurations.normal,
///   curve: AppCurves.standard,
/// )
/// ```
library;

import 'package:flutter/material.dart';

/// StarNote animasyon süreleri.
///
/// Tutarlı animasyon hızları için kullanılır.
/// Hardcoded duration kullanımı yasaktır!
abstract class AppDurations {
  // ══════════════════════════════════════════════════════════════════════════
  // BASE DURATIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// 100ms - Anlık geçiş (hover, focus state)
  static const Duration instant = Duration(milliseconds: 100);

  /// 200ms - Hızlı animasyon (button press, toggle)
  static const Duration fast = Duration(milliseconds: 200);

  /// 300ms - Normal animasyon (standart geçişler)
  static const Duration normal = Duration(milliseconds: 300);

  /// 400ms - Yavaş animasyon (complex transitions)
  static const Duration slow = Duration(milliseconds: 400);

  /// 500ms - Çok yavaş animasyon (large elements)
  static const Duration slower = Duration(milliseconds: 500);

  // ══════════════════════════════════════════════════════════════════════════
  // SEMANTIC DURATIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Buton basma animasyonu (200ms)
  static const Duration buttonPress = fast;

  /// Sayfa geçiş animasyonu (300ms)
  static const Duration pageTransition = normal;

  /// Modal açılma animasyonu (300ms)
  static const Duration modalOpen = normal;

  /// Snackbar görünme süresi (4 saniye)
  static const Duration snackbar = Duration(seconds: 4);

  /// Tooltip görünme süresi (2 saniye)
  static const Duration tooltip = Duration(seconds: 2);

  /// Splash ekranı süresi (2 saniye)
  static const Duration splash = Duration(seconds: 2);

  /// Debounce süresi - arama vb. (300ms)
  static const Duration debounce = normal;
}

/// StarNote animasyon eğrileri.
///
/// Tutarlı animasyon eğrileri için kullanılır.
/// Hardcoded curve kullanımı yasaktır!
abstract class AppCurves {
  // ══════════════════════════════════════════════════════════════════════════
  // BASE CURVES
  // ══════════════════════════════════════════════════════════════════════════

  /// Standart eğri - Genel kullanım (easeInOut)
  static const Curve standard = Curves.easeInOut;

  /// Giriş eğrisi - Element girişi (easeOut)
  ///
  /// Hızlı başlar, yavaş biter.
  static const Curve enter = Curves.easeOut;

  /// Çıkış eğrisi - Element çıkışı (easeIn)
  ///
  /// Yavaş başlar, hızlı biter.
  static const Curve exit = Curves.easeIn;

  /// Bounce eğrisi - Vurgulu animasyonlar (elasticOut)
  ///
  /// ⚠️ Dikkatli kullan! Sadece özel vurgular için.
  static const Curve bounce = Curves.elasticOut;

  // ══════════════════════════════════════════════════════════════════════════
  // SEMANTIC CURVES
  // ══════════════════════════════════════════════════════════════════════════

  /// Modal açılma eğrisi
  static const Curve modalEnter = enter;

  /// Modal kapanma eğrisi
  static const Curve modalExit = exit;

  /// Sayfa geçiş eğrisi
  static const Curve pageTransition = standard;

  /// Fade animasyonu eğrisi
  static const Curve fade = Curves.easeInOut;
}
