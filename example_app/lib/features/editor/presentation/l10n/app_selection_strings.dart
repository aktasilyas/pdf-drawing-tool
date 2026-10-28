import 'package:drawing_ui/drawing_ui.dart';
import 'package:example_app/l10n/l10n.dart';

/// [SelectionStrings] backed by the generated [AppLocalizations].
class AppSelectionStrings extends SelectionStrings {
  const AppSelectionStrings(this._l10n);

  final AppLocalizations _l10n;

  @override
  String get lassoFreeform => _l10n.editorSelectionLassoFreeform;

  @override
  String get lassoRectangle => _l10n.editorSelectionLassoRectangle;

  @override
  String get lassoSelectable => _l10n.editorSelectionLassoSelectable;

  @override
  String get typeHandwriting => _l10n.editorSelectionTypeHandwriting;

  @override
  String get typeShape => _l10n.editorSelectionTypeShape;

  @override
  String get typeImage => _l10n.editorSelectionTypeImage;

  @override
  String get typeHighlighter => _l10n.editorSelectionTypeHighlighter;

  @override
  String get typeText => _l10n.editorSelectionTypeText;

  @override
  String get typeTape => _l10n.editorSelectionTypeTape;

  @override
  String get typeLink => _l10n.editorSelectionTypeLink;

  @override
  String get typeLabel => _l10n.editorSelectionTypeLabel;

  @override
  String get ai => _l10n.editorSelectionAi;

  @override
  String get color => _l10n.editorSelectionColor;

  @override
  String get screenshot => _l10n.editorSelectionScreenshot;

  @override
  String get cut => _l10n.editorSelectionCut;

  @override
  String get duplicate => _l10n.editorSelectionDuplicate;

  @override
  String get delete => _l10n.editorSelectionDelete;

  @override
  String get bringToFront => _l10n.editorSelectionBringToFront;

  @override
  String get sendToBack => _l10n.editorSelectionSendToBack;

  @override
  String get copy => _l10n.editorSelectionCopy;

  @override
  String get paste => _l10n.editorSelectionPaste;

  @override
  String get askAi => _l10n.editorSelectionAskAi;

  @override
  String get takeScreenshot => _l10n.editorSelectionTakeScreenshot;

  @override
  String get more => _l10n.editorSelectionMore;

  @override
  String get save => _l10n.editorSelectionSave;

  @override
  String get screenshotCaptureFailed =>
      _l10n.editorSelectionScreenshotCaptureFailed;

  @override
  String get screenshotSavedAndCopied =>
      _l10n.editorSelectionScreenshotSavedAndCopied;

  @override
  String get screenshotSaved => _l10n.editorSelectionScreenshotSaved;

  @override
  String get screenshotCopied => _l10n.editorSelectionScreenshotCopied;

  @override
  String get screenshotSaveFailed => _l10n.editorSelectionScreenshotSaveFailed;

  @override
  String get contextEdit => _l10n.editorSelectionContextEdit;

  @override
  String get contextStyle => _l10n.editorSelectionContextStyle;

  @override
  String get contextMove => _l10n.editorSelectionContextMove;
}
