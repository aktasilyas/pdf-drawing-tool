import 'package:drawing_ui/drawing_ui.dart';
import 'package:example_app/l10n/l10n.dart';

/// [ToolStrings] backed by the generated [AppLocalizations].
class AppToolStrings extends ToolStrings {
  const AppToolStrings(this._l10n);

  final AppLocalizations _l10n;

  @override
  String get fountainPen => _l10n.editorToolFountainPen;

  @override
  String get pencil => _l10n.editorToolPencil;

  @override
  String get hardPencil => _l10n.editorToolHardPencil;

  @override
  String get ballpointPen => _l10n.editorToolBallpointPen;

  @override
  String get gelPen => _l10n.editorToolGelPen;

  @override
  String get dashedPen => _l10n.editorToolDashedPen;

  @override
  String get highlighter => _l10n.editorToolHighlighter;

  @override
  String get brushPen => _l10n.editorToolBrushPen;

  @override
  String get neonHighlighter => _l10n.editorToolNeonHighlighter;

  @override
  String get rulerPen => _l10n.editorToolRulerPen;

  @override
  String get pixelEraser => _l10n.editorToolPixelEraser;

  @override
  String get strokeEraser => _l10n.editorToolStrokeEraser;

  @override
  String get lassoEraser => _l10n.editorToolLassoEraser;

  @override
  String get shapes => _l10n.editorToolShapes;

  @override
  String get text => _l10n.editorToolText;

  @override
  String get sticker => _l10n.editorToolSticker;

  @override
  String get image => _l10n.editorToolImage;

  @override
  String get selection => _l10n.editorToolSelection;

  @override
  String get panZoom => _l10n.editorToolPanZoom;

  @override
  String get laserPointer => _l10n.editorToolLaserPointer;

  @override
  String get stickyNote => _l10n.editorToolStickyNote;

  @override
  String get toolbarSettings => _l10n.editorToolToolbarSettings;

  @override
  String get penGroup => _l10n.editorToolPenGroup;
}
