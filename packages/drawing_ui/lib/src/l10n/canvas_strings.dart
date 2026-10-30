/// User-facing copy of layers, zoom bar, pen box, image panel and canvas hints.
///
/// Every getter and method must also be listed in [toMap]; the drift tests
/// rely on it. Parameterized strings are called with a fixed sample there.
abstract class CanvasStrings {
  const CanvasStrings();

  String get addLayer;
  String defaultLayerName(int number);
  String get deleteLayer;
  String get duplicateLayer;
  String get hideLayer;
  String get showLayer;
  String get lockLayer;
  String get unlockLayer;
  String get zoomLock;
  String zoomLevel(int percent);
  String get favoriteZoom;
  String penBox(int count);
  String get finishEditing;
  String get editPenBox;
  String get collapsePenBox;
  String get removePen;
  String get addImage;
  String get addImageHint;
  String get fromGallery;
  String get fromGalleryHint;
  String get takePhoto;
  String get takePhotoHint;
  String get tapToPlace;
  String get tapToPlaceImage;
  String get addColor;
  String get textStyleTitle;
  String get emojiSize;
  String get textPreviewSample;
  String get stickyNoteColorYellow;
  String get stickyNoteColorPink;
  String get stickyNoteColorBlue;
  String get stickyNoteColorGreen;
  String get stickyNoteColorOrange;
  String get stickyNoteColorPurple;

  /// Every getter by name, for drift tests.
  Map<String, String> toMap() => {
        'addLayer': addLayer,
        'defaultLayerName': defaultLayerName(1),
        'deleteLayer': deleteLayer,
        'duplicateLayer': duplicateLayer,
        'hideLayer': hideLayer,
        'showLayer': showLayer,
        'lockLayer': lockLayer,
        'unlockLayer': unlockLayer,
        'zoomLock': zoomLock,
        'zoomLevel': zoomLevel(1),
        'favoriteZoom': favoriteZoom,
        'penBox': penBox(1),
        'finishEditing': finishEditing,
        'editPenBox': editPenBox,
        'collapsePenBox': collapsePenBox,
        'removePen': removePen,
        'addImage': addImage,
        'addImageHint': addImageHint,
        'fromGallery': fromGallery,
        'fromGalleryHint': fromGalleryHint,
        'takePhoto': takePhoto,
        'takePhotoHint': takePhotoHint,
        'tapToPlace': tapToPlace,
        'tapToPlaceImage': tapToPlaceImage,
        'addColor': addColor,
        'textStyleTitle': textStyleTitle,
        'emojiSize': emojiSize,
        'textPreviewSample': textPreviewSample,
        'stickyNoteColorYellow': stickyNoteColorYellow,
        'stickyNoteColorPink': stickyNoteColorPink,
        'stickyNoteColorBlue': stickyNoteColorBlue,
        'stickyNoteColorGreen': stickyNoteColorGreen,
        'stickyNoteColorOrange': stickyNoteColorOrange,
        'stickyNoteColorPurple': stickyNoteColorPurple,
      };
}

/// Turkish copy: the default when no scope is installed.
class CanvasStringsTr extends CanvasStrings {
  const CanvasStringsTr();

  @override
  String get addLayer => 'Katman Ekle';

  @override
  String defaultLayerName(int number) => 'Katman $number';

  @override
  String get deleteLayer => 'Katmanı Sil';

  @override
  String get duplicateLayer => 'Katmanı Kopyala';

  @override
  String get hideLayer => 'Gizle';

  @override
  String get showLayer => 'Göster';

  @override
  String get lockLayer => 'Kilitle';

  @override
  String get unlockLayer => 'Kilidi Aç';

  @override
  String get zoomLock => 'Yakınlaştırma kilidi';

  @override
  String zoomLevel(int percent) => 'Yakınlaştırma $percent%, favori düzeyler';

  @override
  String get favoriteZoom => 'Favori yakınlaştırma';

  @override
  String penBox(int count) => 'Kalem kutusu, $count kalem';

  @override
  String get finishEditing => 'Düzenlemeyi bitir';

  @override
  String get editPenBox => 'Kalem kutusunu düzenle';

  @override
  String get collapsePenBox => 'Kalem kutusunu daralt';

  @override
  String get removePen => 'Kalemi kaldır';

  @override
  String get addImage => 'Resim Ekle';

  @override
  String get addImageHint => 'Galeriden veya kamerayla resim ekleyin';

  @override
  String get fromGallery => 'Galeriden Seç';

  @override
  String get fromGalleryHint => 'Albümden bir resim seçin';

  @override
  String get takePhoto => 'Fotoğraf Çek';

  @override
  String get takePhotoHint => 'Kamera ile yeni fotoğraf çekin';

  @override
  String get tapToPlace => 'Yerleştirmek için dokunun';

  @override
  String get tapToPlaceImage => 'Resmi yerleştirmek için dokunun';

  @override
  String get addColor => 'Renk ekle';

  @override
  String get textStyleTitle => 'Metin Stili';

  @override
  String get emojiSize => 'Emoji Boyutu';

  @override
  String get textPreviewSample => 'Merhaba';

  @override
  String get stickyNoteColorYellow => 'Sarı';

  @override
  String get stickyNoteColorPink => 'Pembe';

  @override
  String get stickyNoteColorBlue => 'Mavi';

  @override
  String get stickyNoteColorGreen => 'Yeşil';

  @override
  String get stickyNoteColorOrange => 'Turuncu';

  @override
  String get stickyNoteColorPurple => 'Mor';
}
