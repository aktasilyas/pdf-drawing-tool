import 'package:drawing_ui/drawing_ui.dart';
import 'package:example_app/features/editor/presentation/l10n/app_canvas_strings.dart';
import 'package:example_app/features/editor/presentation/l10n/app_catalog_strings.dart';
import 'package:example_app/features/editor/presentation/l10n/app_error_strings.dart';
import 'package:example_app/features/editor/presentation/l10n/app_export_strings.dart';
import 'package:example_app/features/editor/presentation/l10n/app_page_list_strings.dart';
import 'package:example_app/features/editor/presentation/l10n/app_page_strings.dart';
import 'package:example_app/features/editor/presentation/l10n/app_panel_strings.dart';
import 'package:example_app/features/editor/presentation/l10n/app_selection_strings.dart';
import 'package:example_app/features/editor/presentation/l10n/app_template_strings.dart';
import 'package:example_app/features/editor/presentation/l10n/app_tool_strings.dart';
import 'package:example_app/features/editor/presentation/l10n/app_toolbar_strings.dart';
import 'package:example_app/l10n/l10n.dart';

/// Editor copy from the app's ARB files, handed to drawing_ui through
/// [DrawingStringsScope].
///
/// Equality follows the locale, so the scope only notifies on a locale change.
class AppDrawingStrings implements DrawingStrings {
  AppDrawingStrings(AppLocalizations l10n)
      : _locale = l10n.localeName,
        tools = AppToolStrings(l10n),
        toolbar = AppToolbarStrings(l10n),
        panels = AppPanelStrings(l10n),
        catalog = AppCatalogStrings(l10n),
        selection = AppSelectionStrings(l10n),
        pages = AppPageStrings(l10n),
        pageList = AppPageListStrings(l10n),
        export = AppExportStrings(l10n),
        templates = AppTemplateStrings(l10n),
        errors = AppErrorStrings(l10n),
        canvas = AppCanvasStrings(l10n);

  final String _locale;

  @override
  final ToolStrings tools;

  @override
  final ToolbarStrings toolbar;

  @override
  final PanelStrings panels;

  @override
  final CatalogStrings catalog;

  @override
  final SelectionStrings selection;

  @override
  final PageStrings pages;

  @override
  final PageListStrings pageList;

  @override
  final ExportStrings export;

  @override
  final TemplateStrings templates;

  @override
  final ErrorStrings errors;

  @override
  final CanvasStrings canvas;

  @override
  bool operator ==(Object other) =>
      other is AppDrawingStrings && other._locale == _locale;

  @override
  int get hashCode => _locale.hashCode;
}
