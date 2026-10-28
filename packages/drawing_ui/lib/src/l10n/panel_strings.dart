/// User-facing copy of the tool settings panels (pen, highlighter, eraser,
/// laser, text, sticky note) and the color picker.
///
/// Every getter must also be listed in [toMap]; the drift tests rely on it.
abstract class PanelStrings {
  const PanelStrings();

  /// Close button of a panel header.
  String get close;

  /// Thickness slider label.
  String get thickness;

  /// Pen pressure toggle.
  String get pressureSensitivity;

  /// Stroke smoothing slider.
  String get stabilization;

  /// Pen type picker label.
  String get penType;

  /// Neon highlighter glow slider.
  String get glow;

  /// Highlighter straight-line toggle.
  String get straightLine;

  /// Eraser size slider.
  String get size;

  /// Pixel eraser section title.
  String get eraserPixel;

  /// Eraser pressure toggle.
  String get eraserPressure;

  /// Eraser highlighter-only toggle.
  String get eraserHighlighterOnly;

  /// Eraser auto-lift toggle.
  String get eraserAutoLift;

  /// Clear page button.
  String get clearPage;

  /// Clear page dialog title.
  String get clearPageTitle;

  /// Clear page dialog body.
  String get clearPageMessage;

  /// Dialog cancel button.
  String get cancel;

  /// Clear page dialog confirm button.
  String get clearPageConfirm;

  /// Laser pointer mode.
  String get laserDot;

  /// Laser pointer mode.
  String get laserLine;

  /// Laser pointer mode.
  String get laserHollow;

  /// Laser pointer mode.
  String get laserRainbow;

  /// Laser trail duration slider.
  String get laserDuration;

  /// Text settings panel title.
  String get textTitle;

  /// Text settings panel hint.
  String get textHint;

  /// Text color label.
  String get textColor;

  /// Text style label.
  String get textStyle;

  /// Sticky note add button.
  String get addNote;

  /// Color picker hex tab.
  String get colorHex;

  /// Color picker red channel.
  String get colorRed;

  /// Color picker green channel.
  String get colorGreen;

  /// Color picker blue channel.
  String get colorBlue;

  /// Color picker cancel.
  String get colorCancel;

  /// Color picker done.
  String get colorDone;

  /// Color picker swatches tab.
  String get colorSwatches;

  /// Color picker spectrum tab.
  String get colorSpectrum;

  /// Every getter by name, for drift tests.
  Map<String, String> toMap() => {
        'close': close,
        'thickness': thickness,
        'pressureSensitivity': pressureSensitivity,
        'stabilization': stabilization,
        'penType': penType,
        'glow': glow,
        'straightLine': straightLine,
        'size': size,
        'eraserPixel': eraserPixel,
        'eraserPressure': eraserPressure,
        'eraserHighlighterOnly': eraserHighlighterOnly,
        'eraserAutoLift': eraserAutoLift,
        'clearPage': clearPage,
        'clearPageTitle': clearPageTitle,
        'clearPageMessage': clearPageMessage,
        'cancel': cancel,
        'clearPageConfirm': clearPageConfirm,
        'laserDot': laserDot,
        'laserLine': laserLine,
        'laserHollow': laserHollow,
        'laserRainbow': laserRainbow,
        'laserDuration': laserDuration,
        'textTitle': textTitle,
        'textHint': textHint,
        'textColor': textColor,
        'textStyle': textStyle,
        'addNote': addNote,
        'colorHex': colorHex,
        'colorRed': colorRed,
        'colorGreen': colorGreen,
        'colorBlue': colorBlue,
        'colorCancel': colorCancel,
        'colorDone': colorDone,
        'colorSwatches': colorSwatches,
        'colorSpectrum': colorSpectrum,
      };
}

/// Turkish copy: the default when no scope is installed.
class PanelStringsTr extends PanelStrings {
  const PanelStringsTr();

  @override
  String get close => 'Kapat';

  @override
  String get thickness => 'Kalınlık';

  @override
  String get pressureSensitivity => 'Basınç Duyarlılığı';

  @override
  String get stabilization => 'Çizgi Stabilizasyonu';

  @override
  String get penType => 'Kalem türü';

  @override
  String get glow => 'Parlaklık';

  @override
  String get straightLine => 'Düz çizgi';

  @override
  String get size => 'Boyut';

  @override
  String get eraserPixel => 'Piksel Silgi';

  @override
  String get eraserPressure => 'Basınç hassasiyeti';

  @override
  String get eraserHighlighterOnly => 'Sadece vurgulayıcı sil';

  @override
  String get eraserAutoLift => 'Otomatik kaldır';

  @override
  String get clearPage => 'Sayfayı Temizle';

  @override
  String get clearPageTitle => 'Sayfayı Temizle?';

  @override
  String get clearPageMessage =>
      'Bu sayfa içeriğini tamamen silecek. Bu işlem geri alınamaz.';

  @override
  String get cancel => 'İptal';

  @override
  String get clearPageConfirm => 'Temizle';

  @override
  String get laserDot => 'Lazer Nokta';

  @override
  String get laserLine => 'Lazer Çizgi';

  @override
  String get laserHollow => 'Lazer Çizgi (Boş)';

  @override
  String get laserRainbow => 'Lazer Gökkuşağı';

  @override
  String get laserDuration => 'Süre';

  @override
  String get textTitle => 'Metin Aracı';

  @override
  String get textHint => 'Tuvale dokunarak metin kutusu ekleyin.';

  @override
  String get textColor => 'Renk';

  @override
  String get textStyle => 'Stil';

  @override
  String get addNote => 'Not Ekle';

  @override
  String get colorHex => 'Altıgen';

  @override
  String get colorRed => 'Kırmızı';

  @override
  String get colorGreen => 'Yeşil';

  @override
  String get colorBlue => 'Mavi';

  @override
  String get colorCancel => 'İptal et';

  @override
  String get colorDone => 'Bitti';

  @override
  String get colorSwatches => 'Kartelalar';

  @override
  String get colorSpectrum => 'Spektrum';
}
