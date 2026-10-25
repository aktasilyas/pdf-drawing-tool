import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/presentation/widgets/folder_tile_art.dart';

void main() {
  group('FolderTileArt.shouldRepaint', () {
    final base = FolderTileArt(
      color: const Color(0xFF5B7CFF),
      palette: AppPalette.light,
    );

    test('is false for equal inputs', () {
      final same = FolderTileArt(
        color: const Color(0xFF5B7CFF),
        palette: AppPalette.light,
      );
      expect(same.shouldRepaint(base), isFalse);
    });

    test('is true for a new colour', () {
      final other = FolderTileArt(
        color: const Color(0xFFE91E63),
        palette: AppPalette.light,
      );
      expect(other.shouldRepaint(base), isTrue);
    });

    test('is true for a new palette', () {
      final other = FolderTileArt(
        color: const Color(0xFF5B7CFF),
        palette: AppPalette.dark,
      );
      expect(other.shouldRepaint(base), isTrue);
    });
  });

  testWidgets('paints without error in a tile-sized box', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Center(
          child: SizedBox(
            width: 151,
            height: 201.6,
            child: Builder(
              builder: (context) => CustomPaint(
                painter: FolderTileArt(
                  color: const Color(0xFF5B7CFF),
                  palette: context.palette,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
