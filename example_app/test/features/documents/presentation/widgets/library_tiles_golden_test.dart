import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/widgets/document_card.dart';
import 'package:example_app/features/documents/presentation/widgets/folder_card.dart';

import '../../../../helpers/font_loader.dart';
import '../../../../helpers/l10n.dart';

DocumentInfo _doc(String title, {bool portrait = true}) => DocumentInfo(
      id: title,
      title: title,
      templateId: 'thin_lined',
      createdAt: DateTime(2026, 10, 1),
      updatedAt: DateTime(2026, 10, 1),
      hasCover: false,
      isPortrait: portrait,
    );

Folder _folder(String name, int color) => Folder(
      id: name,
      name: name,
      colorValue: color,
      createdAt: DateTime(2026, 1, 1),
      documentCount: 5,
    );

Widget _row(ThemeData theme, double tileWidth) {
  const gap = 16.0;
  void noop() {}
  final tiles = <Widget>[
    FolderCard(folder: _folder('Okul', 0xFF5B7CFF), onTap: noop),
    FolderCard(folder: _folder('İş', 0xFFE0A030), onTap: noop),
    DocumentCard(document: _doc('Ders Notu'), onTap: noop),
    DocumentCard(document: _doc('Sunum Taslağı', portrait: false), onTap: noop),
    DocumentCard(document: _doc('Beyaz Tahta'), onTap: noop),
  ];
  return ProviderScope(
    child: localizedApp(
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) => Scaffold(
          backgroundColor: context.palette.background,
          body: Padding(
            padding: const EdgeInsets.all(gap),
            child: Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final t in tiles)
                  SizedBox(
                    width: tileWidth,
                    height: tileWidth * 4 / 3 + 64,
                    child: t,
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppTestFonts();
  });

  const sizes = {
    'tablet': (180.0, Size(1000, 360)),
    'phone': (110.0, Size(400, 560))
  };
  for (final entry in sizes.entries) {
    for (final mode in ['light', 'dark']) {
      testWidgets('library tiles mixed row ${entry.key} $mode', (tester) async {
        tester.view.physicalSize = entry.value.$2;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_row(
          mode == 'light' ? AppTheme.light : AppTheme.dark,
          entry.value.$1,
        ));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/library_tiles_${entry.key}_$mode.png'),
        );
      });
    }
  }
}
