import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/drawing_ui.dart' show ElyanotesIcons;

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/widgets/library_tile_frame.dart';
import 'package:example_app/features/documents/presentation/widgets/library_tile_parts.dart';

Widget _host(ThemeData theme, Widget child) => MaterialApp(
      theme: theme,
      home: Scaffold(body: Center(child: child)),
    );

BoxDecoration _checkboxDecoration(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byType(LibrarySelectionCheckbox),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  group('LibrarySelectionCheckbox', () {
    for (final entry in {
      'light': (AppTheme.light, AppPalette.light),
      'dark': (AppTheme.dark, AppPalette.dark),
    }.entries) {
      final theme = entry.value.$1;
      final palette = entry.value.$2;

      testWidgets('${entry.key}: off uses elevated fill and muted ring',
          (tester) async {
        await tester.pumpWidget(
          _host(theme, const LibrarySelectionCheckbox(isSelected: false)),
        );

        final d = _checkboxDecoration(tester);
        expect(
          d.color,
          equals(palette.surfaceElevated.withValues(alpha: 0.92)),
        );
        expect(d.border?.top.color, equals(palette.textMuted));
        expect(d.border?.top.width, equals(1.5));
        expect(find.byIcon(ElyanotesIcons.libraryCheck), findsNothing);
      });

      testWidgets('${entry.key}: on uses accent fill and a check',
          (tester) async {
        await tester.pumpWidget(
          _host(theme, const LibrarySelectionCheckbox(isSelected: true)),
        );

        final d = _checkboxDecoration(tester);
        expect(d.color, equals(palette.accent));
        final icon = tester.widget<Icon>(
          find.byIcon(ElyanotesIcons.libraryCheck),
        );
        expect(icon.color, equals(palette.onAccent));
      });
    }
  });

  group('LibraryMeta', () {
    final doc = DocumentInfo(
      id: 'd',
      title: 'T',
      templateId: 'blank',
      createdAt: DateTime(2026, 10, 12),
      updatedAt: DateTime(2026, 10, 12),
    );

    test('document with one page has no page count', () {
      expect(LibraryMeta.document(doc), '12 Eki 2026');
    });

    test('document with several pages adds the count', () {
      expect(
        LibraryMeta.document(doc.copyWith(pageCount: 24)),
        '12 Eki 2026 · 24 sayfa',
      );
    });

    test('folder shows the document count', () {
      final folder = Folder(
        id: 'f',
        name: 'F',
        createdAt: DateTime(2026, 10, 1),
        documentCount: 4,
      );
      expect(LibraryMeta.folder(folder), '4 belge');
    });
  });

  testWidgets('LibraryTileInfo hit area is at least 48dp high', (tester) async {
    await tester.pumpWidget(
      _host(
        AppTheme.light,
        const SizedBox(
          width: 151,
          child: LibraryTileInfo(title: 'Biyoloji', meta: '12 Eki 2026'),
        ),
      ),
    );

    final size = tester.getSize(find.byType(LibraryTileInfo));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('LibraryTileInfo tap calls onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        AppTheme.light,
        SizedBox(
          width: 151,
          child: LibraryTileInfo(
            title: 'Biyoloji',
            meta: '12 Eki 2026',
            onTap: () => taps++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Biyoloji'));
    expect(taps, 1);
  });

  group('LibraryTileFrame', () {
    Widget frame({
      required VoidCallback onTap,
      required VoidCallback onLongPress,
      bool isSelectionMode = false,
      bool isSelected = false,
    }) {
      return _host(
        AppTheme.light,
        SizedBox(
          width: 151,
          height: 252,
          child: LibraryTileFrame(
            cover: const ColoredBox(color: Colors.red),
            info: const LibraryTileInfo(title: 'Biyoloji', meta: '12 Eki 2026'),
            onTap: onTap,
            onLongPress: onLongPress,
            isSelectionMode: isSelectionMode,
            isSelected: isSelected,
          ),
        ),
      );
    }

    testWidgets('tap on the cover calls onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(frame(onTap: () => taps++, onLongPress: () {}));

      await tester.tapAt(tester.getTopLeft(find.byType(LibraryTileFrame)) +
          const Offset(75, 100));
      expect(taps, 1);
    });

    testWidgets('long press on the cover calls onLongPress', (tester) async {
      var longPresses = 0;
      await tester.pumpWidget(
        frame(onTap: () {}, onLongPress: () => longPresses++),
      );

      final origin = tester.getTopLeft(find.byType(LibraryTileFrame));
      await tester.longPressAt(origin + const Offset(75, 100));
      expect(longPresses, 1);
    });

    testWidgets('checkbox only appears in selection mode', (tester) async {
      await tester.pumpWidget(frame(onTap: () {}, onLongPress: () {}));
      expect(find.byType(LibrarySelectionCheckbox), findsNothing);

      await tester.pumpWidget(
        frame(onTap: () {}, onLongPress: () {}, isSelectionMode: true),
      );
      expect(find.byType(LibrarySelectionCheckbox), findsOneWidget);
    });

    testWidgets('checkbox sits on the top-right of a custom artRect',
        (tester) async {
      const key = Key('art_marker');
      Rect art(Size box) => const Rect.fromLTWH(10, 20, 80, 90);
      await tester.pumpWidget(
        _host(
          AppTheme.light,
          SizedBox(
            width: 151,
            height: 252,
            child: LibraryTileFrame(
              cover: const ColoredBox(color: Colors.red),
              info: const LibraryTileInfo(title: 'A', meta: 'B'),
              onTap: () {},
              onLongPress: () {},
              isSelectionMode: true,
              artRect: art,
              overlays: (rect) => [
                Positioned.fromRect(
                  rect: rect,
                  child: const SizedBox(key: key),
                ),
              ],
            ),
          ),
        ),
      );

      final marker = tester.getRect(find.byKey(key));
      final box = tester.getRect(find.byType(LibrarySelectionCheckbox));
      expect(marker.width, closeTo(80, 0.01));
      expect(marker.height, closeTo(90, 0.01));
      expect(box.right, closeTo(marker.right - AppSpacing.sm, 0.01));
      expect(box.top, closeTo(marker.top + AppSpacing.sm, 0.01));
    });
  });
}
