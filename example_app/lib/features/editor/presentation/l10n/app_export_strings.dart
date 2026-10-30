import 'package:drawing_ui/drawing_ui.dart';
import 'package:example_app/l10n/l10n.dart';

/// [ExportStrings] backed by the generated [AppLocalizations].
class AppExportStrings extends ExportStrings {
  const AppExportStrings(this._l10n);

  final AppLocalizations _l10n;

  @override
  String get scopeAll => _l10n.editorExportScopeAll;

  @override
  String get scopeCurrent => _l10n.editorExportScopeCurrent;

  @override
  String get scopeRange => _l10n.editorExportScopeRange;

  @override
  String get from => _l10n.editorExportFrom;

  @override
  String get to => _l10n.editorExportTo;

  @override
  String get includeTemplate => _l10n.editorExportIncludeTemplate;

  @override
  String get exportPng => _l10n.editorExportExportPng;

  @override
  String get exportPdf => _l10n.editorExportExportPdf;

  @override
  String get sharePdf => _l10n.editorExportSharePdf;

  @override
  String invalidRange(int count) => _l10n.editorExportInvalidRange(count);

  @override
  String get savePdfDialog => _l10n.editorExportSavePdfDialog;

  @override
  String get savePngDialog => _l10n.editorExportSavePngDialog;

  @override
  String get fallbackFileName => _l10n.editorExportFallbackFileName;

  @override
  String pageFileName(String title, int page) =>
      _l10n.editorExportPageFileName(title, page);

  @override
  String get exporting => _l10n.editorExportExporting;

  @override
  String percent(int percent) => _l10n.editorExportPercent(percent);

  @override
  String remainingSeconds(int seconds) =>
      _l10n.editorExportRemainingSeconds(seconds);

  @override
  String remainingMinutes(int minutes) =>
      _l10n.editorExportRemainingMinutes(minutes);

  @override
  String get saved => _l10n.editorExportSaved;

  @override
  String savedWithSize(String size) => _l10n.editorExportSavedWithSize(size);

  @override
  String get cancelled => _l10n.editorExportCancelled;

  @override
  String get inProgress => _l10n.editorExportInProgress;

  @override
  String pagesWithoutPdfBackground(int count) =>
      _l10n.editorExportPagesWithoutPdfBackground(count);

  @override
  String pagesWithoutImages(int count) =>
      _l10n.editorExportPagesWithoutImages(count);
}
