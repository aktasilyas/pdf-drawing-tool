import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/presentation/screens/template_selection_screen.dart';
import 'package:example_app/features/documents/presentation/widgets/library_header_parts.dart';
import 'package:example_app/features/documents/presentation/widgets/library_tile_frame.dart';
import 'package:example_app/features/documents/presentation/widgets/library_tile_parts.dart';
import 'package:example_app/features/documents/presentation/widgets/manage_folder_list_item.dart';
import 'package:example_app/features/documents/presentation/widgets/sidebar_item.dart';
import 'package:example_app/features/documents/presentation/widgets/template_preview_section.dart';
import 'package:example_app/l10n/l10n.dart';

import '../helpers/l10n.dart';
import '../helpers/pump_helpers.dart';

/// Sidebar sections of the library.
enum LibrarySection {
  all,
  favorites,
  trash;

  /// The section's sidebar label in the running locale.
  String label(AppLocalizations l10n) => switch (this) {
        LibrarySection.all => l10n.librarySectionAll,
        LibrarySection.favorites => l10n.librarySectionFavorites,
        LibrarySection.trash => l10n.librarySectionTrash,
      };
}

/// Page object for the library (documents) screen.
///
/// Finds widgets by type, or by the localized text or tooltip of the running
/// locale (`tester.l10n`); screens not localized yet are still matched by
/// their Turkish text. Works on the phone layout (drawer sidebar) and the
/// tablet layout (inline sidebar).
class LibraryRobot {
  LibraryRobot(this.tester);

  final WidgetTester tester;

  /// Only valid once the library is visible (see [waitForLibrary]).
  AppLocalizations get _l10n => tester.l10n;

  Finder get _emptyState => find.text(_l10n.libraryEmptyTitle);
  Finder get _newButton => find.byType(LibraryNewButton);

  /// Title text inside a tile's info block; tapping it opens the item menu.
  Finder tileTitle(String title) => find.descendant(
        of: find.byType(LibraryTileInfo),
        matching: find.text(title),
      );

  /// Waits through the splash screen until the library is shown.
  /// Also lets startup work (the unawaited trash purge) settle, so a later
  /// reset or relaunch does not close the database under it.
  Future<void> waitForLibrary() async {
    await tester.pumpUntilFound(_newButton);
    await tester.pumpFor(const Duration(milliseconds: 500));
  }

  void expectEmptyState() {
    expect(_emptyState, findsOneWidget);
    expect(find.byType(LibraryTileInfo), findsNothing);
  }

  void expectListed(String title) {
    expect(tileTitle(title), findsOneWidget);
  }

  Future<void> waitListed(String title) =>
      tester.pumpUntilFound(tileTitle(title));

  Future<void> waitNotListed(String title) =>
      tester.pumpUntilGone(tileTitle(title));

  void expectNotListed(String title) {
    expect(tileTitle(title), findsNothing);
  }

  void expectFavoriteBadge({required bool visible}) {
    expect(
      find.byType(LibraryFavoriteBadge),
      visible ? findsOneWidget : findsNothing,
    );
  }

  /// New (+) button > "Notebook" > template screen: set the title, then
  /// "Create". The app opens the new notebook in the editor.
  ///
  /// With [cover] false the cover switch is turned off, so the notebook
  /// starts with a single writable page instead of cover + page.
  Future<void> createNotebook(String title, {bool cover = true}) async {
    await tester.tapAndWait(_newButton);
    await tester.tapAndWait(find.text(_l10n.libraryNewNotebook));
    await tester.pumpUntilFound(find.byType(TemplateSelectionScreen));
    final field = find.descendant(
      of: find.byType(AppTextField),
      matching: find.byType(TextFormField),
    );
    await tester.pumpUntilFound(field);
    await tester.enterText(field.first, title);
    await tester.pumpFor(const Duration(milliseconds: 300));
    if (!cover) {
      final coverSwitch = find
          .descendant(
            of: find.byType(TemplatePreviewSection),
            matching: find.byType(Switch),
          )
          .first;
      await tester.ensureVisible(coverSwitch);
      await tester.tapAndWait(coverSwitch);
    }
    await tester.tapAndWait(
      find.widgetWithText(AppButton, _l10n.commonCreate),
    );
  }

  /// Cover of the grid tile titled [title]; tapping it opens the item.
  Finder tileCover(String title) => find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is LibraryTileFrame && w.semanticLabel == title,
        ),
        matching: find.byType(GestureDetector),
      );

  /// Opens the notebook titled [title] in the editor by tapping its cover.
  Future<void> openNotebook(String title) async {
    await tester.tapAndWait(tileCover(title));
  }

  /// Opens the bottom-sheet menu of the tile titled [title].
  Future<void> openMenu(String title) async {
    await tester.tapAndWait(tileTitle(title));
    await tester.pumpUntilFound(find.byType(BottomSheet));
  }

  Future<void> rename(String from, String to) async {
    await openMenu(from);
    final l10n = _l10n;
    await tester.tapAndWait(find.text(l10n.commonRename));
    final dialog = find.byType(AlertDialog);
    await tester.pumpUntilFound(dialog);
    final field = find.descendant(
      of: dialog,
      matching: find.byType(TextField),
    );
    await tester.enterText(field, to);
    await tester.pumpFor(const Duration(milliseconds: 300));
    await tester.tapAndWait(find.text(l10n.commonSave));
    await tester.pumpUntilGone(dialog);
  }

  Future<void> addToFavorites(String title) async {
    await openMenu(title);
    await tester.tapAndWait(find.text(_l10n.libraryAddToFavorites));
  }

  Future<void> moveToTrash(String title) async {
    await openMenu(title);
    await tester.tapAndWait(find.text(_l10n.libraryMoveToTrash));
  }

  /// Restores a trashed tile ("Restore" in the trash menu).
  Future<void> restore(String title) async {
    await openMenu(title);
    await tester.tapAndWait(find.text(_l10n.commonRestore));
  }

  /// Switches the sidebar section, opening the drawer / collapsed sidebar
  /// first when its entries are not tappable.
  Future<void> openSection(LibrarySection section) async {
    final item = find
        .descendant(
          of: find.byType(SidebarItem),
          matching: find.text(section.label(_l10n)),
        )
        .hitTestable();
    if (item.evaluate().isEmpty) await tester.tapAndWait(_sidebarOpener);
    await tester.tapAndWait(item);
  }

  /// Phone drawer button, or the tablet's collapsed-sidebar toggle.
  Finder get _sidebarOpener {
    final menu = find.byTooltip(_l10n.commonMenu);
    return menu.evaluate().isNotEmpty
        ? menu
        : find.byTooltip(_l10n.libraryOpenSidebar);
  }

  /// Opens the folder management screen from the sidebar ("Manage").
  Future<void> openManageFolders() async {
    await _ensureSidebarVisible();
    await tester.tapAndWait(find.text(_l10n.libraryManage));
    await tester.pumpUntilFound(find.text('Klasörleri Yönet'));
  }

  /// Leaves the folder management screen.
  Future<void> closeManageFolders() async {
    await tester.tapAndWait(find.byTooltip('Geri'));
    await waitForLibrary();
  }

  Finder get _dialog => find.byType(AlertDialog);

  Future<void> _fillDialogAndConfirm(String text, String confirm) async {
    await tester.pumpUntilFound(_dialog);
    final field =
        find.descendant(of: _dialog, matching: find.byType(TextField));
    await tester.enterText(field, text);
    await tester.pumpFor(const Duration(milliseconds: 300));
    await tester.tapAndWait(
      find.descendant(of: _dialog, matching: find.text(confirm)),
    );
    await tester.pumpUntilGone(_dialog);
  }

  /// Manage-folders screen: bottom "Yeni Klasör" button.
  Future<void> createFolder(String name) async {
    await tester.tapAndWait(find.text('Yeni Klasör').last);
    await _fillDialogAndConfirm(name, 'Oluştur');
  }

  Future<void> _folderMenuAction(String folder, String action) async {
    final tile = find.ancestor(
      of: find.text(folder),
      matching: find.byType(ManageFolderListItem),
    );
    await tester.tapAndWait(
      find.descendant(of: tile, matching: find.byType(PopupMenuButton<String>)),
    );
    await tester.tapAndWait(find.text(action));
  }

  Future<void> renameFolder(String from, String to) async {
    await _folderMenuAction(from, 'Yeniden Adlandır');
    await _fillDialogAndConfirm(to, 'Kaydet');
  }

  Future<void> addSubfolder(String parent, String name) async {
    await _folderMenuAction(parent, 'Alt Klasör Ekle');
    await _fillDialogAndConfirm(name, 'Oluştur');
  }

  /// Deletes a folder through its menu and the confirm dialog.
  Future<void> deleteFolder(String name) async {
    await _folderMenuAction(name, 'Sil');
    await tester.tapAndWait(
      find.widgetWithText(AppButton, 'Sil'),
    );
  }

  void expectFolderListed(String name, {required bool listed}) {
    expect(
      find.descendant(
        of: find.byType(ManageFolderListItem),
        matching: find.text(name),
      ),
      listed ? findsOneWidget : findsNothing,
    );
  }

  /// Trash section: "Empty trash" then confirm "Empty".
  Future<void> emptyTrash() async {
    final l10n = _l10n;
    await tester.tapAndWait(
      find.widgetWithText(AppButton, l10n.libraryEmptyTrash),
    );
    await tester.tapAndWait(
      find.widgetWithText(AppButton, l10n.libraryEmptyTrashConfirm),
    );
  }

  Future<void> _ensureSidebarVisible() async {
    final manage = find.text(_l10n.libraryManage).hitTestable();
    if (manage.evaluate().isNotEmpty) return;
    await tester.tapAndWait(_sidebarOpener);
  }
}
