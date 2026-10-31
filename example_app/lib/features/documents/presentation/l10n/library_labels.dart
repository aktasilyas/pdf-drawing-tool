/// Localized labels for library enums. Domain and providers only know the
/// enums; every user-facing string resolves here through [AppLocalizations].
library;

import 'package:drawing_core/drawing_core.dart';
import 'package:example_app/features/documents/domain/entities/library_rule.dart';
import 'package:example_app/features/documents/domain/entities/paper_color.dart';
import 'package:example_app/features/documents/domain/entities/sort_option.dart';
import 'package:example_app/features/documents/presentation/providers/library_error.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_sidebar.dart';
import 'package:example_app/features/documents/presentation/widgets/new_document_dialog.dart';
import 'package:example_app/l10n/l10n.dart';

/// Picks the Turkish or English variant of drawing_core content that ships
/// both (`TemplateCategory.displayName`/`displayNameEn`, `Template.name`/
/// `nameEn`), following the active locale.
String localizedName(
  AppLocalizations l10n, {
  required String tr,
  required String en,
}) =>
    l10n.localeName.startsWith('tr') ? tr : en;

extension LibraryActionL10n on LibraryAction {
  /// Message for a failed [LibraryAction] (storage or unexpected errors).
  String failureMessage(AppLocalizations l) => switch (this) {
        LibraryAction.createDocument => l.libraryErrorCreateDocument,
        LibraryAction.importDocument => l.libraryErrorImportDocument,
        LibraryAction.moveDocument => l.libraryErrorMoveDocument,
        LibraryAction.toggleFavorite => l.libraryErrorToggleFavorite,
        LibraryAction.trashDocument => l.libraryErrorTrashDocument,
        LibraryAction.deleteDocument => l.libraryErrorDeleteDocument,
        LibraryAction.renameDocument => l.libraryErrorRenameDocument,
        LibraryAction.restoreDocument => l.libraryErrorRestoreDocument,
        LibraryAction.duplicateDocument => l.libraryErrorDuplicateDocument,
        LibraryAction.deleteDocumentForever =>
          l.libraryErrorDeleteDocumentForever,
        LibraryAction.trashDocuments => l.libraryErrorTrashDocuments,
        LibraryAction.deleteDocumentsForever =>
          l.libraryErrorDeleteDocumentsForever,
        LibraryAction.duplicateDocuments => l.libraryErrorDuplicateDocuments,
        LibraryAction.moveDocuments => l.libraryErrorMoveDocuments,
        LibraryAction.trashPage => l.libraryErrorTrashPage,
        LibraryAction.deletePageForever => l.libraryErrorDeletePageForever,
        LibraryAction.emptyTrash => l.libraryErrorEmptyTrash,
        LibraryAction.createFolder => l.libraryErrorCreateFolder,
        LibraryAction.renameFolder => l.libraryErrorRenameFolder,
        LibraryAction.recolorFolder => l.libraryErrorRecolorFolder,
        LibraryAction.saveFolderOrder => l.libraryErrorSaveFolderOrder,
        LibraryAction.moveFolder => l.libraryErrorMoveFolder,
        LibraryAction.deleteFolder => l.libraryErrorDeleteFolder,
        LibraryAction.exportDocument => l.libraryErrorExportDocument,
        LibraryAction.changeCover => l.libraryErrorChangeCover,
      };
}

extension LibraryRuleL10n on LibraryRule {
  /// User-facing explanation of a violated [LibraryRule].
  String message(AppLocalizations l) => switch (this) {
        LibraryRule.folderDepth => l.libraryRuleFolderDepth,
        LibraryRule.folderIntoOwnSubfolder =>
          l.libraryRuleFolderIntoOwnSubfolder,
        LibraryRule.folderMoveDepth => l.libraryRuleFolderMoveDepth,
        LibraryRule.folderWithSubfoldersMove =>
          l.libraryRuleFolderWithSubfoldersMove,
        LibraryRule.documentLimit => l.libraryRuleDocumentLimit,
        LibraryRule.folderLimit => l.libraryRuleFolderLimit,
      };
}

extension SortOptionL10n on SortOption {
  String label(AppLocalizations l) => switch (this) {
        SortOption.date => l.librarySortByDate,
        SortOption.name => l.librarySortByName,
        SortOption.size => l.librarySortBySize,
      };
}

extension PaperSizePresetL10n on PaperSizePreset {
  String label(AppLocalizations l) => switch (this) {
        PaperSizePreset.a4 => 'A4', // l10n-ignore
        PaperSizePreset.a5 => 'A5', // l10n-ignore
        PaperSizePreset.a6 => 'A6', // l10n-ignore
        PaperSizePreset.letter => 'Letter', // l10n-ignore
        PaperSizePreset.legal => 'Legal', // l10n-ignore
        PaperSizePreset.square => l.libraryPaperSquare,
        PaperSizePreset.widescreen => l.libraryPaperWide,
        PaperSizePreset.custom => l.libraryPaperCustom,
      };
}

extension NewDocumentOptionL10n on NewDocumentOption {
  String label(AppLocalizations l) => switch (this) {
        NewDocumentOption.notebook => l.libraryNewNotebook,
        NewDocumentOption.whiteboard => l.libraryNewWhiteboard,
        NewDocumentOption.quickNote => l.libraryNewQuickNote,
        NewDocumentOption.importPdf => l.libraryImportPdf,
        NewDocumentOption.importImage => l.libraryImportImage,
      };
}

extension PaperColorL10n on PaperColor {
  /// Display name; [PaperColor.storageKey] is the persisted value, not copy.
  String label(AppLocalizations l) => switch (this) {
        PaperColor.white => l.libraryPaperColorWhite,
        PaperColor.black => l.libraryPaperColorBlack,
        PaperColor.cream => l.libraryPaperColorCream,
        PaperColor.gray => l.libraryPaperColorGray,
        PaperColor.green => l.libraryPaperColorGreen,
        PaperColor.blue => l.libraryPaperColorBlue,
        PaperColor.yellow => l.libraryPaperColorYellow,
      };
}

extension SidebarSectionL10n on SidebarSection {
  /// Title for a section; a folder section shows its folder name instead and
  /// falls back to this while the name loads.
  String title(AppLocalizations l) => switch (this) {
        SidebarSection.documents => l.librarySectionAll,
        SidebarSection.favorites => l.librarySectionFavorites,
        SidebarSection.trash => l.librarySectionTrash,
        SidebarSection.folder => l.libraryFolderFallback,
      };
}
