import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:example_app/features/editor/presentation/l10n/app_drawing_strings.dart';
import 'package:example_app/l10n/l10n.dart';

/// Installs [AppDrawingStrings] for the active app locale. Place it below
/// the localizations (e.g. in `MaterialApp.builder`).
class AppDrawingStringsScope extends StatelessWidget {
  const AppDrawingStringsScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DrawingStringsScope(
      strings: AppDrawingStrings(context.l10n),
      child: child,
    );
  }
}
