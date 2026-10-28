import 'package:drawing_ui/src/l10n/canvas_strings.dart';
import 'package:drawing_ui/src/l10n/catalog_strings.dart';
import 'package:drawing_ui/src/l10n/error_strings.dart';
import 'package:drawing_ui/src/l10n/export_strings.dart';
import 'package:drawing_ui/src/l10n/page_list_strings.dart';
import 'package:drawing_ui/src/l10n/page_strings.dart';
import 'package:drawing_ui/src/l10n/panel_strings.dart';
import 'package:drawing_ui/src/l10n/selection_strings.dart';
import 'package:drawing_ui/src/l10n/template_strings.dart';
import 'package:drawing_ui/src/l10n/tool_strings.dart';
import 'package:drawing_ui/src/l10n/toolbar_strings.dart';

/// All user-facing copy of the editor UI, grouped by area.
///
/// The host app supplies an implementation through `DrawingStringsScope`;
/// without one the widgets fall back to [DrawingStringsTr].
abstract interface class DrawingStrings {
  ToolStrings get tools;
  ToolbarStrings get toolbar;
  PanelStrings get panels;
  CatalogStrings get catalog;
  SelectionStrings get selection;
  PageStrings get pages;
  PageListStrings get pageList;
  ExportStrings get export;
  TemplateStrings get templates;
  ErrorStrings get errors;
  CanvasStrings get canvas;
}

/// Turkish copy, the built-in default.
class DrawingStringsTr implements DrawingStrings {
  const DrawingStringsTr();

  @override
  ToolStrings get tools => const ToolStringsTr();

  @override
  ToolbarStrings get toolbar => const ToolbarStringsTr();

  @override
  PanelStrings get panels => const PanelStringsTr();

  @override
  CatalogStrings get catalog => const CatalogStringsTr();

  @override
  SelectionStrings get selection => const SelectionStringsTr();

  @override
  PageStrings get pages => const PageStringsTr();

  @override
  PageListStrings get pageList => const PageListStringsTr();

  @override
  ExportStrings get export => const ExportStringsTr();

  @override
  TemplateStrings get templates => const TemplateStringsTr();

  @override
  ErrorStrings get errors => const ErrorStringsTr();

  @override
  CanvasStrings get canvas => const CanvasStringsTr();
}
