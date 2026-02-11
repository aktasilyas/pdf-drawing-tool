/// StarNote Design System - Responsive Utilities
///
/// Responsive design yardımcıları.
///
/// Kullanım:
/// ```dart
/// if (Responsive.isPhone(context)) {
///   // Phone layout
/// } else {
///   // Tablet layout
/// }
///
/// double padding = Responsive.value(
///   context,
///   compact: 16,
///   expanded: 24,
/// );
/// ```
library;

import 'package:flutter/material.dart';

/// Breakpoint sabitleri.
abstract class AppBreakpoints {
  /// Compact (phone) - 0-599px
  static const double compact = 0;

  /// Medium (phone landscape, small tablet) - 600-839px
  static const double medium = 600;

  /// Expanded (tablet) - 840px+
  static const double expanded = 840;
}

/// Cihaz tipleri.
enum DeviceType {
  /// Telefon (< 600px)
  phone,

  /// Tablet (>= 600px)
  tablet,
}

/// Ekran boyutu kategorileri.
enum ScreenSize {
  /// Compact: 0-599px
  compact,

  /// Medium: 600-839px
  medium,

  /// Expanded: 840px+
  expanded,
}

/// Responsive design yardımcı sınıfı.
abstract class Responsive {
  /// Cihaz tipini döndürür (phone/tablet).
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < AppBreakpoints.medium ? DeviceType.phone : DeviceType.tablet;
  }

  /// Ekran boyutu kategorisini döndürür.
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= AppBreakpoints.expanded) {
      return ScreenSize.expanded;
    } else if (width >= AppBreakpoints.medium) {
      return ScreenSize.medium;
    } else {
      return ScreenSize.compact;
    }
  }

  /// Telefon mu? (< 600px)
  static bool isPhone(BuildContext context) {
    return getDeviceType(context) == DeviceType.phone;
  }

  /// Tablet mi? (>= 600px)
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }

  /// Ekran boyutuna göre değer döndürür.
  ///
  /// Fallback: expanded ?? medium ?? compact
  static T value<T>(
    BuildContext context, {
    required T compact,
    T? medium,
    T? expanded,
  }) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.compact:
        return compact;
      case ScreenSize.medium:
        return medium ?? compact;
      case ScreenSize.expanded:
        return expanded ?? medium ?? compact;
    }
  }

  /// Ekran padding'i döndürür.
  ///
  /// Phone: 16dp, Tablet: 24dp
  static double screenPadding(BuildContext context) {
    return isPhone(context) ? 16.0 : 24.0;
  }

  /// Ekran genişliğini döndürür.
  static double width(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Ekran yüksekliğini döndürür.
  static double height(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
}
