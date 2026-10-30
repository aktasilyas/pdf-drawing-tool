import 'package:drawing_ui/drawing_ui.dart';
import 'package:example_app/l10n/l10n.dart';

/// [PanelStrings] backed by the generated [AppLocalizations].
class AppPanelStrings extends PanelStrings {
  const AppPanelStrings(this._l10n);

  final AppLocalizations _l10n;

  @override
  String get close => _l10n.editorPanelClose;

  @override
  String get thickness => _l10n.editorPanelThickness;

  @override
  String get pressureSensitivity => _l10n.editorPanelPressureSensitivity;

  @override
  String get stabilization => _l10n.editorPanelStabilization;

  @override
  String get penType => _l10n.editorPanelPenType;

  @override
  String get glow => _l10n.editorPanelGlow;

  @override
  String get straightLine => _l10n.editorPanelStraightLine;

  @override
  String get size => _l10n.editorPanelSize;

  @override
  String get eraserPixel => _l10n.editorPanelEraserPixel;

  @override
  String get eraserPressure => _l10n.editorPanelEraserPressure;

  @override
  String get eraserHighlighterOnly => _l10n.editorPanelEraserHighlighterOnly;

  @override
  String get eraserAutoLift => _l10n.editorPanelEraserAutoLift;

  @override
  String get clearPage => _l10n.editorPanelClearPage;

  @override
  String get clearPageTitle => _l10n.editorPanelClearPageTitle;

  @override
  String get clearPageMessage => _l10n.editorPanelClearPageMessage;

  @override
  String get cancel => _l10n.editorPanelCancel;

  @override
  String get clearPageConfirm => _l10n.editorPanelClearPageConfirm;

  @override
  String get laserDot => _l10n.editorPanelLaserDot;

  @override
  String get laserLine => _l10n.editorPanelLaserLine;

  @override
  String get laserHollow => _l10n.editorPanelLaserHollow;

  @override
  String get laserRainbow => _l10n.editorPanelLaserRainbow;

  @override
  String get laserDuration => _l10n.editorPanelLaserDuration;

  @override
  String get textTitle => _l10n.editorPanelTextTitle;

  @override
  String get textHint => _l10n.editorPanelTextHint;

  @override
  String get textColor => _l10n.editorPanelTextColor;

  @override
  String get textStyle => _l10n.editorPanelTextStyle;

  @override
  String get bold => _l10n.editorPanelTextBold;

  @override
  String get italic => _l10n.editorPanelTextItalic;

  @override
  String get underline => _l10n.editorPanelTextUnderline;

  @override
  String get addNote => _l10n.editorPanelAddNote;

  @override
  String get colorHex => _l10n.editorPanelColorHex;

  @override
  String get colorRed => _l10n.editorPanelColorRed;

  @override
  String get colorGreen => _l10n.editorPanelColorGreen;

  @override
  String get colorBlue => _l10n.editorPanelColorBlue;

  @override
  String get colorCancel => _l10n.editorPanelColorCancel;

  @override
  String get colorDone => _l10n.editorPanelColorDone;

  @override
  String get colorSwatches => _l10n.editorPanelColorSwatches;

  @override
  String get colorSpectrum => _l10n.editorPanelColorSpectrum;
}
