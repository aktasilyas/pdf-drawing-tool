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

  /// No description provided for @libraryErrorBulkPartial.
  ///
  /// In en, this message translates to:
  /// **'{message} ({failed} of {total} failed)'**
  String libraryErrorBulkPartial(String message, int failed, int total);

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

  /// No description provided for @editorToolFountainPen.
  ///
  /// In en, this message translates to:
  /// **'Fountain pen'**
  String get editorToolFountainPen;

  /// No description provided for @editorToolPencil.
  ///
  /// In en, this message translates to:
  /// **'Pencil'**
  String get editorToolPencil;

  /// No description provided for @editorToolHardPencil.
  ///
  /// In en, this message translates to:
  /// **'Hard pencil'**
  String get editorToolHardPencil;

  /// No description provided for @editorToolBallpointPen.
  ///
  /// In en, this message translates to:
  /// **'Ballpoint pen'**
  String get editorToolBallpointPen;

  /// No description provided for @editorToolGelPen.
  ///
  /// In en, this message translates to:
  /// **'Gel pen'**
  String get editorToolGelPen;

  /// No description provided for @editorToolDashedPen.
  ///
  /// In en, this message translates to:
  /// **'Dashed pen'**
  String get editorToolDashedPen;

  /// No description provided for @editorToolHighlighter.
  ///
  /// In en, this message translates to:
  /// **'Highlighter'**
  String get editorToolHighlighter;

  /// No description provided for @editorToolBrushPen.
  ///
  /// In en, this message translates to:
  /// **'Brush pen'**
  String get editorToolBrushPen;

  /// No description provided for @editorToolNeonHighlighter.
  ///
  /// In en, this message translates to:
  /// **'Neon highlighter'**
  String get editorToolNeonHighlighter;

  /// No description provided for @editorToolRulerPen.
  ///
  /// In en, this message translates to:
  /// **'Ruler pen'**
  String get editorToolRulerPen;

  /// No description provided for @editorToolPixelEraser.
  ///
  /// In en, this message translates to:
  /// **'Eraser'**
  String get editorToolPixelEraser;

  /// No description provided for @editorToolStrokeEraser.
  ///
  /// In en, this message translates to:
  /// **'Stroke eraser'**
  String get editorToolStrokeEraser;

  /// No description provided for @editorToolLassoEraser.
  ///
  /// In en, this message translates to:
  /// **'Lasso eraser'**
  String get editorToolLassoEraser;

  /// No description provided for @editorToolShapes.
  ///
  /// In en, this message translates to:
  /// **'Shapes'**
  String get editorToolShapes;

  /// No description provided for @editorToolText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get editorToolText;

  /// No description provided for @editorToolSticker.
  ///
  /// In en, this message translates to:
  /// **'Sticker'**
  String get editorToolSticker;

  /// No description provided for @editorToolImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get editorToolImage;

  /// No description provided for @editorToolSelection.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get editorToolSelection;

  /// No description provided for @editorToolPanZoom.
  ///
  /// In en, this message translates to:
  /// **'Pan & zoom'**
  String get editorToolPanZoom;

  /// No description provided for @editorToolLaserPointer.
  ///
  /// In en, this message translates to:
  /// **'Laser pointer'**
  String get editorToolLaserPointer;

  /// No description provided for @editorToolStickyNote.
  ///
  /// In en, this message translates to:
  /// **'Sticky note'**
  String get editorToolStickyNote;

  /// No description provided for @editorToolToolbarSettings.
  ///
  /// In en, this message translates to:
  /// **'Toolbar settings'**
  String get editorToolToolbarSettings;

  /// No description provided for @editorToolPenGroup.
  ///
  /// In en, this message translates to:
  /// **'Pen'**
  String get editorToolPenGroup;

  /// No description provided for @editorToolbarHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get editorToolbarHome;

  /// No description provided for @editorToolbarPages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get editorToolbarPages;

  /// No description provided for @editorToolbarRuler.
  ///
  /// In en, this message translates to:
  /// **'Ruler'**
  String get editorToolbarRuler;

  /// No description provided for @editorToolbarAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio recording'**
  String get editorToolbarAudio;

  /// No description provided for @editorToolbarReaderMode.
  ///
  /// In en, this message translates to:
  /// **'Reader mode'**
  String get editorToolbarReaderMode;

  /// No description provided for @editorToolbarEditMode.
  ///
  /// In en, this message translates to:
  /// **'Edit mode'**
  String get editorToolbarEditMode;

  /// No description provided for @editorToolbarMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get editorToolbarMore;

  /// No description provided for @editorToolbarLayers.
  ///
  /// In en, this message translates to:
  /// **'Layers'**
  String get editorToolbarLayers;

  /// No description provided for @editorToolbarAddPage.
  ///
  /// In en, this message translates to:
  /// **'Add page'**
  String get editorToolbarAddPage;

  /// No description provided for @editorToolbarExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get editorToolbarExport;

  /// No description provided for @editorToolbarAi.
  ///
  /// In en, this message translates to:
  /// **'AI assistant'**
  String get editorToolbarAi;

  /// No description provided for @editorToolbarUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled note'**
  String get editorToolbarUntitled;

  /// No description provided for @editorToolbarMoreColors.
  ///
  /// In en, this message translates to:
  /// **'More colors'**
  String get editorToolbarMoreColors;

  /// No description provided for @editorToolbarColorSetHighlighter.
  ///
  /// In en, this message translates to:
  /// **'Highlighter'**
  String get editorToolbarColorSetHighlighter;

  /// No description provided for @editorToolbarColorSetPastel.
  ///
  /// In en, this message translates to:
  /// **'Pastel'**
  String get editorToolbarColorSetPastel;

  /// No description provided for @editorToolbarSelectedColor.
  ///
  /// In en, this message translates to:
  /// **'Selected color {hex}'**
  String editorToolbarSelectedColor(String hex);

  /// No description provided for @editorToolbarColor.
  ///
  /// In en, this message translates to:
  /// **'Color {hex}'**
  String editorToolbarColor(String hex);

  /// No description provided for @editorToolbarThickness.
  ///
  /// In en, this message translates to:
  /// **'Thickness {value}'**
  String editorToolbarThickness(String value);

  /// No description provided for @editorToolbarMoreTools.
  ///
  /// In en, this message translates to:
  /// **'More tools'**
  String get editorToolbarMoreTools;

  /// No description provided for @editorToolbarReadOnlyActive.
  ///
  /// In en, this message translates to:
  /// **'Read-only mode on'**
  String get editorToolbarReadOnlyActive;

  /// No description provided for @editorToolbarReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read-only'**
  String get editorToolbarReadOnly;

  /// No description provided for @editorToolbarUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get editorToolbarUndo;

  /// No description provided for @editorToolbarRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get editorToolbarRedo;

  /// No description provided for @editorToolbarRecordingInProgress.
  ///
  /// In en, this message translates to:
  /// **'Recording…'**
  String get editorToolbarRecordingInProgress;

  /// No description provided for @editorToolbarRecord.
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get editorToolbarRecord;

  /// No description provided for @editorToolbarMicPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is required. Please allow it in Settings.'**
  String get editorToolbarMicPermissionRequired;

  /// No description provided for @editorToolbarShowRecordings.
  ///
  /// In en, this message translates to:
  /// **'Show recordings'**
  String get editorToolbarShowRecordings;

  /// No description provided for @editorToolbarSettingsTabTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get editorToolbarSettingsTabTools;

  /// No description provided for @editorToolbarSettingsTabExtraTools.
  ///
  /// In en, this message translates to:
  /// **'Extra tools'**
  String get editorToolbarSettingsTabExtraTools;

  /// No description provided for @editorToolbarSettingsToolsHint.
  ///
  /// In en, this message translates to:
  /// **'Reorder and hide tools'**
  String get editorToolbarSettingsToolsHint;

  /// No description provided for @editorToolbarSettingsExtraToolsHint.
  ///
  /// In en, this message translates to:
  /// **'Reorder and hide extra tools'**
  String get editorToolbarSettingsExtraToolsHint;

  /// No description provided for @editorToolbarSettingsReset.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get editorToolbarSettingsReset;

  /// No description provided for @editorToolbarColorSetBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get editorToolbarColorSetBasic;

  /// No description provided for @editorToolbarColorSetNeon.
  ///
  /// In en, this message translates to:
  /// **'Neon'**
  String get editorToolbarColorSetNeon;

  /// No description provided for @editorPanelClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get editorPanelClose;

  /// No description provided for @editorPanelThickness.
  ///
  /// In en, this message translates to:
  /// **'Thickness'**
  String get editorPanelThickness;

  /// No description provided for @editorPanelPressureSensitivity.
  ///
  /// In en, this message translates to:
  /// **'Pressure sensitivity'**
  String get editorPanelPressureSensitivity;

  /// No description provided for @editorPanelStabilization.
  ///
  /// In en, this message translates to:
  /// **'Stroke stabilization'**
  String get editorPanelStabilization;

  /// No description provided for @editorPanelPenType.
  ///
  /// In en, this message translates to:
  /// **'Pen type'**
  String get editorPanelPenType;

  /// No description provided for @editorPanelGlow.
  ///
  /// In en, this message translates to:
  /// **'Glow'**
  String get editorPanelGlow;

  /// No description provided for @editorPanelStraightLine.
  ///
  /// In en, this message translates to:
  /// **'Straight line'**
  String get editorPanelStraightLine;

  /// No description provided for @editorPanelSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get editorPanelSize;

  /// No description provided for @editorPanelEraserPixel.
  ///
  /// In en, this message translates to:
  /// **'Pixel eraser'**
  String get editorPanelEraserPixel;

  /// No description provided for @editorPanelEraserPressure.
  ///
  /// In en, this message translates to:
  /// **'Pressure sensitivity'**
  String get editorPanelEraserPressure;

  /// No description provided for @editorPanelEraserHighlighterOnly.
  ///
  /// In en, this message translates to:
  /// **'Erase highlighter only'**
  String get editorPanelEraserHighlighterOnly;

  /// No description provided for @editorPanelEraserAutoLift.
  ///
  /// In en, this message translates to:
  /// **'Auto-deselect'**
  String get editorPanelEraserAutoLift;

  /// No description provided for @editorPanelClearPage.
  ///
  /// In en, this message translates to:
  /// **'Clear page'**
  String get editorPanelClearPage;

  /// No description provided for @editorPanelClearPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear page?'**
  String get editorPanelClearPageTitle;

  /// No description provided for @editorPanelClearPageMessage.
  ///
  /// In en, this message translates to:
  /// **'This erases everything on this page. This can\'t be undone.'**
  String get editorPanelClearPageMessage;

  /// No description provided for @editorPanelCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get editorPanelCancel;

  /// No description provided for @editorPanelClearPageConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get editorPanelClearPageConfirm;

  /// No description provided for @editorPanelLaserDot.
  ///
  /// In en, this message translates to:
  /// **'Laser dot'**
  String get editorPanelLaserDot;

  /// No description provided for @editorPanelLaserLine.
  ///
  /// In en, this message translates to:
  /// **'Laser line'**
  String get editorPanelLaserLine;

  /// No description provided for @editorPanelLaserHollow.
  ///
  /// In en, this message translates to:
  /// **'Hollow laser line'**
  String get editorPanelLaserHollow;

  /// No description provided for @editorPanelLaserRainbow.
  ///
  /// In en, this message translates to:
  /// **'Rainbow laser'**
  String get editorPanelLaserRainbow;

  /// No description provided for @editorPanelLaserDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get editorPanelLaserDuration;

  /// No description provided for @editorPanelTextTitle.
  ///
  /// In en, this message translates to:
  /// **'Text tool'**
  String get editorPanelTextTitle;

  /// No description provided for @editorPanelTextHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the canvas to add a text box.'**
  String get editorPanelTextHint;

  /// No description provided for @editorPanelTextColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get editorPanelTextColor;

  /// No description provided for @editorPanelTextStyle.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get editorPanelTextStyle;

  /// No description provided for @editorPanelAddNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get editorPanelAddNote;

  /// No description provided for @editorPanelColorHex.
  ///
  /// In en, this message translates to:
  /// **'Hex'**
  String get editorPanelColorHex;

  /// No description provided for @editorPanelColorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get editorPanelColorRed;

  /// No description provided for @editorPanelColorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get editorPanelColorGreen;

  /// No description provided for @editorPanelColorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get editorPanelColorBlue;

  /// No description provided for @editorPanelColorCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get editorPanelColorCancel;

  /// No description provided for @editorPanelColorDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get editorPanelColorDone;

  /// No description provided for @editorPanelColorSwatches.
  ///
  /// In en, this message translates to:
  /// **'Swatches'**
  String get editorPanelColorSwatches;

  /// No description provided for @editorPanelColorSpectrum.
  ///
  /// In en, this message translates to:
  /// **'Spectrum'**
  String get editorPanelColorSpectrum;

  /// No description provided for @editorCatalogShapesTitle.
  ///
  /// In en, this message translates to:
  /// **'Shape'**
  String get editorCatalogShapesTitle;

  /// No description provided for @editorCatalogStrokeWidth.
  ///
  /// In en, this message translates to:
  /// **'Stroke width'**
  String get editorCatalogStrokeWidth;

  /// No description provided for @editorCatalogStrokeColor.
  ///
  /// In en, this message translates to:
  /// **'Stroke color'**
  String get editorCatalogStrokeColor;

  /// No description provided for @editorCatalogFillShape.
  ///
  /// In en, this message translates to:
  /// **'Fill shape'**
  String get editorCatalogFillShape;

  /// No description provided for @editorCatalogFillColor.
  ///
  /// In en, this message translates to:
  /// **'Fill color'**
  String get editorCatalogFillColor;

  /// No description provided for @editorCatalogShapeLine.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get editorCatalogShapeLine;

  /// No description provided for @editorCatalogShapeArrow.
  ///
  /// In en, this message translates to:
  /// **'Arrow'**
  String get editorCatalogShapeArrow;

  /// No description provided for @editorCatalogShapeRectangle.
  ///
  /// In en, this message translates to:
  /// **'Rectangle'**
  String get editorCatalogShapeRectangle;

  /// No description provided for @editorCatalogShapeEllipse.
  ///
  /// In en, this message translates to:
  /// **'Ellipse'**
  String get editorCatalogShapeEllipse;

  /// No description provided for @editorCatalogShapeTriangle.
  ///
  /// In en, this message translates to:
  /// **'Triangle'**
  String get editorCatalogShapeTriangle;

  /// No description provided for @editorCatalogShapeDiamond.
  ///
  /// In en, this message translates to:
  /// **'Diamond'**
  String get editorCatalogShapeDiamond;

  /// No description provided for @editorCatalogShapeStar.
  ///
  /// In en, this message translates to:
  /// **'Star'**
  String get editorCatalogShapeStar;

  /// No description provided for @editorCatalogShapePentagon.
  ///
  /// In en, this message translates to:
  /// **'Pentagon'**
  String get editorCatalogShapePentagon;

  /// No description provided for @editorCatalogShapeHexagon.
  ///
  /// In en, this message translates to:
  /// **'Hexagon'**
  String get editorCatalogShapeHexagon;

  /// No description provided for @editorCatalogShapePlus.
  ///
  /// In en, this message translates to:
  /// **'Plus'**
  String get editorCatalogShapePlus;

  /// No description provided for @editorCatalogStickersTitle.
  ///
  /// In en, this message translates to:
  /// **'Stickers'**
  String get editorCatalogStickersTitle;

  /// No description provided for @editorCatalogAddSticker.
  ///
  /// In en, this message translates to:
  /// **'Add sticker'**
  String get editorCatalogAddSticker;

  /// No description provided for @editorCatalogStickerEmoji.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get editorCatalogStickerEmoji;

  /// No description provided for @editorCatalogStickerAnimals.
  ///
  /// In en, this message translates to:
  /// **'Animals'**
  String get editorCatalogStickerAnimals;

  /// No description provided for @editorCatalogStickerFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get editorCatalogStickerFood;

  /// No description provided for @editorCatalogStickerTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get editorCatalogStickerTravel;

  /// No description provided for @editorCatalogStickerObjects.
  ///
  /// In en, this message translates to:
  /// **'Objects'**
  String get editorCatalogStickerObjects;

  /// No description provided for @editorCatalogStickerSymbols.
  ///
  /// In en, this message translates to:
  /// **'Symbols'**
  String get editorCatalogStickerSymbols;

  /// No description provided for @editorCatalogStickerHands.
  ///
  /// In en, this message translates to:
  /// **'Hands'**
  String get editorCatalogStickerHands;

  /// No description provided for @editorCatalogStickerNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get editorCatalogStickerNature;

  /// No description provided for @editorSelectionLassoFreeform.
  ///
  /// In en, this message translates to:
  /// **'Freeform'**
  String get editorSelectionLassoFreeform;

  /// No description provided for @editorSelectionLassoRectangle.
  ///
  /// In en, this message translates to:
  /// **'Rectangle'**
  String get editorSelectionLassoRectangle;

  /// No description provided for @editorSelectionLassoSelectable.
  ///
  /// In en, this message translates to:
  /// **'Selectable'**
  String get editorSelectionLassoSelectable;

  /// No description provided for @editorSelectionTypeHandwriting.
  ///
  /// In en, this message translates to:
  /// **'Handwriting'**
  String get editorSelectionTypeHandwriting;

  /// No description provided for @editorSelectionTypeShape.
  ///
  /// In en, this message translates to:
  /// **'Shapes'**
  String get editorSelectionTypeShape;

  /// No description provided for @editorSelectionTypeImage.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get editorSelectionTypeImage;

  /// No description provided for @editorSelectionTypeHighlighter.
  ///
  /// In en, this message translates to:
  /// **'Highlighter'**
  String get editorSelectionTypeHighlighter;

  /// No description provided for @editorSelectionTypeText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get editorSelectionTypeText;

  /// No description provided for @editorSelectionTypeTape.
  ///
  /// In en, this message translates to:
  /// **'Tape'**
  String get editorSelectionTypeTape;

  /// No description provided for @editorSelectionTypeLink.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get editorSelectionTypeLink;

  /// No description provided for @editorSelectionTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get editorSelectionTypeLabel;

  /// No description provided for @editorSelectionAi.
  ///
  /// In en, this message translates to:
  /// **'AI assistant'**
  String get editorSelectionAi;

  /// No description provided for @editorSelectionColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get editorSelectionColor;

  /// No description provided for @editorSelectionScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Screenshot'**
  String get editorSelectionScreenshot;

  /// No description provided for @editorSelectionCut.
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get editorSelectionCut;

  /// No description provided for @editorSelectionDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get editorSelectionDuplicate;

  /// No description provided for @editorSelectionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get editorSelectionDelete;

  /// No description provided for @editorSelectionBringToFront.
  ///
  /// In en, this message translates to:
  /// **'Bring to front'**
  String get editorSelectionBringToFront;

  /// No description provided for @editorSelectionSendToBack.
  ///
  /// In en, this message translates to:
  /// **'Send to back'**
  String get editorSelectionSendToBack;

  /// No description provided for @editorSelectionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get editorSelectionCopy;

  /// No description provided for @editorSelectionPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get editorSelectionPaste;

  /// No description provided for @editorSelectionAskAi.
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get editorSelectionAskAi;

  /// No description provided for @editorSelectionTakeScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Take screenshot'**
  String get editorSelectionTakeScreenshot;

  /// No description provided for @editorSelectionMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get editorSelectionMore;

  /// No description provided for @editorSelectionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get editorSelectionSave;

  /// No description provided for @editorSelectionScreenshotCaptureFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the screenshot'**
  String get editorSelectionScreenshotCaptureFailed;

  /// No description provided for @editorSelectionScreenshotSavedAndCopied.
  ///
  /// In en, this message translates to:
  /// **'Screenshot saved to the gallery and copied to the clipboard'**
  String get editorSelectionScreenshotSavedAndCopied;

  /// No description provided for @editorSelectionScreenshotSaved.
  ///
  /// In en, this message translates to:
  /// **'Screenshot saved to the gallery'**
  String get editorSelectionScreenshotSaved;

  /// No description provided for @editorSelectionScreenshotCopied.
  ///
  /// In en, this message translates to:
  /// **'Screenshot copied to the clipboard'**
  String get editorSelectionScreenshotCopied;

  /// No description provided for @editorSelectionScreenshotSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the screenshot'**
  String get editorSelectionScreenshotSaveFailed;

  /// No description provided for @editorSelectionContextEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editorSelectionContextEdit;

  /// No description provided for @editorSelectionContextStyle.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get editorSelectionContextStyle;

  /// No description provided for @editorSelectionContextMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get editorSelectionContextMove;

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

  /// No description provided for @libraryNewNotebook.
  ///
  /// In en, this message translates to:
  /// **'Notebook'**
  String get libraryNewNotebook;

  /// No description provided for @libraryNewWhiteboard.
  ///
  /// In en, this message translates to:
  /// **'Whiteboard'**
  String get libraryNewWhiteboard;

  /// No description provided for @libraryNewQuickNote.
  ///
  /// In en, this message translates to:
  /// **'Quick note'**
  String get libraryNewQuickNote;

  /// No description provided for @libraryImportPdf.
  ///
  /// In en, this message translates to:
  /// **'Import PDF'**
  String get libraryImportPdf;

  /// No description provided for @libraryImportImage.
  ///
  /// In en, this message translates to:
  /// **'Import image'**
  String get libraryImportImage;

  /// No description provided for @libraryQuickNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick note - {date}'**
  String libraryQuickNoteTitle(String date);

  /// No description provided for @libraryWhiteboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Whiteboard - {date}'**
  String libraryWhiteboardTitle(String date);

  /// No description provided for @libraryPdfReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the PDF file'**
  String get libraryPdfReadFailed;

  /// No description provided for @libraryImageReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the image file'**
  String get libraryImageReadFailed;

  /// No description provided for @libraryImageLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading image...'**
  String get libraryImageLoading;

  /// No description provided for @libraryImageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Image is too large. Maximum size: 4096x4096'**
  String get libraryImageTooLarge;

  /// No description provided for @libraryPdfTooLarge.
  ///
  /// In en, this message translates to:
  /// **'PDF is too large. Maximum size: 200 MB'**
  String get libraryPdfTooLarge;

  /// No description provided for @libraryPdfOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening PDF...'**
  String get libraryPdfOpening;

  /// No description provided for @libraryPdfImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t import the PDF'**
  String get libraryPdfImportFailed;

  /// No description provided for @libraryOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening {title}'**
  String libraryOpening(String title);

  /// No description provided for @libraryOpeningWithPages.
  ///
  /// In en, this message translates to:
  /// **'Opening {title} ({pages})'**
  String libraryOpeningWithPages(String title, String pages);

  /// No description provided for @libraryFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get libraryFormat;

  /// No description provided for @libraryOrientation.
  ///
  /// In en, this message translates to:
  /// **'Orientation'**
  String get libraryOrientation;

  /// No description provided for @libraryPortrait.
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get libraryPortrait;

  /// No description provided for @libraryLandscape.
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get libraryLandscape;

  /// No description provided for @librarySize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get librarySize;

  /// No description provided for @libraryFormatSummary.
  ///
  /// In en, this message translates to:
  /// **'{orientation}, {size}'**
  String libraryFormatSummary(String orientation, String size);

  /// No description provided for @libraryCover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get libraryCover;

  /// No description provided for @libraryPaper.
  ///
  /// In en, this message translates to:
  /// **'Paper'**
  String get libraryPaper;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get libraryTitle;

  /// No description provided for @libraryNoteTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Note title'**
  String get libraryNoteTitleHint;

  /// No description provided for @libraryTemplateCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get libraryTemplateCategoryAll;

  /// No description provided for @libraryNoTemplatesInCategory.
  ///
  /// In en, this message translates to:
  /// **'No templates in this category'**
  String get libraryNoTemplatesInCategory;

  /// No description provided for @libraryCreateNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Create new note'**
  String get libraryCreateNoteTitle;

  /// No description provided for @libraryTemplate.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get libraryTemplate;

  /// No description provided for @libraryUntitledNote.
  ///
  /// In en, this message translates to:
  /// **'Untitled note'**
  String get libraryUntitledNote;

  /// No description provided for @libraryPaperColorWhite.
  ///
  /// In en, this message translates to:
  /// **'White paper'**
  String get libraryPaperColorWhite;

  /// No description provided for @libraryPaperColorBlack.
  ///
  /// In en, this message translates to:
  /// **'Black paper'**
  String get libraryPaperColorBlack;

  /// No description provided for @libraryPaperColorCream.
  ///
  /// In en, this message translates to:
  /// **'Cream paper'**
  String get libraryPaperColorCream;

  /// No description provided for @libraryPaperColorGray.
  ///
  /// In en, this message translates to:
  /// **'Gray paper'**
  String get libraryPaperColorGray;

  /// No description provided for @libraryPaperColorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green paper'**
  String get libraryPaperColorGreen;

  /// No description provided for @libraryPaperColorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue paper'**
  String get libraryPaperColorBlue;

  /// No description provided for @libraryPaperColorYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow paper'**
  String get libraryPaperColorYellow;

  /// No description provided for @librarySelectColor.
  ///
  /// In en, this message translates to:
  /// **'Choose a color'**
  String get librarySelectColor;

  /// No description provided for @editorPageRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get editorPageRename;

  /// No description provided for @editorPageMoveDocumentToTrash.
  ///
  /// In en, this message translates to:
  /// **'Move to trash'**
  String get editorPageMoveDocumentToTrash;

  /// No description provided for @editorPageDocumentOptions.
  ///
  /// In en, this message translates to:
  /// **'Document options'**
  String get editorPageDocumentOptions;

  /// No description provided for @editorPagePageNumber.
  ///
  /// In en, this message translates to:
  /// **'Page {number}'**
  String editorPagePageNumber(int number);

  /// No description provided for @editorPageBookmarkPage.
  ///
  /// In en, this message translates to:
  /// **'Bookmark page'**
  String get editorPageBookmarkPage;

  /// No description provided for @editorPageRemoveBookmark.
  ///
  /// In en, this message translates to:
  /// **'Remove bookmark'**
  String get editorPageRemoveBookmark;

  /// No description provided for @editorPageCopyPage.
  ///
  /// In en, this message translates to:
  /// **'Copy page'**
  String get editorPageCopyPage;

  /// No description provided for @editorPagePastePage.
  ///
  /// In en, this message translates to:
  /// **'Paste page'**
  String get editorPagePastePage;

  /// No description provided for @editorPageDuplicatePage.
  ///
  /// In en, this message translates to:
  /// **'Duplicate page'**
  String get editorPageDuplicatePage;

  /// No description provided for @editorPageChangeTemplate.
  ///
  /// In en, this message translates to:
  /// **'Change template'**
  String get editorPageChangeTemplate;

  /// No description provided for @editorPageGoToPageMenu.
  ///
  /// In en, this message translates to:
  /// **'Go to page'**
  String get editorPageGoToPageMenu;

  /// No description provided for @editorPageExportPagePdf.
  ///
  /// In en, this message translates to:
  /// **'Export page as PDF'**
  String get editorPageExportPagePdf;

  /// No description provided for @editorPageClearPageMenu.
  ///
  /// In en, this message translates to:
  /// **'Clear page'**
  String get editorPageClearPageMenu;

  /// No description provided for @editorPageMovePageToTrash.
  ///
  /// In en, this message translates to:
  /// **'Move to trash'**
  String get editorPageMovePageToTrash;

  /// No description provided for @editorPageSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get editorPageSettings;

  /// No description provided for @editorPageEditToolbar.
  ///
  /// In en, this message translates to:
  /// **'Edit toolbar'**
  String get editorPageEditToolbar;

  /// No description provided for @editorPageScrollDirection.
  ///
  /// In en, this message translates to:
  /// **'Scroll direction'**
  String get editorPageScrollDirection;

  /// No description provided for @editorPageScrollHorizontal.
  ///
  /// In en, this message translates to:
  /// **'Horizontal'**
  String get editorPageScrollHorizontal;

  /// No description provided for @editorPageScrollVertical.
  ///
  /// In en, this message translates to:
  /// **'Vertical'**
  String get editorPageScrollVertical;

  /// No description provided for @editorPagePageCopied.
  ///
  /// In en, this message translates to:
  /// **'Page copied'**
  String get editorPagePageCopied;

  /// No description provided for @editorPagePagePasted.
  ///
  /// In en, this message translates to:
  /// **'Page pasted'**
  String get editorPagePagePasted;

  /// No description provided for @editorPagePageDuplicated.
  ///
  /// In en, this message translates to:
  /// **'Page duplicated'**
  String get editorPagePageDuplicated;

  /// No description provided for @editorPageLastPageCannotDelete.
  ///
  /// In en, this message translates to:
  /// **'The last page can\'t be deleted'**
  String get editorPageLastPageCannotDelete;

  /// No description provided for @editorPagePageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Page deleted'**
  String get editorPagePageDeleted;

  /// No description provided for @editorPageClearPageQuestion.
  ///
  /// In en, this message translates to:
  /// **'Clear page {page}?\nYou can undo this.'**
  String editorPageClearPageQuestion(int page);

  /// No description provided for @editorPagePageAdded.
  ///
  /// In en, this message translates to:
  /// **'Page added'**
  String get editorPagePageAdded;

  /// No description provided for @editorPagePageMoved.
  ///
  /// In en, this message translates to:
  /// **'Page moved'**
  String get editorPagePageMoved;

  /// No description provided for @editorPageGoToPage.
  ///
  /// In en, this message translates to:
  /// **'Go to page'**
  String get editorPageGoToPage;

  /// No description provided for @editorPageGo.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get editorPageGo;

  /// No description provided for @editorPageListPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {count}'**
  String editorPageListPageOf(int page, int count);

  /// No description provided for @editorPageListPageRangeOf.
  ///
  /// In en, this message translates to:
  /// **'Pages {first}–{last} of {count}'**
  String editorPageListPageRangeOf(int first, int last, int count);

  /// No description provided for @editorPageListPreviousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get editorPageListPreviousPage;

  /// No description provided for @editorPageListNextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get editorPageListNextPage;

  /// No description provided for @editorPageListGoToPageHint.
  ///
  /// In en, this message translates to:
  /// **'{pageLabel}, tap to go to a page'**
  String editorPageListGoToPageHint(String pageLabel);

  /// No description provided for @editorPageListAddPage.
  ///
  /// In en, this message translates to:
  /// **'Add page'**
  String get editorPageListAddPage;

  /// No description provided for @editorPageListAddBookmark.
  ///
  /// In en, this message translates to:
  /// **'Add bookmark'**
  String get editorPageListAddBookmark;

  /// No description provided for @editorPageListNoBookmarks.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet'**
  String get editorPageListNoBookmarks;

  /// No description provided for @editorPageListNoBookmarksHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the bookmark icon on a thumbnail to bookmark that page.'**
  String get editorPageListNoBookmarksHint;

  /// No description provided for @editorPageListFilterAllPages.
  ///
  /// In en, this message translates to:
  /// **'All pages'**
  String get editorPageListFilterAllPages;

  /// No description provided for @editorPageListFilterBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get editorPageListFilterBookmarks;

  /// No description provided for @editorPageListFilterRecordings.
  ///
  /// In en, this message translates to:
  /// **'Recordings'**
  String get editorPageListFilterRecordings;

  /// No description provided for @editorPageListPageOptions.
  ///
  /// In en, this message translates to:
  /// **'Page options'**
  String get editorPageListPageOptions;

  /// No description provided for @editorPageListThumbnailFailed.
  ///
  /// In en, this message translates to:
  /// **'Preview\nunavailable'**
  String get editorPageListThumbnailFailed;

  /// No description provided for @editorPageListDropToAddPage.
  ///
  /// In en, this message translates to:
  /// **'Drag and drop\nto add a new page'**
  String get editorPageListDropToAddPage;

  /// No description provided for @editorPageListPositionBefore.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get editorPageListPositionBefore;

  /// No description provided for @editorPageListPositionAfter.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get editorPageListPositionAfter;

  /// No description provided for @editorPageListLastPage.
  ///
  /// In en, this message translates to:
  /// **'Last page'**
  String get editorPageListLastPage;

  /// No description provided for @editorPageListMoreTemplates.
  ///
  /// In en, this message translates to:
  /// **'More templates'**
  String get editorPageListMoreTemplates;

  /// No description provided for @editorPageListTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get editorPageListTakePhoto;

  /// No description provided for @editorPageListImportFile.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get editorPageListImportFile;

  /// No description provided for @editorExportScopeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get editorExportScopeAll;

  /// No description provided for @editorExportScopeCurrent.
  ///
  /// In en, this message translates to:
  /// **'This page'**
  String get editorExportScopeCurrent;

  /// No description provided for @editorExportScopeRange.
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get editorExportScopeRange;

  /// No description provided for @editorExportFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get editorExportFrom;

  /// No description provided for @editorExportTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get editorExportTo;

  /// No description provided for @editorExportIncludeTemplate.
  ///
  /// In en, this message translates to:
  /// **'Include page template'**
  String get editorExportIncludeTemplate;

  /// No description provided for @editorExportExportPng.
  ///
  /// In en, this message translates to:
  /// **'Export as PNG'**
  String get editorExportExportPng;

  /// No description provided for @editorExportExportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get editorExportExportPdf;

  /// No description provided for @editorExportSharePdf.
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get editorExportSharePdf;

  /// No description provided for @editorExportInvalidRange.
  ///
  /// In en, this message translates to:
  /// **'The page range must be between 1 and {count}.'**
  String editorExportInvalidRange(int count);

  /// No description provided for @editorExportSavePdfDialog.
  ///
  /// In en, this message translates to:
  /// **'Save PDF'**
  String get editorExportSavePdfDialog;

  /// No description provided for @editorExportSavePngDialog.
  ///
  /// In en, this message translates to:
  /// **'Save PNG'**
  String get editorExportSavePngDialog;

  /// No description provided for @editorExportFallbackFileName.
  ///
  /// In en, this message translates to:
  /// **'document'**
  String get editorExportFallbackFileName;

  /// No description provided for @editorExportPageFileName.
  ///
  /// In en, this message translates to:
  /// **'{title}_page{page}'**
  String editorExportPageFileName(String title, int page);

  /// No description provided for @editorExportExporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting PDF…'**
  String get editorExportExporting;

  /// No description provided for @editorExportPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String editorExportPercent(int percent);

  /// No description provided for @editorExportRemainingSeconds.
  ///
  /// In en, this message translates to:
  /// **'~{seconds} s'**
  String editorExportRemainingSeconds(int seconds);

  /// No description provided for @editorExportRemainingMinutes.
  ///
  /// In en, this message translates to:
  /// **'~{minutes} min'**
  String editorExportRemainingMinutes(int minutes);

  /// No description provided for @editorExportSaved.
  ///
  /// In en, this message translates to:
  /// **'PDF saved'**
  String get editorExportSaved;

  /// No description provided for @editorExportSavedWithSize.
  ///
  /// In en, this message translates to:
  /// **'PDF saved ({size})'**
  String editorExportSavedWithSize(String size);

  /// No description provided for @editorExportCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get editorExportCancelled;

  /// No description provided for @editorExportPagesWithoutPdfBackground.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 page was exported without its PDF background} other{{count} pages were exported without their PDF background}}'**
  String editorExportPagesWithoutPdfBackground(int count);

  /// No description provided for @editorTemplateAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get editorTemplateAllCategories;

  /// No description provided for @editorTemplateCoverTab.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get editorTemplateCoverTab;

  /// No description provided for @editorTemplatePaperTab.
  ///
  /// In en, this message translates to:
  /// **'Paper'**
  String get editorTemplatePaperTab;

  /// No description provided for @editorTemplateApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get editorTemplateApply;

  /// No description provided for @editorTemplatePortrait.
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get editorTemplatePortrait;

  /// No description provided for @editorTemplateLandscape.
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get editorTemplateLandscape;

  /// No description provided for @editorTemplatePaperSquare.
  ///
  /// In en, this message translates to:
  /// **'Square'**
  String get editorTemplatePaperSquare;

  /// No description provided for @editorTemplatePaperWidescreen.
  ///
  /// In en, this message translates to:
  /// **'Widescreen (16:9)'**
  String get editorTemplatePaperWidescreen;

  /// No description provided for @editorTemplateCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get editorTemplateCustom;

  /// No description provided for @editorTemplateColorWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get editorTemplateColorWhite;

  /// No description provided for @editorTemplateColorCream.
  ///
  /// In en, this message translates to:
  /// **'Cream'**
  String get editorTemplateColorCream;

  /// No description provided for @editorTemplateColorBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get editorTemplateColorBlack;

  /// No description provided for @editorTemplateColorYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get editorTemplateColorYellow;

  /// No description provided for @editorTemplateTemplatesHeader.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get editorTemplateTemplatesHeader;

  /// No description provided for @editorTemplateBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get editorTemplateBackground;

  /// No description provided for @editorTemplateBackgroundPattern.
  ///
  /// In en, this message translates to:
  /// **'Background pattern'**
  String get editorTemplateBackgroundPattern;

  /// No description provided for @editorTemplatePatternPlain.
  ///
  /// In en, this message translates to:
  /// **'Plain'**
  String get editorTemplatePatternPlain;

  /// No description provided for @editorTemplatePatternDotted.
  ///
  /// In en, this message translates to:
  /// **'Dotted'**
  String get editorTemplatePatternDotted;

  /// No description provided for @editorTemplatePatternGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get editorTemplatePatternGrid;

  /// No description provided for @editorTemplateBackgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Background color'**
  String get editorTemplateBackgroundColor;

  /// No description provided for @editorCoverSolidNavy.
  ///
  /// In en, this message translates to:
  /// **'Navy'**
  String get editorCoverSolidNavy;

  /// No description provided for @editorCoverSolidBurgundy.
  ///
  /// In en, this message translates to:
  /// **'Burgundy'**
  String get editorCoverSolidBurgundy;

  /// No description provided for @editorCoverMinimalGray.
  ///
  /// In en, this message translates to:
  /// **'Gray Frame'**
  String get editorCoverMinimalGray;

  /// No description provided for @editorCoverPatternDots.
  ///
  /// In en, this message translates to:
  /// **'Dotted'**
  String get editorCoverPatternDots;

  /// No description provided for @editorCoverPatternLines.
  ///
  /// In en, this message translates to:
  /// **'Lined'**
  String get editorCoverPatternLines;

  /// No description provided for @editorCoverGradientSunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get editorCoverGradientSunset;

  /// No description provided for @editorCoverGradientOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get editorCoverGradientOcean;

  /// No description provided for @editorCoverGradientForest.
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get editorCoverGradientForest;

  /// No description provided for @editorCoverGradientPurple.
  ///
  /// In en, this message translates to:
  /// **'Lavender'**
  String get editorCoverGradientPurple;

  /// No description provided for @editorCoverImgKraft.
  ///
  /// In en, this message translates to:
  /// **'Kraft'**
  String get editorCoverImgKraft;

  /// No description provided for @editorCoverImgGeometric.
  ///
  /// In en, this message translates to:
  /// **'Geometric'**
  String get editorCoverImgGeometric;

  /// No description provided for @editorCoverImgTerrazzo.
  ///
  /// In en, this message translates to:
  /// **'Terrazzo'**
  String get editorCoverImgTerrazzo;

  /// No description provided for @editorCoverImgDinosaur.
  ///
  /// In en, this message translates to:
  /// **'Dinosaur'**
  String get editorCoverImgDinosaur;

  /// No description provided for @editorCoverImgSpace.
  ///
  /// In en, this message translates to:
  /// **'Space'**
  String get editorCoverImgSpace;

  /// No description provided for @editorCoverImgFloral.
  ///
  /// In en, this message translates to:
  /// **'Floral'**
  String get editorCoverImgFloral;

  /// No description provided for @editorCoverImgNavyGold.
  ///
  /// In en, this message translates to:
  /// **'Navy Gold'**
  String get editorCoverImgNavyGold;

  /// No description provided for @editorCoverImgLeather.
  ///
  /// In en, this message translates to:
  /// **'Leather'**
  String get editorCoverImgLeather;

  /// No description provided for @editorCoverLinenSage.
  ///
  /// In en, this message translates to:
  /// **'Sage Linen'**
  String get editorCoverLinenSage;

  /// No description provided for @editorCoverLinenSand.
  ///
  /// In en, this message translates to:
  /// **'Sand Linen'**
  String get editorCoverLinenSand;

  /// No description provided for @editorCoverLinenSlate.
  ///
  /// In en, this message translates to:
  /// **'Slate Linen'**
  String get editorCoverLinenSlate;

  /// No description provided for @editorCoverLeatherOxblood.
  ///
  /// In en, this message translates to:
  /// **'Oxblood Leather'**
  String get editorCoverLeatherOxblood;

  /// No description provided for @editorCoverLeatherCognac.
  ///
  /// In en, this message translates to:
  /// **'Cognac Leather'**
  String get editorCoverLeatherCognac;

  /// No description provided for @editorCoverLeatherNavy.
  ///
  /// In en, this message translates to:
  /// **'Navy Leather'**
  String get editorCoverLeatherNavy;

  /// No description provided for @editorCoverKraftNatural.
  ///
  /// In en, this message translates to:
  /// **'Natural Kraft'**
  String get editorCoverKraftNatural;

  /// No description provided for @editorCoverKraftCharcoal.
  ///
  /// In en, this message translates to:
  /// **'Charcoal Kraft'**
  String get editorCoverKraftCharcoal;

  /// No description provided for @editorCoverFeltMustard.
  ///
  /// In en, this message translates to:
  /// **'Mustard Felt'**
  String get editorCoverFeltMustard;

  /// No description provided for @editorCoverFeltDustyRose.
  ///
  /// In en, this message translates to:
  /// **'Dusty Rose Felt'**
  String get editorCoverFeltDustyRose;

  /// No description provided for @editorErrorExportStorageFull.
  ///
  /// In en, this message translates to:
  /// **'Not enough storage to export. Free up space and try again.'**
  String get editorErrorExportStorageFull;

  /// No description provided for @editorErrorExportCannotWrite.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t write the file. Try again.'**
  String get editorErrorExportCannotWrite;

  /// No description provided for @editorErrorExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed. Try again.'**
  String get editorErrorExportFailed;

  /// No description provided for @editorErrorExportNoPages.
  ///
  /// In en, this message translates to:
  /// **'There are no pages to export'**
  String get editorErrorExportNoPages;

  /// No description provided for @editorErrorPdfPasswordProtected.
  ///
  /// In en, this message translates to:
  /// **'This PDF is password-protected. Remove the password and try again.'**
  String get editorErrorPdfPasswordProtected;

  /// No description provided for @editorErrorPdfFileAccess.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t access the PDF file.'**
  String get editorErrorPdfFileAccess;

  /// No description provided for @editorErrorPdfStorageFull.
  ///
  /// In en, this message translates to:
  /// **'Not enough storage to import the PDF. Free up space and try again.'**
  String get editorErrorPdfStorageFull;

  /// No description provided for @editorErrorPdfOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the PDF. The file may be damaged.'**
  String get editorErrorPdfOpenFailed;

  /// No description provided for @editorErrorPdfPagesUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the PDF pages. The file may be damaged.'**
  String get editorErrorPdfPagesUnreadable;

  /// No description provided for @editorErrorPdfTooManyPages.
  ///
  /// In en, this message translates to:
  /// **'This PDF has too many pages ({count}). Up to {max} pages are supported.'**
  String editorErrorPdfTooManyPages(int count, int max);

  /// No description provided for @editorErrorPdfPagePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'PDF page'**
  String get editorErrorPdfPagePlaceholder;

  /// No description provided for @editorErrorPdfSourceMissing.
  ///
  /// In en, this message translates to:
  /// **'Source PDF not found'**
  String get editorErrorPdfSourceMissing;

  /// No description provided for @editorErrorPdfLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load PDF'**
  String get editorErrorPdfLoadFailed;

  /// No description provided for @editorErrorPdfPagesSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 page could not be read and was skipped} other{{count} pages could not be read and were skipped}}'**
  String editorErrorPdfPagesSkipped(int count);

  /// No description provided for @editorCanvasAddLayer.
  ///
  /// In en, this message translates to:
  /// **'Add layer'**
  String get editorCanvasAddLayer;

  /// No description provided for @editorCanvasDefaultLayerName.
  ///
  /// In en, this message translates to:
  /// **'Layer {number}'**
  String editorCanvasDefaultLayerName(int number);

  /// No description provided for @editorCanvasDeleteLayer.
  ///
  /// In en, this message translates to:
  /// **'Delete layer'**
  String get editorCanvasDeleteLayer;

  /// No description provided for @editorCanvasDuplicateLayer.
  ///
  /// In en, this message translates to:
  /// **'Duplicate layer'**
  String get editorCanvasDuplicateLayer;

  /// No description provided for @editorCanvasHideLayer.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get editorCanvasHideLayer;

  /// No description provided for @editorCanvasShowLayer.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get editorCanvasShowLayer;

  /// No description provided for @editorCanvasLockLayer.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get editorCanvasLockLayer;

  /// No description provided for @editorCanvasUnlockLayer.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get editorCanvasUnlockLayer;

  /// No description provided for @editorCanvasZoomLock.
  ///
  /// In en, this message translates to:
  /// **'Zoom lock'**
  String get editorCanvasZoomLock;

  /// No description provided for @editorCanvasZoomLevel.
  ///
  /// In en, this message translates to:
  /// **'Zoom {percent}%, favorite levels'**
  String editorCanvasZoomLevel(int percent);

  /// No description provided for @editorCanvasFavoriteZoom.
  ///
  /// In en, this message translates to:
  /// **'Favorite zoom'**
  String get editorCanvasFavoriteZoom;

  /// No description provided for @editorCanvasPenBox.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Pen box, 1 pen} other{Pen box, {count} pens}}'**
  String editorCanvasPenBox(int count);

  /// No description provided for @editorCanvasFinishEditing.
  ///
  /// In en, this message translates to:
  /// **'Done editing'**
  String get editorCanvasFinishEditing;

  /// No description provided for @editorCanvasEditPenBox.
  ///
  /// In en, this message translates to:
  /// **'Edit pen box'**
  String get editorCanvasEditPenBox;

  /// No description provided for @editorCanvasCollapsePenBox.
  ///
  /// In en, this message translates to:
  /// **'Collapse pen box'**
  String get editorCanvasCollapsePenBox;

  /// No description provided for @editorCanvasRemovePen.
  ///
  /// In en, this message translates to:
  /// **'Remove pen'**
  String get editorCanvasRemovePen;

  /// No description provided for @editorCanvasAddImage.
  ///
  /// In en, this message translates to:
  /// **'Add image'**
  String get editorCanvasAddImage;

  /// No description provided for @editorCanvasAddImageHint.
  ///
  /// In en, this message translates to:
  /// **'Add an image from the gallery or camera'**
  String get editorCanvasAddImageHint;

  /// No description provided for @editorCanvasFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get editorCanvasFromGallery;

  /// No description provided for @editorCanvasFromGalleryHint.
  ///
  /// In en, this message translates to:
  /// **'Pick an image from your albums'**
  String get editorCanvasFromGalleryHint;

  /// No description provided for @editorCanvasTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get editorCanvasTakePhoto;

  /// No description provided for @editorCanvasTakePhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Take a new photo with the camera'**
  String get editorCanvasTakePhotoHint;

  /// No description provided for @editorCanvasTapToPlace.
  ///
  /// In en, this message translates to:
  /// **'Tap to place'**
  String get editorCanvasTapToPlace;

  /// No description provided for @editorCanvasTapToPlaceImage.
  ///
  /// In en, this message translates to:
  /// **'Tap to place the image'**
  String get editorCanvasTapToPlaceImage;

  /// No description provided for @editorCanvasAddColor.
  ///
  /// In en, this message translates to:
  /// **'Add color'**
  String get editorCanvasAddColor;

  /// No description provided for @editorCanvasTextStyleTitle.
  ///
  /// In en, this message translates to:
  /// **'Text style'**
  String get editorCanvasTextStyleTitle;

  /// No description provided for @editorCanvasEmojiSize.
  ///
  /// In en, this message translates to:
  /// **'Emoji size'**
  String get editorCanvasEmojiSize;

  /// No description provided for @editorCanvasTextPreviewSample.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get editorCanvasTextPreviewSample;

  /// No description provided for @libraryManageFolders.
  ///
  /// In en, this message translates to:
  /// **'Manage folders'**
  String get libraryManageFolders;

  /// No description provided for @libraryNoFoldersYet.
  ///
  /// In en, this message translates to:
  /// **'No folders yet'**
  String get libraryNoFoldersYet;

  /// No description provided for @libraryNoFoldersHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to create a folder'**
  String get libraryNoFoldersHint;

  /// No description provided for @libraryNoFoldersStartHint.
  ///
  /// In en, this message translates to:
  /// **'Create a folder to get started'**
  String get libraryNoFoldersStartHint;

  /// No description provided for @libraryFolderOrderSaved.
  ///
  /// In en, this message translates to:
  /// **'Order saved'**
  String get libraryFolderOrderSaved;

  /// No description provided for @libraryAddSubfolder.
  ///
  /// In en, this message translates to:
  /// **'Add subfolder'**
  String get libraryAddSubfolder;

  /// No description provided for @libraryAddSubfolderTitle.
  ///
  /// In en, this message translates to:
  /// **'New folder in {parent}'**
  String libraryAddSubfolderTitle(String parent);

  /// No description provided for @libraryDeleteFolderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete the folder \"{name}\"?\nIts notes will be moved to the trash.'**
  String libraryDeleteFolderConfirm(String name);

  /// No description provided for @libraryFolderManagement.
  ///
  /// In en, this message translates to:
  /// **'Folder management'**
  String get libraryFolderManagement;

  /// No description provided for @libraryMoveFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Move folder'**
  String get libraryMoveFolderTitle;

  /// No description provided for @libraryMoveToFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Move to folder'**
  String get libraryMoveToFolderTitle;

  /// No description provided for @libraryFoldersLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load folders'**
  String get libraryFoldersLoadFailed;

  /// No description provided for @libraryFolderNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Folder name can\'t be empty'**
  String get libraryFolderNameEmpty;

  /// No description provided for @libraryFolderCreated.
  ///
  /// In en, this message translates to:
  /// **'Folder \"{name}\" created'**
  String libraryFolderCreated(String name);

  /// No description provided for @libraryRootFolders.
  ///
  /// In en, this message translates to:
  /// **'Top-level folders'**
  String get libraryRootFolders;

  /// No description provided for @libraryNoFolderRoot.
  ///
  /// In en, this message translates to:
  /// **'Documents (no folder)'**
  String get libraryNoFolderRoot;

  /// No description provided for @libraryFolderNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a folder name'**
  String get libraryFolderNameHint;

  /// No description provided for @libraryColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get libraryColor;

  /// No description provided for @libraryFolderColorEmerald.
  ///
  /// In en, this message translates to:
  /// **'Emerald'**
  String get libraryFolderColorEmerald;

  /// No description provided for @libraryFolderColorPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get libraryFolderColorPurple;

  /// No description provided for @libraryFolderColorPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get libraryFolderColorPink;

  /// No description provided for @libraryFolderColorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get libraryFolderColorRed;

  /// No description provided for @libraryFolderColorOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get libraryFolderColorOrange;

  /// No description provided for @libraryFolderColorAmber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get libraryFolderColorAmber;

  /// No description provided for @libraryFolderColorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get libraryFolderColorGreen;

  /// No description provided for @libraryFolderColorTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get libraryFolderColorTeal;

  /// No description provided for @libraryFolderColorCyan.
  ///
  /// In en, this message translates to:
  /// **'Cyan'**
  String get libraryFolderColorCyan;

  /// No description provided for @libraryFolderColorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get libraryFolderColorBlue;

  /// No description provided for @libraryFolderColorGray.
  ///
  /// In en, this message translates to:
  /// **'Gray'**
  String get libraryFolderColorGray;

  /// No description provided for @libraryFolderColorStone.
  ///
  /// In en, this message translates to:
  /// **'Stone'**
  String get libraryFolderColorStone;
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
