/// ElyaNotes Design System - ResponsiveBuilder Component
///
/// Ekran boyutuna göre farklı widget döndürür.
///
/// Kullanım:
/// ```dart
/// ResponsiveBuilder(
///   compact: PhoneLayout(),
///   expanded: TabletLayout(),
/// )
///
/// ResponsiveBuilder(
///   builder: (context, screenSize, deviceType) {
///     if (deviceType == DeviceType.phone) {
///       return PhoneLayout();
///     }
///     return TabletLayout();
///   },
/// )
/// ```
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/utils/responsive.dart';

/// ElyaNotes responsive builder komponenti.
///
/// Ekran boyutuna göre farklı layout'lar gösterir.
class ResponsiveBuilder extends StatelessWidget {
  /// Compact (phone) layout.
  final Widget? compact;

  /// Medium (phone landscape, small tablet) layout.
  final Widget? medium;

  /// Expanded (tablet) layout.
  final Widget? expanded;

  /// Builder function (alternatif kullanım).
  final Widget Function(BuildContext, ScreenSize, DeviceType)? builder;

  const ResponsiveBuilder({
    this.compact,
    this.medium,
    this.expanded,
    this.builder,
    super.key,
  }) : assert(
          compact != null || builder != null,
          'Either compact or builder must be provided',
        );

  @override
  Widget build(BuildContext context) {
    final screenSize = Responsive.getScreenSize(context);
    final deviceType = Responsive.getDeviceType(context);

    // Builder varsa onu kullan
    if (builder != null) {
      return builder!(context, screenSize, deviceType);
    }

    // Widget-based usage
    switch (screenSize) {
      case ScreenSize.compact:
        return compact!;

      case ScreenSize.medium:
        return medium ?? compact!;

      case ScreenSize.expanded:
        return expanded ?? medium ?? compact!;
    }
  }
}
