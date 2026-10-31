import 'package:drawing_ui/drawing_ui.dart';
import 'package:example_app/l10n/l10n.dart';

/// [CanvasStrings] backed by the generated [AppLocalizations].
class AppCanvasStrings extends CanvasStrings {
  const AppCanvasStrings(this._l10n);

  final AppLocalizations _l10n;

  @override
  String get addLayer => _l10n.editorCanvasAddLayer;

  @override
  String defaultLayerName(int number) =>
      _l10n.editorCanvasDefaultLayerName(number);

  @override
  String get deleteLayer => _l10n.editorCanvasDeleteLayer;

  @override
  String get duplicateLayer => _l10n.editorCanvasDuplicateLayer;

  @override
  String get hideLayer => _l10n.editorCanvasHideLayer;

  @override
  String get showLayer => _l10n.editorCanvasShowLayer;

  @override
  String get lockLayer => _l10n.editorCanvasLockLayer;

  @override
  String get unlockLayer => _l10n.editorCanvasUnlockLayer;

  @override
  String get renameLayer => _l10n.editorCanvasRenameLayer;

  @override
  String get zoomLock => _l10n.editorCanvasZoomLock;

  @override
  String zoomLevel(int percent) => _l10n.editorCanvasZoomLevel(percent);

  @override
  String get favoriteZoom => _l10n.editorCanvasFavoriteZoom;

  @override
  String penBox(int count) => _l10n.editorCanvasPenBox(count);

  @override
  String get finishEditing => _l10n.editorCanvasFinishEditing;

  @override
  String get editPenBox => _l10n.editorCanvasEditPenBox;

  @override
  String get collapsePenBox => _l10n.editorCanvasCollapsePenBox;

  @override
  String get removePen => _l10n.editorCanvasRemovePen;

  @override
  String get addImage => _l10n.editorCanvasAddImage;

  @override
  String get addImageHint => _l10n.editorCanvasAddImageHint;

  @override
  String get fromGallery => _l10n.editorCanvasFromGallery;

  @override
  String get fromGalleryHint => _l10n.editorCanvasFromGalleryHint;

  @override
  String get takePhoto => _l10n.editorCanvasTakePhoto;

  @override
  String get takePhotoHint => _l10n.editorCanvasTakePhotoHint;

  @override
  String get tapToPlace => _l10n.editorCanvasTapToPlace;

  @override
  String get tapToPlaceImage => _l10n.editorCanvasTapToPlaceImage;

  @override
  String get addColor => _l10n.editorCanvasAddColor;

  @override
  String get textStyleTitle => _l10n.editorCanvasTextStyleTitle;

  @override
  String get emojiSize => _l10n.editorCanvasEmojiSize;

  @override
  String get textPreviewSample => _l10n.editorCanvasTextPreviewSample;

  @override
  String get stickyNoteColorYellow => _l10n.editorCanvasStickyNoteColorYellow;

  @override
  String get stickyNoteColorPink => _l10n.editorCanvasStickyNoteColorPink;

  @override
  String get stickyNoteColorBlue => _l10n.editorCanvasStickyNoteColorBlue;

  @override
  String get stickyNoteColorGreen => _l10n.editorCanvasStickyNoteColorGreen;

  @override
  String get stickyNoteColorOrange => _l10n.editorCanvasStickyNoteColorOrange;

  @override
  String get stickyNoteColorPurple => _l10n.editorCanvasStickyNoteColorPurple;
}
