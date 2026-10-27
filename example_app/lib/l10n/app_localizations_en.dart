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
}
