import 'package:drawing_ui/drawing_ui.dart';
import 'package:example_app/l10n/l10n.dart';

/// [PageStrings] backed by the generated [AppLocalizations].
class AppPageStrings extends PageStrings {
  const AppPageStrings(this._l10n);

  final AppLocalizations _l10n;

  @override
  String get rename => _l10n.editorPageRename;

  @override
  String get moveDocumentToTrash => _l10n.editorPageMoveDocumentToTrash;

  @override
  String get documentOptions => _l10n.editorPageDocumentOptions;

  @override
  String pageNumber(int number) => _l10n.editorPagePageNumber(number);

  @override
  String get bookmarkPage => _l10n.editorPageBookmarkPage;

  @override
  String get removeBookmark => _l10n.editorPageRemoveBookmark;

  @override
  String get copyPage => _l10n.editorPageCopyPage;

  @override
  String get pastePage => _l10n.editorPagePastePage;

  @override
  String get duplicatePage => _l10n.editorPageDuplicatePage;

  @override
  String get changeTemplate => _l10n.editorPageChangeTemplate;

  @override
  String get goToPageMenu => _l10n.editorPageGoToPageMenu;

  @override
  String get exportPagePdf => _l10n.editorPageExportPagePdf;

  @override
  String get clearPageMenu => _l10n.editorPageClearPageMenu;

  @override
  String get movePageToTrash => _l10n.editorPageMovePageToTrash;

  @override
  String get settings => _l10n.editorPageSettings;

  @override
  String get editToolbar => _l10n.editorPageEditToolbar;

  @override
  String get scrollDirection => _l10n.editorPageScrollDirection;

  @override
  String get scrollHorizontal => _l10n.editorPageScrollHorizontal;

  @override
  String get scrollVertical => _l10n.editorPageScrollVertical;

  @override
  String get pageCopied => _l10n.editorPagePageCopied;

  @override
  String get pagePasted => _l10n.editorPagePagePasted;

  @override
  String get pasteFilesMissing => _l10n.editorPagePasteFilesMissing;

  @override
  String get pageDuplicated => _l10n.editorPagePageDuplicated;

  @override
  String get lastPageCannotDelete => _l10n.editorPageLastPageCannotDelete;

  @override
  String get pageDeleted => _l10n.editorPagePageDeleted;

  @override
  String clearPageQuestion(int page) => _l10n.editorPageClearPageQuestion(page);

  @override
  String get pageAdded => _l10n.editorPagePageAdded;

  @override
  String get pageMoved => _l10n.editorPagePageMoved;

  @override
  String get cannotUndo => _l10n.editorPageCannotUndo;

  @override
  String get backgroundReplaced => _l10n.editorPageBackgroundReplaced;

  @override
  String get goToPage => _l10n.editorPageGoToPage;

  @override
  String get go => _l10n.editorPageGo;
}
