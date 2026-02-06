/// StarNote Design System - AppDivider Component
///
/// Divider komponenti.
///
/// Kullanım:
/// ```dart
/// AppDivider()
/// AppDivider(indent: 16, endIndent: 16)
/// AppDivider(thickness: 2, color: Colors.red)
/// ```
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';

/// StarNote divider komponenti.
///
/// Horizontal ayırıcı çizgi.
class AppDivider extends StatelessWidget {
  /// Sol boşluk.
  final double? indent;

  /// Sağ boşluk.
  final double? endIndent;

  /// Çizgi kalınlığı.
  final double thickness;

  /// Çizgi rengi (null ise theme'den alınır).
  final Color? color;

  const AppDivider({
    this.indent,
    this.endIndent,
    this.thickness = 1,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor =
        isDark ? AppColors.outlineDark : AppColors.outlineLight;

    return Divider(
      indent: indent,
      endIndent: endIndent,
      thickness: thickness,
      height: thickness,
      color: color ?? defaultColor,
    );
  }
}
