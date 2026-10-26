import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/presentation/widgets/library_tile_parts.dart';
import 'package:example_app/features/documents/presentation/widgets/sidebar_item.dart';

import '../helpers/pump_helpers.dart';

/// Sidebar sections of the library, by their visible label.
class LibrarySection {
  static const all = 'Tüm Notlar';
  static const favorites = 'Favoriler';
  static const trash = 'Son Silinenler';
}

/// Page object for the library (documents) screen.
///
/// Finds widgets by visible Turkish text or tooltip; works on the phone
/// layout (drawer sidebar) and the tablet layout (inline sidebar).
class LibraryRobot {
  LibraryRobot(this.tester);

  final WidgetTester tester;

  static const _emptyTitle = 'Henüz not yok';

  Finder get _emptyState => find.text(_emptyTitle);
  Finder get _newButton => find.byTooltip('Yeni Belge');

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

  /// New (+) button > "Not Defteri" > template screen: set the title, then
  /// "Olustur". The app opens the new notebook in the editor.
  Future<void> createNotebook(String title) async {
    await tester.tapAndWait(_newButton);
    await tester.tapAndWait(find.text('Not Defteri'));
    await tester.pumpUntilFound(find.text('Yeni not olustur'));
    final field = find.descendant(
      of: find.byType(AppTextField),
      matching: find.byType(TextFormField),
    );
    await tester.pumpUntilFound(field);
    await tester.enterText(field.first, title);
    await tester.pumpFor(const Duration(milliseconds: 300));
    await tester.tapAndWait(find.text('Olustur'));
  }

  /// Opens the bottom-sheet menu of the tile titled [title].
  Future<void> openMenu(String title) async {
    await tester.tapAndWait(tileTitle(title));
    await tester.pumpUntilFound(find.byType(BottomSheet));
  }

  Future<void> rename(String from, String to) async {
    await openMenu(from);
    await tester.tapAndWait(find.text('Yeniden Adlandır'));
    final dialog = find.byType(AlertDialog);
    await tester.pumpUntilFound(dialog);
    final field = find.descendant(
      of: dialog,
      matching: find.byType(TextField),
    );
    await tester.enterText(field, to);
    await tester.pumpFor(const Duration(milliseconds: 300));
    await tester.tapAndWait(find.text('Kaydet'));
    await tester.pumpUntilGone(dialog);
  }

  Future<void> addToFavorites(String title) async {
    await openMenu(title);
    await tester.tapAndWait(find.text('Favorilere Ekle'));
  }

  Future<void> moveToTrash(String title) async {
    await openMenu(title);
    await tester.tapAndWait(find.text('Çöpe Taşı'));
  }

  /// Restores a trashed tile ("Kurtar" in the trash menu).
  Future<void> restore(String title) async {
    await openMenu(title);
    await tester.tapAndWait(find.text('Kurtar'));
  }

  /// Switches the sidebar section, opening the drawer / collapsed sidebar
  /// first when its entries are not tappable.
  Future<void> openSection(String label) async {
    final item = find
        .descendant(
          of: find.byType(SidebarItem),
          matching: find.text(label),
        )
        .hitTestable();
    if (item.evaluate().isEmpty) {
      final opener = find.byTooltip('Menü').evaluate().isNotEmpty
          ? find.byTooltip('Menü')
          : find.byTooltip('Kenar çubuğunu aç');
      await tester.tapAndWait(opener);
    }
    await tester.tapAndWait(item);
  }
}
