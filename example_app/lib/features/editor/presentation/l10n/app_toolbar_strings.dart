import 'package:drawing_ui/drawing_ui.dart';
import 'package:example_app/l10n/l10n.dart';

/// [ToolbarStrings] backed by the generated [AppLocalizations].
class AppToolbarStrings extends ToolbarStrings {
  const AppToolbarStrings(this._l10n);

  final AppLocalizations _l10n;

  @override
  String get home => _l10n.editorToolbarHome;

  @override
  String get pages => _l10n.editorToolbarPages;

  @override
  String get ruler => _l10n.editorToolbarRuler;

  @override
  String get audio => _l10n.editorToolbarAudio;

  @override
  String get readerMode => _l10n.editorToolbarReaderMode;

  @override
  String get editMode => _l10n.editorToolbarEditMode;

  @override
  String get more => _l10n.editorToolbarMore;

  @override
  String get layers => _l10n.editorToolbarLayers;

  @override
  String get addPage => _l10n.editorToolbarAddPage;

  @override
  String get export => _l10n.editorToolbarExport;

  @override
  String get ai => _l10n.editorToolbarAi;

  @override
  String get untitled => _l10n.editorToolbarUntitled;

  @override
  String get moreColors => _l10n.editorToolbarMoreColors;

  @override
  String get colorSetHighlighter => _l10n.editorToolbarColorSetHighlighter;

  @override
  String get colorSetPastel => _l10n.editorToolbarColorSetPastel;

  @override
  String get colorSetBasic => _l10n.editorToolbarColorSetBasic;

  @override
  String get colorSetNeon => _l10n.editorToolbarColorSetNeon;

  @override
  String selectedColor(String hex) => _l10n.editorToolbarSelectedColor(hex);

  @override
  String color(String hex) => _l10n.editorToolbarColor(hex);

  @override
  String thickness(String value) => _l10n.editorToolbarThickness(value);

  @override
  String get moreTools => _l10n.editorToolbarMoreTools;

  @override
  String get readOnlyActive => _l10n.editorToolbarReadOnlyActive;

  @override
  String get readOnly => _l10n.editorToolbarReadOnly;

  @override
  String get undo => _l10n.editorToolbarUndo;

  @override
  String get redo => _l10n.editorToolbarRedo;

  @override
  String get recordingInProgress => _l10n.editorToolbarRecordingInProgress;

  @override
  String get record => _l10n.editorToolbarRecord;

  @override
  String get micPermissionRequired => _l10n.editorToolbarMicPermissionRequired;

  @override
  String get showRecordings => _l10n.editorToolbarShowRecordings;

  @override
  String get settingsTabTools => _l10n.editorToolbarSettingsTabTools;

  @override
  String get settingsTabExtraTools => _l10n.editorToolbarSettingsTabExtraTools;

  @override
  String get settingsToolsHint => _l10n.editorToolbarSettingsToolsHint;

  @override
  String get settingsExtraToolsHint =>
      _l10n.editorToolbarSettingsExtraToolsHint;

  @override
  String get settingsReset => _l10n.editorToolbarSettingsReset;
}
