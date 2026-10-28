import 'package:flutter/widgets.dart';

import 'package:drawing_ui/src/l10n/drawing_strings.dart';

/// Provides [DrawingStrings] to the editor widgets below it.
class DrawingStringsScope extends InheritedWidget {
  const DrawingStringsScope({
    super.key,
    required this.strings,
    required super.child,
  });

  final DrawingStrings strings;

  /// The strings of the nearest scope, or null when none is installed.
  static DrawingStrings? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<DrawingStringsScope>()
      ?.strings;

  @override
  bool updateShouldNotify(DrawingStringsScope oldWidget) =>
      strings != oldWidget.strings;
}

/// Access to the editor strings from any widget.
extension DrawingStringsContext on BuildContext {
  /// Strings of the nearest [DrawingStringsScope], Turkish when absent.
  DrawingStrings get drawingStrings =>
      DrawingStringsScope.maybeOf(this) ?? const DrawingStringsTr();
}
