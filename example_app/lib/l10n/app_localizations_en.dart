// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonClose => 'Close';

  @override
  String get commonBack => 'Back';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonDone => 'Done';

  @override
  String get commonOk => 'OK';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonRename => 'Rename';

  @override
  String get commonMove => 'Move';

  @override
  String get commonDuplicate => 'Duplicate';

  @override
  String get commonRestore => 'Restore';

  @override
  String get commonMenu => 'Menu';

  @override
  String commonErrorDetail(String error) {
    return 'Error: $error';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionAppearance => 'APPEARANCE';

  @override
  String get settingsSectionAccount => 'ACCOUNT';

  @override
  String get settingsSectionPrivacy => 'PRIVACY';

  @override
  String get settingsSectionAbout => 'ABOUT';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeDialogTitle => 'Choose theme';

  @override
  String get settingsCanvasTheme => 'Canvas theme';

  @override
  String get settingsPinFavorites => 'Pin favorites to top';

  @override
  String get settingsChangePassword => 'Change password';

  @override
  String get settingsChangePasswordSoon =>
      'Changing the password is coming soon';

  @override
  String get settingsAccountInfo => 'Account info';

  @override
  String get settingsAccountInfoTitle => 'Account Info';

  @override
  String settingsAccountEmail(String email) {
    return 'Email: $email';
  }

  @override
  String settingsAccountId(String id) {
    return 'ID: $id';
  }

  @override
  String get settingsUserFallbackName => 'User';

  @override
  String get settingsEditName => 'Edit Name';

  @override
  String get settingsEditNameHint => 'Edit name';

  @override
  String get settingsNameLabel => 'Your name';

  @override
  String get settingsLogout => 'Log Out';

  @override
  String get settingsLogoutConfirm =>
      'Are you sure you want to log out of your account?';

  @override
  String get settingsCrashReports => 'Send crash reports';

  @override
  String get settingsCrashReportsSubtitle =>
      'Anonymous error reports; note content is never sent';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get settingsPrivacyPolicyLoadError =>
      'Could not open the privacy policy';

  @override
  String get settingsLicenses => 'Open source licenses';

  @override
  String get settingsFeedback => 'Send feedback';

  @override
  String get settingsCopy => 'Copy';

  @override
  String get settingsEmailCopied => 'Email address copied';

  @override
  String get libraryErrorCreateDocument => 'Couldn\'t create the notebook';

  @override
  String get libraryErrorImportDocument => 'Couldn\'t import the document';

  @override
  String get libraryErrorMoveDocument => 'Couldn\'t move the notebook';

  @override
  String get libraryErrorToggleFavorite => 'Couldn\'t update favorites';

  @override
  String get libraryErrorTrashDocument =>
      'Couldn\'t move the notebook to the trash';

  @override
  String get libraryErrorDeleteDocument => 'Couldn\'t delete the notebook';

  @override
  String get libraryErrorRenameDocument => 'Couldn\'t rename the notebook';

  @override
  String get libraryErrorRestoreDocument => 'Couldn\'t restore the notebook';

  @override
  String get libraryErrorDuplicateDocument =>
      'Couldn\'t duplicate the notebook';

  @override
  String get libraryErrorDeleteDocumentForever =>
      'Couldn\'t delete the notebook permanently';

  @override
  String get libraryErrorTrashDocuments =>
      'Couldn\'t move the notebooks to the trash';

  @override
  String get libraryErrorDeleteDocumentsForever =>
      'Couldn\'t delete the notebooks permanently';

  @override
  String get libraryErrorDuplicateDocuments =>
      'Couldn\'t duplicate the notebooks';

  @override
  String get libraryErrorMoveDocuments => 'Couldn\'t move the notebooks';

  @override
  String libraryErrorBulkPartial(String message, int failed, int total) {
    return '$message ($failed of $total failed)';
  }

  @override
  String get libraryErrorTrashPage => 'Couldn\'t move the page to the trash';

  @override
  String get libraryErrorDeletePageForever =>
      'Couldn\'t delete the page permanently';

  @override
  String get libraryErrorEmptyTrash => 'Couldn\'t empty the trash';

  @override
  String get libraryErrorCreateFolder => 'Couldn\'t create the folder';

  @override
  String get libraryErrorRenameFolder => 'Couldn\'t rename the folder';

  @override
  String get libraryErrorRecolorFolder => 'Couldn\'t change the folder color';

  @override
  String get libraryErrorSaveFolderOrder => 'Couldn\'t save the order';

  @override
  String get libraryErrorMoveFolder => 'Couldn\'t move the folder';

  @override
  String get libraryErrorDeleteFolder => 'Couldn\'t delete the folder';

  @override
  String get libraryRuleFolderDepth => 'Folders can only be one level deep';

  @override
  String get libraryRuleFolderIntoOwnSubfolder =>
      'A folder can\'t be moved into its own subfolder';

  @override
  String get libraryRuleFolderMoveDepth =>
      'A folder can\'t be moved into a subfolder';

  @override
  String get libraryRuleFolderWithSubfoldersMove =>
      'A folder with subfolders can\'t be moved into another folder';

  @override
  String get libraryRuleDocumentLimit =>
      'You\'ve reached the free limit. Upgrade to Premium.';

  @override
  String get libraryRuleFolderLimit =>
      'You\'ve reached the folder limit. Upgrade to Premium.';

  @override
  String get librarySortByDate => 'By date';

  @override
  String get librarySortByName => 'By name';

  @override
  String get librarySortBySize => 'By size';

  @override
  String get librarySectionAll => 'All notes';

  @override
  String get librarySectionFavorites => 'Favorites';

  @override
  String get librarySectionTrash => 'Recently deleted';

  @override
  String get libraryFolderFallback => 'Folder';

  @override
  String get libraryPaperSquare => 'Square';

  @override
  String get libraryPaperWide => 'Widescreen';

  @override
  String get libraryPaperCustom => 'Custom';

  @override
  String get libraryBreadcrumbRoot => 'Library';

  @override
  String get libraryFolders => 'Folders';

  @override
  String get libraryDocuments => 'Documents';

  @override
  String get libraryManage => 'Manage';

  @override
  String get libraryNewFolder => 'New folder';

  @override
  String get libraryNoFolders => 'No folders';

  @override
  String get librarySidebarCollapse => 'Collapse';

  @override
  String get libraryOpenSidebar => 'Open sidebar';

  @override
  String get librarySearchHint => 'Search...';

  @override
  String get libraryListView => 'List view';

  @override
  String get libraryGridView => 'Grid view';

  @override
  String get librarySelectMode => 'Select';

  @override
  String get libraryNewDocument => 'New document';

  @override
  String get libraryNewDocumentLocked => 'Document limit reached';

  @override
  String get libraryNew => 'New';

  @override
  String get libraryTrashInfo =>
      'Deleted notes are permanently removed after 30 days';

  @override
  String get libraryEmptyTrash => 'Empty trash';

  @override
  String get libraryEmptyTrashConfirmMessage =>
      'Everything in the trash will be deleted permanently. This can\'t be undone.';

  @override
  String get libraryEmptyTrashConfirm => 'Empty';

  @override
  String get libraryTrashEmptied => 'Trash emptied';

  @override
  String get libraryOpenFailed => 'Couldn\'t open the notebook';

  @override
  String get libraryTrashCountsTowardsLimit =>
      'Notes in the trash count towards the limit. Delete them permanently to free up space, or';

  @override
  String libraryRemainingDocuments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents left',
      one: '1 document left',
    );
    return '$_temp0';
  }

  @override
  String get librarySortTitle => 'Sort';

  @override
  String get librarySortNewestFirst => 'Newest first';

  @override
  String get librarySortOldestFirst => 'Oldest first';

  @override
  String get libraryEmptyTitle => 'No notes yet';

  @override
  String get libraryEmptyMessage => 'Create a notebook or import a PDF.';

  @override
  String get libraryEmptyAction => 'New note';

  @override
  String get libraryEmptyFavoritesTitle => 'No favorite notes';

  @override
  String get libraryEmptyFavoritesMessage =>
      'Tap the star icon to add notes to your favorites';

  @override
  String get libraryEmptyFolderTitle => 'This folder is empty';

  @override
  String get libraryEmptyFolderMessage => 'Move notes here or create a new one';

  @override
  String get libraryTrashEmptyTitle => 'Trash is empty';

  @override
  String get libraryTrashEmptyMessage => 'Deleted notes will appear here';

  @override
  String get libraryNoResultsTitle => 'No results';

  @override
  String libraryNoResultsMessage(String query) {
    return 'No notes match \"$query\"';
  }

  @override
  String get libraryClearSearch => 'Clear search';

  @override
  String librarySelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get librarySelectAll => 'All';

  @override
  String get libraryDeleteForever => 'Delete permanently';

  @override
  String get libraryDeleteForeverTitle => 'Delete permanently?';

  @override
  String get libraryDeleteDocumentsTitle => 'Delete notes';

  @override
  String get libraryDocumentLimitReached => 'Document limit reached';

  @override
  String libraryDocumentsCopied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents duplicated',
      one: '1 document duplicated',
    );
    return '$_temp0';
  }

  @override
  String libraryDocumentsTrashed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents moved to the trash',
      one: '1 document moved to the trash',
    );
    return '$_temp0';
  }

  @override
  String libraryDocumentsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents deleted',
      one: '1 document deleted',
    );
    return '$_temp0';
  }

  @override
  String libraryDeleteDocumentsForeverMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count documents will be deleted permanently. This can\'t be undone.',
      one: '1 document will be deleted permanently. This can\'t be undone.',
    );
    return '$_temp0';
  }

  @override
  String libraryTrashDocumentsMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents will be moved to the trash.',
      one: '1 document will be moved to the trash.',
    );
    return '$_temp0';
  }

  @override
  String libraryPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String libraryDocumentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents',
      one: '1 document',
    );
    return '$_temp0';
  }

  @override
  String libraryDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get libraryRemoveFavoriteBadge => 'Remove from favorites';

  @override
  String get libraryRemoveFromFavorites => 'Remove from favorites';

  @override
  String get libraryAddToFavorites => 'Add to favorites';

  @override
  String get libraryMoveToTrash => 'Move to trash';

  @override
  String get libraryDocumentDuplicated => 'Notebook duplicated';

  @override
  String get libraryDocumentMoved => 'Notebook moved';

  @override
  String get libraryDocumentRestored => 'Notebook restored';

  @override
  String get libraryDeleteDocumentForeverMessage =>
      'This notebook will be deleted permanently. This can\'t be undone.';

  @override
  String get libraryDocumentNameLabel => 'Notebook name';

  @override
  String get libraryChangeColor => 'Change color';

  @override
  String get libraryFolderMoved => 'Folder moved';

  @override
  String get libraryFolderColorChanged => 'Folder color changed';

  @override
  String get libraryDeleteFolderTitle => 'Delete folder';

  @override
  String libraryDeleteFolderNonEmptyMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'This folder contains $count documents. Deleting it also deletes them. Continue?',
      one:
          'This folder contains 1 document. Deleting the folder also deletes that document. Continue?',
    );
    return '$_temp0';
  }

  @override
  String get libraryDeleteFolderMessage => 'Delete this folder?';

  @override
  String get libraryFolderDeleted => 'Folder deleted';

  @override
  String get libraryRenameFolderTitle => 'Rename folder';

  @override
  String get libraryFolderNameLabel => 'Folder name';

  @override
  String libraryFolderRenamed(String name) {
    return 'Folder renamed to \"$name\"';
  }

  @override
  String libraryPageNumber(int page) {
    return 'Page $page';
  }

  @override
  String libraryTrashedPageTitle(String document, int page) {
    return '$document — Page $page';
  }

  @override
  String get librarySourceDocumentMissing =>
      'The original notebook no longer exists';

  @override
  String get libraryPageRestored => 'Page restored';

  @override
  String get libraryPageRestoreFailed => 'Couldn\'t restore the page';

  @override
  String get libraryDeletePageForeverMessage =>
      'This page will be deleted permanently. This can\'t be undone.';

  @override
  String libraryCopyTitle(String title) {
    return '$title (copy)';
  }

  @override
  String get editorToolFountainPen => 'Fountain pen';

  @override
  String get editorToolPencil => 'Pencil';

  @override
  String get editorToolHardPencil => 'Hard pencil';

  @override
  String get editorToolBallpointPen => 'Ballpoint pen';

  @override
  String get editorToolGelPen => 'Gel pen';

  @override
  String get editorToolDashedPen => 'Dashed pen';

  @override
  String get editorToolHighlighter => 'Highlighter';

  @override
  String get editorToolBrushPen => 'Brush pen';

  @override
  String get editorToolNeonHighlighter => 'Neon highlighter';

  @override
  String get editorToolRulerPen => 'Ruler pen';

  @override
  String get editorToolPixelEraser => 'Eraser';

  @override
  String get editorToolStrokeEraser => 'Stroke eraser';

  @override
  String get editorToolLassoEraser => 'Lasso eraser';

  @override
  String get editorToolShapes => 'Shapes';

  @override
  String get editorToolText => 'Text';

  @override
  String get editorToolSticker => 'Sticker';

  @override
  String get editorToolImage => 'Image';

  @override
  String get editorToolSelection => 'Select';

  @override
  String get editorToolPanZoom => 'Pan & zoom';

  @override
  String get editorToolLaserPointer => 'Laser pointer';

  @override
  String get editorToolStickyNote => 'Sticky note';

  @override
  String get editorToolToolbarSettings => 'Toolbar settings';

  @override
  String get editorToolPenGroup => 'Pen';

  @override
  String get editorToolbarHome => 'Home';

  @override
  String get editorToolbarPages => 'Pages';

  @override
  String get editorToolbarRuler => 'Ruler';

  @override
  String get editorToolbarAudio => 'Audio recording';

  @override
  String get editorToolbarReaderMode => 'Reader mode';

  @override
  String get editorToolbarEditMode => 'Edit mode';

  @override
  String get editorToolbarMore => 'More';

  @override
  String get editorToolbarLayers => 'Layers';

  @override
  String get editorToolbarAddPage => 'Add page';

  @override
  String get editorToolbarExport => 'Export';

  @override
  String get editorToolbarAi => 'AI assistant';

  @override
  String get editorToolbarUntitled => 'Untitled note';

  @override
  String get editorToolbarMoreColors => 'More colors';

  @override
  String get editorToolbarColorSetHighlighter => 'Highlighter';

  @override
  String get editorToolbarColorSetPastel => 'Pastel';

  @override
  String editorToolbarSelectedColor(String hex) {
    return 'Selected color $hex';
  }

  @override
  String editorToolbarColor(String hex) {
    return 'Color $hex';
  }

  @override
  String editorToolbarThickness(String value) {
    return 'Thickness $value';
  }

  @override
  String get editorToolbarMoreTools => 'More tools';

  @override
  String get editorToolbarReadOnlyActive => 'Read-only mode on';

  @override
  String get editorToolbarReadOnly => 'Read-only';

  @override
  String get editorToolbarUndo => 'Undo';

  @override
  String get editorToolbarRedo => 'Redo';

  @override
  String get editorToolbarRecordingInProgress => 'Recording…';

  @override
  String get editorToolbarRecord => 'Start recording';

  @override
  String get editorToolbarMicPermissionRequired =>
      'Microphone access is required. Please allow it in Settings.';

  @override
  String get editorToolbarShowRecordings => 'Show recordings';

  @override
  String get editorToolbarSettingsTabTools => 'Tools';

  @override
  String get editorToolbarSettingsTabExtraTools => 'Extra tools';

  @override
  String get editorToolbarSettingsToolsHint => 'Reorder and hide tools';

  @override
  String get editorToolbarSettingsExtraToolsHint =>
      'Reorder and hide extra tools';

  @override
  String get editorToolbarSettingsReset => 'Reset to default';

  @override
  String get editorToolbarColorSetBasic => 'Basic';

  @override
  String get editorToolbarColorSetNeon => 'Neon';

  @override
  String get editorPanelClose => 'Close';

  @override
  String get editorPanelThickness => 'Thickness';

  @override
  String get editorPanelPressureSensitivity => 'Pressure sensitivity';

  @override
  String get editorPanelStabilization => 'Stroke stabilization';

  @override
  String get editorPanelPenType => 'Pen type';

  @override
  String get editorPanelGlow => 'Glow';

  @override
  String get editorPanelStraightLine => 'Straight line';

  @override
  String get editorPanelSize => 'Size';

  @override
  String get editorPanelEraserPixel => 'Pixel eraser';

  @override
  String get editorPanelEraserPressure => 'Pressure sensitivity';

  @override
  String get editorPanelEraserHighlighterOnly => 'Erase highlighter only';

  @override
  String get editorPanelEraserAutoLift => 'Auto-deselect';

  @override
  String get editorPanelClearPage => 'Clear page';

  @override
  String get editorPanelClearPageTitle => 'Clear page?';

  @override
  String get editorPanelClearPageMessage =>
      'This erases everything on this page. This can\'t be undone.';

  @override
  String get editorPanelCancel => 'Cancel';

  @override
  String get editorPanelClearPageConfirm => 'Clear';

  @override
  String get editorPanelLaserDot => 'Laser dot';

  @override
  String get editorPanelLaserLine => 'Laser line';

  @override
  String get editorPanelLaserHollow => 'Hollow laser line';

  @override
  String get editorPanelLaserRainbow => 'Rainbow laser';

  @override
  String get editorPanelLaserDuration => 'Duration';

  @override
  String get editorPanelTextTitle => 'Text tool';

  @override
  String get editorPanelTextHint => 'Tap the canvas to add a text box.';

  @override
  String get editorPanelTextColor => 'Color';

  @override
  String get editorPanelTextStyle => 'Style';

  @override
  String get editorPanelAddNote => 'Add note';

  @override
  String get editorPanelColorHex => 'Hex';

  @override
  String get editorPanelColorRed => 'Red';

  @override
  String get editorPanelColorGreen => 'Green';

  @override
  String get editorPanelColorBlue => 'Blue';

  @override
  String get editorPanelColorCancel => 'Cancel';

  @override
  String get editorPanelColorDone => 'Done';

  @override
  String get editorPanelColorSwatches => 'Swatches';

  @override
  String get editorPanelColorSpectrum => 'Spectrum';

  @override
  String get editorCatalogShapesTitle => 'Shape';

  @override
  String get editorCatalogStrokeWidth => 'Stroke width';

  @override
  String get editorCatalogStrokeColor => 'Stroke color';

  @override
  String get editorCatalogFillShape => 'Fill shape';

  @override
  String get editorCatalogFillColor => 'Fill color';

  @override
  String get editorCatalogShapeLine => 'Line';

  @override
  String get editorCatalogShapeArrow => 'Arrow';

  @override
  String get editorCatalogShapeRectangle => 'Rectangle';

  @override
  String get editorCatalogShapeEllipse => 'Ellipse';

  @override
  String get editorCatalogShapeTriangle => 'Triangle';

  @override
  String get editorCatalogShapeDiamond => 'Diamond';

  @override
  String get editorCatalogShapeStar => 'Star';

  @override
  String get editorCatalogShapePentagon => 'Pentagon';

  @override
  String get editorCatalogShapeHexagon => 'Hexagon';

  @override
  String get editorCatalogShapePlus => 'Plus';

  @override
  String get editorCatalogStickersTitle => 'Stickers';

  @override
  String get editorCatalogAddSticker => 'Add sticker';

  @override
  String get editorCatalogStickerEmoji => 'Emoji';

  @override
  String get editorCatalogStickerAnimals => 'Animals';

  @override
  String get editorCatalogStickerFood => 'Food';

  @override
  String get editorCatalogStickerTravel => 'Travel';

  @override
  String get editorCatalogStickerObjects => 'Objects';

  @override
  String get editorCatalogStickerSymbols => 'Symbols';

  @override
  String get editorCatalogStickerHands => 'Hands';

  @override
  String get editorCatalogStickerNature => 'Nature';

  @override
  String get editorSelectionLassoFreeform => 'Freeform';

  @override
  String get editorSelectionLassoRectangle => 'Rectangle';

  @override
  String get editorSelectionLassoSelectable => 'Selectable';

  @override
  String get editorSelectionTypeHandwriting => 'Handwriting';

  @override
  String get editorSelectionTypeShape => 'Shapes';

  @override
  String get editorSelectionTypeImage => 'Images';

  @override
  String get editorSelectionTypeHighlighter => 'Highlighter';

  @override
  String get editorSelectionTypeText => 'Text';

  @override
  String get editorSelectionTypeTape => 'Tape';

  @override
  String get editorSelectionTypeLink => 'Links';

  @override
  String get editorSelectionTypeLabel => 'Labels';

  @override
  String get editorSelectionAi => 'AI assistant';

  @override
  String get editorSelectionColor => 'Color';

  @override
  String get editorSelectionScreenshot => 'Screenshot';

  @override
  String get editorSelectionCut => 'Cut';

  @override
  String get editorSelectionDuplicate => 'Duplicate';

  @override
  String get editorSelectionDelete => 'Delete';

  @override
  String get editorSelectionBringToFront => 'Bring to front';

  @override
  String get editorSelectionSendToBack => 'Send to back';

  @override
  String get editorSelectionCopy => 'Copy';

  @override
  String get editorSelectionPaste => 'Paste';

  @override
  String get editorSelectionAskAi => 'Ask AI';

  @override
  String get editorSelectionTakeScreenshot => 'Take screenshot';

  @override
  String get editorSelectionMore => 'More';

  @override
  String get editorSelectionSave => 'Save';

  @override
  String get editorSelectionScreenshotCaptureFailed =>
      'Couldn\'t create the screenshot';

  @override
  String get editorSelectionScreenshotSavedAndCopied =>
      'Screenshot saved to the gallery and copied to the clipboard';

  @override
  String get editorSelectionScreenshotSaved =>
      'Screenshot saved to the gallery';

  @override
  String get editorSelectionScreenshotCopied =>
      'Screenshot copied to the clipboard';

  @override
  String get editorSelectionScreenshotSaveFailed =>
      'Couldn\'t save the screenshot';

  @override
  String get editorSelectionContextEdit => 'Edit';

  @override
  String get editorSelectionContextStyle => 'Style';

  @override
  String get editorSelectionContextMove => 'Move';

  @override
  String get editorDocumentNameLabel => 'Document name';

  @override
  String get editorMoveToTrashTitle => 'Move to trash';

  @override
  String get editorMoveToTrashMessage =>
      'This document will be moved to the trash. You can restore it later.';

  @override
  String get editorLoadErrorTitle => 'Couldn\'t open the document';

  @override
  String get editorLoadErrorMessage =>
      'The document wasn\'t found or couldn\'t be read.';

  @override
  String get editorLoadErrorBack => 'Go back';

  @override
  String get editorSaveFailedMessage =>
      'Couldn\'t save. Your changes haven\'t been saved yet.';

  @override
  String get startupErrorTitle => 'The app couldn\'t start';

  @override
  String get startupErrorMessage =>
      'Your notes are safe, nothing was deleted. Something went wrong while opening your data. Try again; if the problem persists, close the app and reopen it.';

  @override
  String get commonPasswordLabel => 'Password';

  @override
  String get commonSelectItemTitle => 'Select an item';

  @override
  String get commonSelectItemDescription =>
      'Select an item on the left to see its details';

  @override
  String get commonUnderConstruction =>
      'This screen is still under construction';

  @override
  String get routerForgotPasswordTitle => 'Forgot password';

  @override
  String get routerProfileTitle => 'Profile';

  @override
  String get routerSubscriptionTitle => 'Subscription';

  @override
  String get libraryNewNotebook => 'Notebook';

  @override
  String get libraryNewWhiteboard => 'Whiteboard';

  @override
  String get libraryNewQuickNote => 'Quick note';

  @override
  String get libraryImportPdf => 'Import PDF';

  @override
  String get libraryImportImage => 'Import image';

  @override
  String libraryQuickNoteTitle(String date) {
    return 'Quick note - $date';
  }

  @override
  String libraryWhiteboardTitle(String date) {
    return 'Whiteboard - $date';
  }

  @override
  String get libraryPdfReadFailed => 'Couldn\'t read the PDF file';

  @override
  String get libraryImageReadFailed => 'Couldn\'t read the image file';

  @override
  String get libraryImageLoading => 'Loading image...';

  @override
  String get libraryImageTooLarge =>
      'Image is too large. Maximum size: 4096x4096';

  @override
  String get libraryPdfTooLarge => 'PDF is too large. Maximum size: 200 MB';

  @override
  String get libraryPdfOpening => 'Opening PDF...';

  @override
  String get libraryPdfImportFailed => 'Couldn\'t import the PDF';

  @override
  String libraryOpening(String title) {
    return 'Opening $title';
  }

  @override
  String libraryOpeningWithPages(String title, String pages) {
    return 'Opening $title ($pages)';
  }

  @override
  String get libraryFormat => 'Format';

  @override
  String get libraryOrientation => 'Orientation';

  @override
  String get libraryPortrait => 'Portrait';

  @override
  String get libraryLandscape => 'Landscape';

  @override
  String get librarySize => 'Size';

  @override
  String libraryFormatSummary(String orientation, String size) {
    return '$orientation, $size';
  }

  @override
  String get libraryCover => 'Cover';

  @override
  String get libraryPaper => 'Paper';

  @override
  String get libraryTitle => 'Title';

  @override
  String get libraryNoteTitleHint => 'Note title';

  @override
  String get libraryTemplateCategoryAll => 'All';

  @override
  String get libraryNoTemplatesInCategory => 'No templates in this category';

  @override
  String get libraryCreateNoteTitle => 'Create new note';

  @override
  String get libraryTemplate => 'Template';

  @override
  String get libraryUntitledNote => 'Untitled note';

  @override
  String get libraryPaperColorWhite => 'White paper';

  @override
  String get libraryPaperColorBlack => 'Black paper';

  @override
  String get libraryPaperColorCream => 'Cream paper';

  @override
  String get libraryPaperColorGray => 'Gray paper';

  @override
  String get libraryPaperColorGreen => 'Green paper';

  @override
  String get libraryPaperColorBlue => 'Blue paper';

  @override
  String get libraryPaperColorYellow => 'Yellow paper';

  @override
  String get librarySelectColor => 'Choose a color';

  @override
  String get editorPageRename => 'Rename';

  @override
  String get editorPageMoveDocumentToTrash => 'Move to trash';

  @override
  String get editorPageDocumentOptions => 'Document options';

  @override
  String editorPagePageNumber(int number) {
    return 'Page $number';
  }

  @override
  String get editorPageBookmarkPage => 'Bookmark page';

  @override
  String get editorPageRemoveBookmark => 'Remove bookmark';

  @override
  String get editorPageCopyPage => 'Copy page';

  @override
  String get editorPagePastePage => 'Paste page';

  @override
  String get editorPageDuplicatePage => 'Duplicate page';

  @override
  String get editorPageChangeTemplate => 'Change template';

  @override
  String get editorPageGoToPageMenu => 'Go to page';

  @override
  String get editorPageExportPagePdf => 'Export page as PDF';

  @override
  String get editorPageClearPageMenu => 'Clear page';

  @override
  String get editorPageMovePageToTrash => 'Move to trash';

  @override
  String get editorPageSettings => 'Settings';

  @override
  String get editorPageEditToolbar => 'Edit toolbar';

  @override
  String get editorPageScrollDirection => 'Scroll direction';

  @override
  String get editorPageScrollHorizontal => 'Horizontal';

  @override
  String get editorPageScrollVertical => 'Vertical';

  @override
  String get editorPagePageCopied => 'Page copied';

  @override
  String get editorPagePagePasted => 'Page pasted';

  @override
  String get editorPagePasteFilesMissing =>
      'Can\'t paste: the copied files no longer exist';

  @override
  String get editorPagePageDuplicated => 'Page duplicated';

  @override
  String get editorPageLastPageCannotDelete =>
      'The last page can\'t be deleted';

  @override
  String get editorPagePageDeleted => 'Page deleted';

  @override
  String editorPageClearPageQuestion(int page) {
    return 'Clear page $page?\nYou can undo this.';
  }

  @override
  String get editorPagePageAdded => 'Page added';

  @override
  String get editorPageCannotUndo => 'Can\'t undo';

  @override
  String get editorPagePageMoved => 'Page moved';

  @override
  String get editorPageBackgroundReplaced => 'Page background replaced';

  @override
  String get editorPageGoToPage => 'Go to page';

  @override
  String get editorPageGo => 'Go';

  @override
  String editorPageListPageOf(int page, int count) {
    return 'Page $page of $count';
  }

  @override
  String editorPageListPageRangeOf(int first, int last, int count) {
    return 'Pages $first–$last of $count';
  }

  @override
  String get editorPageListPreviousPage => 'Previous page';

  @override
  String get editorPageListNextPage => 'Next page';

  @override
  String editorPageListGoToPageHint(String pageLabel) {
    return '$pageLabel, tap to go to a page';
  }

  @override
  String get editorPageListAddPage => 'Add page';

  @override
  String get editorPageListAddBookmark => 'Add bookmark';

  @override
  String get editorPageListNoBookmarks => 'No bookmarks yet';

  @override
  String get editorPageListNoBookmarksHint =>
      'Tap the bookmark icon on a thumbnail to bookmark that page.';

  @override
  String get editorPageListFilterAllPages => 'All pages';

  @override
  String get editorPageListFilterBookmarks => 'Bookmarks';

  @override
  String get editorPageListFilterRecordings => 'Recordings';

  @override
  String get editorPageListPageOptions => 'Page options';

  @override
  String get editorPageListThumbnailFailed => 'Preview\nunavailable';

  @override
  String get editorPageListDropToAddPage => 'Drag and drop\nto add a new page';

  @override
  String get editorPageListPositionBefore => 'Before';

  @override
  String get editorPageListPositionAfter => 'After';

  @override
  String get editorPageListLastPage => 'Last page';

  @override
  String get editorPageListMoreTemplates => 'More templates';

  @override
  String get editorPageListTakePhoto => 'Take photo';

  @override
  String get editorPageListImportFile => 'Import';

  @override
  String get editorExportScopeAll => 'All';

  @override
  String get editorExportScopeCurrent => 'This page';

  @override
  String get editorExportScopeRange => 'Range';

  @override
  String get editorExportFrom => 'From';

  @override
  String get editorExportTo => 'To';

  @override
  String get editorExportIncludeTemplate => 'Include page template';

  @override
  String get editorExportExportPng => 'Export as PNG';

  @override
  String get editorExportExportPdf => 'Export as PDF';

  @override
  String get editorExportSharePdf => 'Share PDF';

  @override
  String editorExportInvalidRange(int count) {
    return 'The page range must be between 1 and $count.';
  }

  @override
  String get editorExportSavePdfDialog => 'Save PDF';

  @override
  String get editorExportSavePngDialog => 'Save PNG';

  @override
  String get editorExportFallbackFileName => 'document';

  @override
  String editorExportPageFileName(String title, int page) {
    return '${title}_page$page';
  }

  @override
  String get editorExportExporting => 'Exporting PDF…';

  @override
  String editorExportPercent(int percent) {
    return '$percent%';
  }

  @override
  String editorExportRemainingSeconds(int seconds) {
    return '~$seconds s';
  }

  @override
  String editorExportRemainingMinutes(int minutes) {
    return '~$minutes min';
  }

  @override
  String get editorExportSaved => 'PDF saved';

  @override
  String editorExportSavedWithSize(String size) {
    return 'PDF saved ($size)';
  }

  @override
  String get editorExportCancelled => 'Cancelled';

  @override
  String editorExportPagesWithoutPdfBackground(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages were exported without their PDF background',
      one: '1 page was exported without its PDF background',
    );
    return '$_temp0';
  }

  @override
  String editorExportPagesWithoutImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Some images on $count pages could not be read and were left out',
      one: 'Some images on 1 page could not be read and were left out',
    );
    return '$_temp0';
  }

  @override
  String get editorTemplateAllCategories => 'All';

  @override
  String get editorTemplateCoverTab => 'Cover';

  @override
  String get editorTemplatePaperTab => 'Paper';

  @override
  String get editorTemplateApply => 'Apply';

  @override
  String get editorTemplatePortrait => 'Portrait';

  @override
  String get editorTemplateLandscape => 'Landscape';

  @override
  String get editorTemplatePaperSquare => 'Square';

  @override
  String get editorTemplatePaperWidescreen => 'Widescreen (16:9)';

  @override
  String get editorTemplateCustom => 'Custom';

  @override
  String get editorTemplateColorWhite => 'White';

  @override
  String get editorTemplateColorCream => 'Cream';

  @override
  String get editorTemplateColorBlack => 'Black';

  @override
  String get editorTemplateColorYellow => 'Yellow';

  @override
  String get editorTemplateTemplatesHeader => 'Templates';

  @override
  String get editorTemplateBackground => 'Background';

  @override
  String get editorTemplateBackgroundPattern => 'Background pattern';

  @override
  String get editorTemplatePatternPlain => 'Plain';

  @override
  String get editorTemplatePatternDotted => 'Dotted';

  @override
  String get editorTemplatePatternGrid => 'Grid';

  @override
  String get editorTemplateBackgroundColor => 'Background color';

  @override
  String get editorCoverSolidNavy => 'Navy';

  @override
  String get editorCoverSolidBurgundy => 'Burgundy';

  @override
  String get editorCoverMinimalGray => 'Gray Frame';

  @override
  String get editorCoverPatternDots => 'Dotted';

  @override
  String get editorCoverPatternLines => 'Lined';

  @override
  String get editorCoverGradientSunset => 'Sunset';

  @override
  String get editorCoverGradientOcean => 'Ocean';

  @override
  String get editorCoverGradientForest => 'Forest';

  @override
  String get editorCoverGradientPurple => 'Lavender';

  @override
  String get editorCoverImgKraft => 'Kraft';

  @override
  String get editorCoverImgGeometric => 'Geometric';

  @override
  String get editorCoverImgTerrazzo => 'Terrazzo';

  @override
  String get editorCoverImgDinosaur => 'Dinosaur';

  @override
  String get editorCoverImgSpace => 'Space';

  @override
  String get editorCoverImgFloral => 'Floral';

  @override
  String get editorCoverImgNavyGold => 'Navy Gold';

  @override
  String get editorCoverImgLeather => 'Leather';

  @override
  String get editorCoverLinenSage => 'Sage Linen';

  @override
  String get editorCoverLinenSand => 'Sand Linen';

  @override
  String get editorCoverLinenSlate => 'Slate Linen';

  @override
  String get editorCoverLeatherOxblood => 'Oxblood Leather';

  @override
  String get editorCoverLeatherCognac => 'Cognac Leather';

  @override
  String get editorCoverLeatherNavy => 'Navy Leather';

  @override
  String get editorCoverKraftNatural => 'Natural Kraft';

  @override
  String get editorCoverKraftCharcoal => 'Charcoal Kraft';

  @override
  String get editorCoverFeltMustard => 'Mustard Felt';

  @override
  String get editorCoverFeltDustyRose => 'Dusty Rose Felt';

  @override
  String get editorErrorExportStorageFull =>
      'Not enough storage to export. Free up space and try again.';

  @override
  String get editorErrorExportCannotWrite =>
      'Couldn\'t write the file. Try again.';

  @override
  String get editorErrorExportFailed => 'Export failed. Try again.';

  @override
  String get editorErrorExportNoPages => 'There are no pages to export';

  @override
  String get editorErrorPdfPasswordProtected =>
      'This PDF is password-protected. Remove the password and try again.';

  @override
  String get editorErrorPdfFileAccess => 'Couldn\'t access the PDF file.';

  @override
  String get editorErrorPdfStorageFull =>
      'Not enough storage to import the PDF. Free up space and try again.';

  @override
  String get editorErrorPdfOpenFailed =>
      'Couldn\'t open the PDF. The file may be damaged.';

  @override
  String get editorErrorPdfPagesUnreadable =>
      'Couldn\'t read the PDF pages. The file may be damaged.';

  @override
  String editorErrorPdfTooManyPages(int count, int max) {
    return 'This PDF has too many pages ($count). Up to $max pages are supported.';
  }

  @override
  String get editorErrorPdfPagePlaceholder => 'PDF page';

  @override
  String get editorErrorPdfSourceMissing => 'Source PDF not found';

  @override
  String get editorErrorPdfLocateSource => 'Locate PDF…';

  @override
  String get editorPdfRelinkDone => 'PDF re-linked';

  @override
  String editorPdfRelinkPageCountMismatch(int found, int required) {
    return 'This PDF has $found pages; the notebook needs $required.';
  }

  @override
  String get editorPdfRelinkFailed => 'Couldn\'t re-link the PDF';

  @override
  String get editorErrorPdfLoadFailed => 'Couldn\'t load PDF';

  @override
  String editorErrorPdfPagesSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages could not be read and were skipped',
      one: '1 page could not be read and was skipped',
    );
    return '$_temp0';
  }

  @override
  String get editorCanvasAddLayer => 'Add layer';

  @override
  String editorCanvasDefaultLayerName(int number) {
    return 'Layer $number';
  }

  @override
  String get editorCanvasDeleteLayer => 'Delete layer';

  @override
  String get editorCanvasDuplicateLayer => 'Duplicate layer';

  @override
  String get editorCanvasHideLayer => 'Hide';

  @override
  String get editorCanvasShowLayer => 'Show';

  @override
  String get editorCanvasLockLayer => 'Lock';

  @override
  String get editorCanvasUnlockLayer => 'Unlock';

  @override
  String get editorCanvasZoomLock => 'Zoom lock';

  @override
  String editorCanvasZoomLevel(int percent) {
    return 'Zoom $percent%, favorite levels';
  }

  @override
  String get editorCanvasFavoriteZoom => 'Favorite zoom';

  @override
  String editorCanvasPenBox(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pen box, $count pens',
      one: 'Pen box, 1 pen',
    );
    return '$_temp0';
  }

  @override
  String get editorCanvasFinishEditing => 'Done editing';

  @override
  String get editorCanvasEditPenBox => 'Edit pen box';

  @override
  String get editorCanvasCollapsePenBox => 'Collapse pen box';

  @override
  String get editorCanvasRemovePen => 'Remove pen';

  @override
  String get editorCanvasAddImage => 'Add image';

  @override
  String get editorCanvasAddImageHint =>
      'Add an image from the gallery or camera';

  @override
  String get editorCanvasFromGallery => 'Choose from gallery';

  @override
  String get editorCanvasFromGalleryHint => 'Pick an image from your albums';

  @override
  String get editorCanvasTakePhoto => 'Take photo';

  @override
  String get editorCanvasTakePhotoHint => 'Take a new photo with the camera';

  @override
  String get editorCanvasTapToPlace => 'Tap to place';

  @override
  String get editorCanvasTapToPlaceImage => 'Tap to place the image';

  @override
  String get editorCanvasAddColor => 'Add color';

  @override
  String get editorCanvasTextStyleTitle => 'Text style';

  @override
  String get editorCanvasEmojiSize => 'Emoji size';

  @override
  String get editorCanvasTextPreviewSample => 'Hello';

  @override
  String get libraryManageFolders => 'Manage folders';

  @override
  String get libraryNoFoldersYet => 'No folders yet';

  @override
  String get libraryNoFoldersHint => 'Tap the button below to create a folder';

  @override
  String get libraryNoFoldersStartHint => 'Create a folder to get started';

  @override
  String get libraryFolderOrderSaved => 'Order saved';

  @override
  String get libraryAddSubfolder => 'Add subfolder';

  @override
  String libraryAddSubfolderTitle(String parent) {
    return 'New folder in $parent';
  }

  @override
  String libraryDeleteFolderConfirm(String name) {
    return 'Delete the folder \"$name\"?\nIts notes will be moved to the trash.';
  }

  @override
  String get libraryFolderManagement => 'Folder management';

  @override
  String get libraryMoveFolderTitle => 'Move folder';

  @override
  String get libraryMoveToFolderTitle => 'Move to folder';

  @override
  String get libraryFoldersLoadFailed => 'Couldn\'t load folders';

  @override
  String get libraryLoadFailed => 'Couldn\'t load your notes';

  @override
  String get libraryTrashLoadFailed => 'Couldn\'t load the trash';

  @override
  String get libraryFolderNameEmpty => 'Folder name can\'t be empty';

  @override
  String libraryFolderCreated(String name) {
    return 'Folder \"$name\" created';
  }

  @override
  String get libraryRootFolders => 'Top-level folders';

  @override
  String get libraryNoFolderRoot => 'Documents (no folder)';

  @override
  String get libraryFolderNameHint => 'Enter a folder name';

  @override
  String get libraryColor => 'Color';

  @override
  String get libraryFolderColorEmerald => 'Emerald';

  @override
  String get libraryFolderColorPurple => 'Purple';

  @override
  String get libraryFolderColorPink => 'Pink';

  @override
  String get libraryFolderColorRed => 'Red';

  @override
  String get libraryFolderColorOrange => 'Orange';

  @override
  String get libraryFolderColorAmber => 'Amber';

  @override
  String get libraryFolderColorGreen => 'Green';

  @override
  String get libraryFolderColorTeal => 'Teal';

  @override
  String get libraryFolderColorCyan => 'Cyan';

  @override
  String get libraryFolderColorBlue => 'Blue';

  @override
  String get libraryFolderColorGray => 'Gray';

  @override
  String get libraryFolderColorStone => 'Stone';
}
