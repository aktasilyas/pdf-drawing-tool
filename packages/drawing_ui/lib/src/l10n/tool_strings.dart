/// User-facing names of the drawing tools.
///
/// Every getter must also be listed in [toMap]; the drift tests rely on it.
abstract class ToolStrings {
  const ToolStrings();

  String get fountainPen;
  String get pencil;
  String get hardPencil;
  String get ballpointPen;
  String get gelPen;
  String get dashedPen;
  String get highlighter;
  String get brushPen;
  String get neonHighlighter;
  String get rulerPen;
  String get pixelEraser;
  String get strokeEraser;
  String get lassoEraser;
  String get shapes;
  String get text;
  String get sticker;
  String get image;
  String get selection;
  String get panZoom;
  String get laserPointer;
  String get stickyNote;
  String get toolbarSettings;

  /// Label of the collapsed pen group in the toolbar settings list.
  String get penGroup;

  /// Every getter by name, for drift tests.
  Map<String, String> toMap() => {
        'fountainPen': fountainPen,
        'pencil': pencil,
        'hardPencil': hardPencil,
        'ballpointPen': ballpointPen,
        'gelPen': gelPen,
        'dashedPen': dashedPen,
        'highlighter': highlighter,
        'brushPen': brushPen,
        'neonHighlighter': neonHighlighter,
        'rulerPen': rulerPen,
        'pixelEraser': pixelEraser,
        'strokeEraser': strokeEraser,
        'lassoEraser': lassoEraser,
        'shapes': shapes,
        'text': text,
        'sticker': sticker,
        'image': image,
        'selection': selection,
        'panZoom': panZoom,
        'laserPointer': laserPointer,
        'stickyNote': stickyNote,
        'toolbarSettings': toolbarSettings,
        'penGroup': penGroup,
      };
}

/// Turkish tool names: the default when no scope is installed.
class ToolStringsTr extends ToolStrings {
  const ToolStringsTr();

  @override
  String get fountainPen => 'Dolma Kalem';
  @override
  String get pencil => 'Kurşun Kalem';
  @override
  String get hardPencil => 'Sert Kalem';
  @override
  String get ballpointPen => 'Tükenmez Kalem';
  @override
  String get gelPen => 'Jel Kalem';
  @override
  String get dashedPen => 'Kesik Çizgi';
  @override
  String get highlighter => 'Fosforlu Kalem';
  @override
  String get brushPen => 'Fırça Kalem';
  @override
  String get neonHighlighter => 'Neon Fosforlu';
  @override
  String get rulerPen => 'Cetvelli Kalem';
  @override
  String get pixelEraser => 'Silgi';
  @override
  String get strokeEraser => 'Çizgi Silgisi';
  @override
  String get lassoEraser => 'Kement Silgisi';
  @override
  String get shapes => 'Şekiller';
  @override
  String get text => 'Metin';
  @override
  String get sticker => 'Çıkartma';
  @override
  String get image => 'Resim';
  @override
  String get selection => 'Seçim';
  @override
  String get panZoom => 'Kaydır/Yakınlaştır';
  @override
  String get laserPointer => 'Lazer İşaretçi';
  @override
  String get stickyNote => 'Yapışkan Not';
  @override
  String get toolbarSettings => 'Araç Çubuğu Ayarları';
  @override
  String get penGroup => 'Kalem';
}
