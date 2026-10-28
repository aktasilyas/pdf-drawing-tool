import 'package:drawing_ui/src/l10n/tool_strings.dart';
import 'package:drawing_ui/src/l10n/toolbar_strings.dart';

/// All user-facing copy of the editor UI, grouped by area.
///
/// The host app supplies an implementation through `DrawingStringsScope`;
/// without one the widgets fall back to [DrawingStringsTr].
abstract interface class DrawingStrings {
  ToolStrings get tools;
  ToolbarStrings get toolbar;
}

/// Turkish copy, the built-in default.
class DrawingStringsTr implements DrawingStrings {
  const DrawingStringsTr();

  @override
  ToolStrings get tools => const ToolStringsTr();

  @override
  ToolbarStrings get toolbar => const ToolbarStringsTr();
}
