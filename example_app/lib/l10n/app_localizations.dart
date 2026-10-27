import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr')
  ];

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Tooltip of the back arrow in app bars.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get commonCreate;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @commonRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get commonRename;

  /// No description provided for @commonMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get commonMove;

  /// No description provided for @commonDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get commonDuplicate;

  /// No description provided for @commonRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get commonRestore;

  /// No description provided for @commonMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get commonMenu;

  /// No description provided for @commonErrorDetail.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String commonErrorDetail(String error);

  /// Settings screen title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Section header; stored uppercase because Dart toUpperCase is not locale-aware.
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get settingsSectionAppearance;

  /// Section header; stored uppercase.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get settingsSectionAccount;

  /// Section header; stored uppercase.
  ///
  /// In en, this message translates to:
  /// **'PRIVACY'**
  String get settingsSectionPrivacy;

  /// Section header; stored uppercase.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get settingsSectionAbout;

  /// App theme tile title.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// Light theme option.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// Dark theme option.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// Follow the system theme option.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose theme'**
  String get settingsThemeDialogTitle;

  /// Title of the canvas (drawing surface) theme setting.
  ///
  /// In en, this message translates to:
  /// **'Canvas theme'**
  String get settingsCanvasTheme;

  /// No description provided for @settingsPinFavorites.
  ///
  /// In en, this message translates to:
  /// **'Pin favorites to top'**
  String get settingsPinFavorites;

  /// No description provided for @settingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get settingsChangePassword;

  /// No description provided for @settingsChangePasswordSoon.
  ///
  /// In en, this message translates to:
  /// **'Changing the password is coming soon'**
  String get settingsChangePasswordSoon;

  /// Tile title that opens the account info dialog.
  ///
  /// In en, this message translates to:
  /// **'Account info'**
  String get settingsAccountInfo;

  /// Title of the account info dialog.
  ///
  /// In en, this message translates to:
  /// **'Account Info'**
  String get settingsAccountInfoTitle;

  /// No description provided for @settingsAccountEmail.
  ///
  /// In en, this message translates to:
  /// **'Email: {email}'**
  String settingsAccountEmail(String email);

  /// No description provided for @settingsAccountId.
  ///
  /// In en, this message translates to:
  /// **'ID: {id}'**
  String settingsAccountId(String id);

  /// Display name when the signed-in user has no name or email.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get settingsUserFallbackName;

  /// Title of the edit name dialog.
  ///
  /// In en, this message translates to:
  /// **'Edit Name'**
  String get settingsEditName;

  /// Screen reader hint of the tappable user name.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get settingsEditNameHint;

  /// Label of the name text field.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get settingsNameLabel;

  /// Log out button and dialog title.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get settingsLogout;

  /// No description provided for @settingsLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of your account?'**
  String get settingsLogoutConfirm;

  /// No description provided for @settingsCrashReports.
  ///
  /// In en, this message translates to:
  /// **'Send crash reports'**
  String get settingsCrashReports;

  /// No description provided for @settingsCrashReportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Anonymous error reports; note content is never sent'**
  String get settingsCrashReportsSubtitle;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// Tile title and privacy policy screen title.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsPrivacyPolicyLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the privacy policy'**
  String get settingsPrivacyPolicyLoadError;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get settingsLicenses;

  /// No description provided for @settingsFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get settingsFeedback;

  /// Screen reader label of the copy icon.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get settingsCopy;

  /// No description provided for @settingsEmailCopied.
  ///
  /// In en, this message translates to:
  /// **'Email address copied'**
  String get settingsEmailCopied;

  /// No description provided for @libraryErrorCreateDocument.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the notebook'**
  String get libraryErrorCreateDocument;

  /// No description provided for @libraryErrorImportDocument.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t import the document'**
  String get libraryErrorImportDocument;

  /// No description provided for @libraryErrorMoveDocument.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t move the notebook'**
  String get libraryErrorMoveDocument;

  /// No description provided for @libraryErrorToggleFavorite.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update favorites'**
  String get libraryErrorToggleFavorite;

  /// No description provided for @libraryErrorTrashDocument.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t move the notebook to the trash'**
  String get libraryErrorTrashDocument;

  /// No description provided for @libraryErrorDeleteDocument.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the notebook'**
  String get libraryErrorDeleteDocument;

  /// No description provided for @libraryErrorRenameDocument.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t rename the notebook'**
  String get libraryErrorRenameDocument;

  /// No description provided for @libraryErrorRestoreDocument.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t restore the notebook'**
  String get libraryErrorRestoreDocument;

  /// No description provided for @libraryErrorDuplicateDocument.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t duplicate the notebook'**
  String get libraryErrorDuplicateDocument;

  /// No description provided for @libraryErrorDeleteDocumentForever.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the notebook permanently'**
  String get libraryErrorDeleteDocumentForever;

  /// No description provided for @libraryErrorTrashDocuments.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t move the notebooks to the trash'**
  String get libraryErrorTrashDocuments;

  /// No description provided for @libraryErrorDeleteDocumentsForever.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the notebooks permanently'**
  String get libraryErrorDeleteDocumentsForever;

  /// No description provided for @libraryErrorDuplicateDocuments.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t duplicate the notebooks'**
  String get libraryErrorDuplicateDocuments;

  /// No description provided for @libraryErrorMoveDocuments.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t move the notebooks'**
  String get libraryErrorMoveDocuments;

  /// No description provided for @libraryErrorTrashPage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t move the page to the trash'**
  String get libraryErrorTrashPage;

  /// No description provided for @libraryErrorDeletePageForever.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the page permanently'**
  String get libraryErrorDeletePageForever;

  /// No description provided for @libraryErrorEmptyTrash.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t empty the trash'**
  String get libraryErrorEmptyTrash;

  /// No description provided for @libraryErrorCreateFolder.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the folder'**
  String get libraryErrorCreateFolder;

  /// No description provided for @libraryErrorRenameFolder.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t rename the folder'**
  String get libraryErrorRenameFolder;

  /// No description provided for @libraryErrorRecolorFolder.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t change the folder color'**
  String get libraryErrorRecolorFolder;

  /// No description provided for @libraryErrorSaveFolderOrder.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the order'**
  String get libraryErrorSaveFolderOrder;

  /// No description provided for @libraryErrorMoveFolder.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t move the folder'**
  String get libraryErrorMoveFolder;

  /// No description provided for @libraryErrorDeleteFolder.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the folder'**
  String get libraryErrorDeleteFolder;

  /// No description provided for @libraryRuleFolderDepth.
  ///
  /// In en, this message translates to:
  /// **'Folders can only be one level deep'**
  String get libraryRuleFolderDepth;

  /// No description provided for @libraryRuleFolderIntoOwnSubfolder.
  ///
  /// In en, this message translates to:
  /// **'A folder can\'t be moved into its own subfolder'**
  String get libraryRuleFolderIntoOwnSubfolder;

  /// No description provided for @libraryRuleFolderMoveDepth.
  ///
  /// In en, this message translates to:
  /// **'A folder can\'t be moved into a subfolder'**
  String get libraryRuleFolderMoveDepth;

  /// No description provided for @libraryRuleFolderWithSubfoldersMove.
  ///
  /// In en, this message translates to:
  /// **'A folder with subfolders can\'t be moved into another folder'**
  String get libraryRuleFolderWithSubfoldersMove;

  /// No description provided for @libraryRuleDocumentLimit.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the free limit. Upgrade to Premium.'**
  String get libraryRuleDocumentLimit;

  /// No description provided for @libraryRuleFolderLimit.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the folder limit. Upgrade to Premium.'**
  String get libraryRuleFolderLimit;

  /// No description provided for @librarySortByDate.
  ///
  /// In en, this message translates to:
  /// **'By date'**
  String get librarySortByDate;

  /// No description provided for @librarySortByName.
  ///
  /// In en, this message translates to:
  /// **'By name'**
  String get librarySortByName;

  /// No description provided for @librarySortBySize.
  ///
  /// In en, this message translates to:
  /// **'By size'**
  String get librarySortBySize;

  /// No description provided for @librarySectionAll.
  ///
  /// In en, this message translates to:
  /// **'All notes'**
  String get librarySectionAll;

  /// No description provided for @librarySectionFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get librarySectionFavorites;

  /// No description provided for @librarySectionTrash.
  ///
  /// In en, this message translates to:
  /// **'Recently deleted'**
  String get librarySectionTrash;

  /// No description provided for @libraryFolderFallback.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get libraryFolderFallback;

  /// No description provided for @libraryPaperSquare.
  ///
  /// In en, this message translates to:
  /// **'Square'**
  String get libraryPaperSquare;

  /// No description provided for @libraryPaperWide.
  ///
  /// In en, this message translates to:
  /// **'Widescreen'**
  String get libraryPaperWide;

  /// No description provided for @libraryPaperCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get libraryPaperCustom;

  /// No description provided for @libraryBreadcrumbRoot.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryBreadcrumbRoot;

  /// No description provided for @libraryFolders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get libraryFolders;

  /// No description provided for @libraryDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get libraryDocuments;

  /// No description provided for @libraryManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get libraryManage;

  /// No description provided for @libraryNewFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get libraryNewFolder;

  /// No description provided for @libraryNoFolders.
  ///
  /// In en, this message translates to:
  /// **'No folders'**
  String get libraryNoFolders;

  /// No description provided for @librarySidebarCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get librarySidebarCollapse;

  /// No description provided for @libraryOpenSidebar.
  ///
  /// In en, this message translates to:
  /// **'Open sidebar'**
  String get libraryOpenSidebar;

  /// No description provided for @librarySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get librarySearchHint;

  /// No description provided for @libraryListView.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get libraryListView;

  /// No description provided for @libraryGridView.
  ///
  /// In en, this message translates to:
  /// **'Grid view'**
  String get libraryGridView;

  /// No description provided for @librarySelectMode.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get librarySelectMode;

  /// No description provided for @libraryNewDocument.
  ///
  /// In en, this message translates to:
  /// **'New document'**
  String get libraryNewDocument;

  /// No description provided for @libraryNewDocumentLocked.
  ///
  /// In en, this message translates to:
  /// **'Document limit reached'**
  String get libraryNewDocumentLocked;

  /// No description provided for @libraryNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get libraryNew;

  /// No description provided for @libraryTrashInfo.
  ///
  /// In en, this message translates to:
  /// **'Deleted notes are permanently removed after 30 days'**
  String get libraryTrashInfo;

  /// No description provided for @libraryEmptyTrash.
  ///
  /// In en, this message translates to:
  /// **'Empty trash'**
  String get libraryEmptyTrash;

  /// No description provided for @libraryEmptyTrashConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Everything in the trash will be deleted permanently. This can\'t be undone.'**
  String get libraryEmptyTrashConfirmMessage;

  /// No description provided for @libraryEmptyTrashConfirm.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get libraryEmptyTrashConfirm;

  /// No description provided for @libraryTrashEmptied.
  ///
  /// In en, this message translates to:
  /// **'Trash emptied'**
  String get libraryTrashEmptied;

  /// No description provided for @libraryOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the notebook'**
  String get libraryOpenFailed;

  /// No description provided for @libraryTrashCountsTowardsLimit.
  ///
  /// In en, this message translates to:
  /// **'Notes in the trash count towards the limit. Delete them permanently to free up space, or'**
  String get libraryTrashCountsTowardsLimit;

  /// No description provided for @libraryRemainingDocuments.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 document left} other{{count} documents left}}'**
  String libraryRemainingDocuments(int count);

  /// No description provided for @librarySortTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get librarySortTitle;

  /// No description provided for @librarySortNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get librarySortNewestFirst;

  /// No description provided for @librarySortOldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get librarySortOldestFirst;

  /// No description provided for @libraryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get libraryEmptyTitle;

  /// No description provided for @libraryEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a notebook or import a PDF.'**
  String get libraryEmptyMessage;

  /// No description provided for @libraryEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get libraryEmptyAction;

  /// No description provided for @libraryEmptyFavoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'No favorite notes'**
  String get libraryEmptyFavoritesTitle;

  /// No description provided for @libraryEmptyFavoritesMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap the star icon to add notes to your favorites'**
  String get libraryEmptyFavoritesMessage;

  /// No description provided for @libraryEmptyFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'This folder is empty'**
  String get libraryEmptyFolderTitle;

  /// No description provided for @libraryEmptyFolderMessage.
  ///
  /// In en, this message translates to:
  /// **'Move notes here or create a new one'**
  String get libraryEmptyFolderMessage;

  /// No description provided for @libraryTrashEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Trash is empty'**
  String get libraryTrashEmptyTitle;

  /// No description provided for @libraryTrashEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Deleted notes will appear here'**
  String get libraryTrashEmptyMessage;

  /// No description provided for @libraryNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get libraryNoResultsTitle;

  /// No description provided for @libraryNoResultsMessage.
  ///
  /// In en, this message translates to:
  /// **'No notes match \"{query}\"'**
  String libraryNoResultsMessage(String query);

  /// No description provided for @libraryClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get libraryClearSearch;

  /// No description provided for @librarySelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String librarySelectedCount(int count);

  /// No description provided for @librarySelectAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get librarySelectAll;

  /// No description provided for @libraryDeleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get libraryDeleteForever;

  /// No description provided for @libraryDeleteForeverTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently?'**
  String get libraryDeleteForeverTitle;

  /// No description provided for @libraryDeleteDocumentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete notes'**
  String get libraryDeleteDocumentsTitle;

  /// No description provided for @libraryDocumentLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Document limit reached'**
  String get libraryDocumentLimitReached;

  /// No description provided for @libraryDocumentsCopied.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 document duplicated} other{{count} documents duplicated}}'**
  String libraryDocumentsCopied(int count);

  /// No description provided for @libraryDocumentsTrashed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 document moved to the trash} other{{count} documents moved to the trash}}'**
  String libraryDocumentsTrashed(int count);

  /// No description provided for @libraryDocumentsDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 document deleted} other{{count} documents deleted}}'**
  String libraryDocumentsDeleted(int count);

  /// No description provided for @libraryDeleteDocumentsForeverMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 document will be deleted permanently. This can\'t be undone.} other{{count} documents will be deleted permanently. This can\'t be undone.}}'**
  String libraryDeleteDocumentsForeverMessage(int count);

  /// No description provided for @libraryTrashDocumentsMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 document will be moved to the trash.} other{{count} documents will be moved to the trash.}}'**
  String libraryTrashDocumentsMessage(int count);

  /// No description provided for @libraryPageCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 page} other{{count} pages}}'**
  String libraryPageCount(int count);

  /// No description provided for @libraryDocumentCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 document} other{{count} documents}}'**
  String libraryDocumentCount(int count);

  /// No description provided for @libraryDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day} other{{days} days}}'**
  String libraryDaysLeft(int days);

  /// No description provided for @libraryRemoveFavoriteBadge.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get libraryRemoveFavoriteBadge;

  /// No description provided for @libraryRemoveFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get libraryRemoveFromFavorites;

  /// No description provided for @libraryAddToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get libraryAddToFavorites;

  /// No description provided for @libraryMoveToTrash.
  ///
  /// In en, this message translates to:
  /// **'Move to trash'**
  String get libraryMoveToTrash;

  /// No description provided for @libraryDocumentDuplicated.
  ///
  /// In en, this message translates to:
  /// **'Notebook duplicated'**
  String get libraryDocumentDuplicated;

  /// No description provided for @libraryDocumentMoved.
  ///
  /// In en, this message translates to:
  /// **'Notebook moved'**
  String get libraryDocumentMoved;

  /// No description provided for @libraryDocumentRestored.
  ///
  /// In en, this message translates to:
  /// **'Notebook restored'**
  String get libraryDocumentRestored;

  /// No description provided for @libraryDeleteDocumentForeverMessage.
  ///
  /// In en, this message translates to:
  /// **'This notebook will be deleted permanently. This can\'t be undone.'**
  String get libraryDeleteDocumentForeverMessage;

  /// No description provided for @libraryDocumentNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Notebook name'**
  String get libraryDocumentNameLabel;

  /// No description provided for @libraryChangeColor.
  ///
  /// In en, this message translates to:
  /// **'Change color'**
  String get libraryChangeColor;

  /// No description provided for @libraryFolderMoved.
  ///
  /// In en, this message translates to:
  /// **'Folder moved'**
  String get libraryFolderMoved;

  /// No description provided for @libraryFolderColorChanged.
  ///
  /// In en, this message translates to:
  /// **'Folder color changed'**
  String get libraryFolderColorChanged;

  /// No description provided for @libraryDeleteFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete folder'**
  String get libraryDeleteFolderTitle;

  /// No description provided for @libraryDeleteFolderNonEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{This folder contains 1 document. Deleting the folder also deletes that document. Continue?} other{This folder contains {count} documents. Deleting it also deletes them. Continue?}}'**
  String libraryDeleteFolderNonEmptyMessage(int count);

  /// No description provided for @libraryDeleteFolderMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete this folder?'**
  String get libraryDeleteFolderMessage;

  /// No description provided for @libraryFolderDeleted.
  ///
  /// In en, this message translates to:
  /// **'Folder deleted'**
  String get libraryFolderDeleted;

  /// No description provided for @libraryRenameFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename folder'**
  String get libraryRenameFolderTitle;

  /// No description provided for @libraryFolderNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get libraryFolderNameLabel;

  /// No description provided for @libraryFolderRenamed.
  ///
  /// In en, this message translates to:
  /// **'Folder renamed to \"{name}\"'**
  String libraryFolderRenamed(String name);

  /// No description provided for @libraryPageNumber.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String libraryPageNumber(int page);

  /// No description provided for @libraryTrashedPageTitle.
  ///
  /// In en, this message translates to:
  /// **'{document} — Page {page}'**
  String libraryTrashedPageTitle(String document, int page);

  /// No description provided for @librarySourceDocumentMissing.
  ///
  /// In en, this message translates to:
  /// **'The original notebook no longer exists'**
  String get librarySourceDocumentMissing;

  /// No description provided for @libraryPageRestored.
  ///
  /// In en, this message translates to:
  /// **'Page restored'**
  String get libraryPageRestored;

  /// No description provided for @libraryPageRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t restore the page'**
  String get libraryPageRestoreFailed;

  /// No description provided for @libraryDeletePageForeverMessage.
  ///
  /// In en, this message translates to:
  /// **'This page will be deleted permanently. This can\'t be undone.'**
  String get libraryDeletePageForeverMessage;

  /// No description provided for @libraryCopyTitle.
  ///
  /// In en, this message translates to:
  /// **'{title} (copy)'**
  String libraryCopyTitle(String title);

  /// No description provided for @editorDocumentNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Document name'**
  String get editorDocumentNameLabel;

  /// No description provided for @editorMoveToTrashTitle.
  ///
  /// In en, this message translates to:
  /// **'Move to trash'**
  String get editorMoveToTrashTitle;

  /// No description provided for @editorMoveToTrashMessage.
  ///
  /// In en, this message translates to:
  /// **'This document will be moved to the trash. You can restore it later.'**
  String get editorMoveToTrashMessage;

  /// No description provided for @editorLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the document'**
  String get editorLoadErrorTitle;

  /// No description provided for @editorLoadErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'The document wasn\'t found or couldn\'t be read.'**
  String get editorLoadErrorMessage;

  /// No description provided for @editorLoadErrorBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get editorLoadErrorBack;

  /// No description provided for @editorSaveFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Your changes haven\'t been saved yet.'**
  String get editorSaveFailedMessage;

  /// No description provided for @startupErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'The app couldn\'t start'**
  String get startupErrorTitle;

  /// No description provided for @startupErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Your notes are safe, nothing was deleted. Something went wrong while opening your data. Try again; if the problem persists, close the app and reopen it.'**
  String get startupErrorMessage;

  /// No description provided for @commonPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get commonPasswordLabel;

  /// No description provided for @commonSelectItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Select an item'**
  String get commonSelectItemTitle;

  /// No description provided for @commonSelectItemDescription.
  ///
  /// In en, this message translates to:
  /// **'Select an item on the left to see its details'**
  String get commonSelectItemDescription;

  /// No description provided for @commonUnderConstruction.
  ///
  /// In en, this message translates to:
  /// **'This screen is still under construction'**
  String get commonUnderConstruction;

  /// No description provided for @routerForgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get routerForgotPasswordTitle;

  /// No description provided for @routerProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get routerProfileTitle;

  /// No description provided for @routerSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get routerSubscriptionTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
