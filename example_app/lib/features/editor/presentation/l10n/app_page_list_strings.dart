import 'package:drawing_ui/drawing_ui.dart';
import 'package:example_app/l10n/l10n.dart';

/// [PageListStrings] backed by the generated [AppLocalizations].
class AppPageListStrings extends PageListStrings {
  const AppPageListStrings(this._l10n);

  final AppLocalizations _l10n;

  @override
  String pageOf(int page, int count) => _l10n.editorPageListPageOf(page, count);

  @override
  String pageRangeOf(int first, int last, int count) =>
      _l10n.editorPageListPageRangeOf(first, last, count);

  @override
  String get previousPage => _l10n.editorPageListPreviousPage;

  @override
  String get nextPage => _l10n.editorPageListNextPage;

  @override
  String goToPageHint(String pageLabel) =>
      _l10n.editorPageListGoToPageHint(pageLabel);

  @override
  String get addPage => _l10n.editorPageListAddPage;

  @override
  String get addBookmark => _l10n.editorPageListAddBookmark;

  @override
  String get noBookmarks => _l10n.editorPageListNoBookmarks;

  @override
  String get noBookmarksHint => _l10n.editorPageListNoBookmarksHint;

  @override
  String get filterAllPages => _l10n.editorPageListFilterAllPages;

  @override
  String get filterBookmarks => _l10n.editorPageListFilterBookmarks;

  @override
  String get filterRecordings => _l10n.editorPageListFilterRecordings;

  @override
  String get pageOptions => _l10n.editorPageListPageOptions;

  @override
  String get thumbnailFailed => _l10n.editorPageListThumbnailFailed;

  @override
  String get dropToAddPage => _l10n.editorPageListDropToAddPage;

  @override
  String get positionBefore => _l10n.editorPageListPositionBefore;

  @override
  String get positionAfter => _l10n.editorPageListPositionAfter;

  @override
  String get lastPage => _l10n.editorPageListLastPage;

  @override
  String get moreTemplates => _l10n.editorPageListMoreTemplates;

  @override
  String get takePhoto => _l10n.editorPageListTakePhoto;

  @override
  String get importFile => _l10n.editorPageListImportFile;
}
