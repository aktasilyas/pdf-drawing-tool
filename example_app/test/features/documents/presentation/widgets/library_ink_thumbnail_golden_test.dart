import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart' as core;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/entities/paper_color.dart';
import 'package:example_app/features/documents/presentation/widgets/document_card.dart';
import 'package:example_app/features/documents/presentation/widgets/library_page_thumbnail.dart';

import '../../../../helpers/font_loader.dart';
import '../../../../helpers/l10n.dart';

/// Library tiles that show a stored ink thumbnail (#520): the PNG replaces
/// the template / PDF content for notebooks, whiteboards and PDFs.
const _types = <(String, core.DocumentType)>[
  ('Defter', core.DocumentType.notebook),
  ('Beyaz tahta', core.DocumentType.whiteboard),
  ('Ders PDF', core.DocumentType.pdf),
];

final _updatedAt = DateTime(2026, 10, 1);

DocumentInfo _doc((String, core.DocumentType) t) => DocumentInfo(
      id: t.$1,
      title: t.$1,
      templateId: 'blank',
      createdAt: _updatedAt,
      updatedAt: _updatedAt,
      hasCover: false,
      paperColor: PaperColor.white.storageKey,
      documentType: t.$2,
      thumbnailPath: 'thumbnails/${t.$1}.png',
    );

/// A page: white paper, ruled lines and two coloured ink strokes.
Future<Uint8List> _inkPage(int w, int h) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  final rule = Paint()
    ..color = const Color(0xFFC9D3E3)
    ..strokeWidth = 2;
  for (var y = h * 0.1; y < h; y += h * 0.08) {
    canvas.drawLine(Offset(0, y), Offset(w.toDouble(), y), rule);
  }
  Paint ink(Color c) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = w * 0.025;
  final blue = Path()
    ..moveTo(w * 0.15, h * 0.25)
    ..cubicTo(w * 0.35, h * 0.1, w * 0.55, h * 0.4, w * 0.85, h * 0.22);
  final red = Path()
    ..moveTo(w * 0.2, h * 0.6)
    ..cubicTo(w * 0.4, h * 0.5, w * 0.6, h * 0.8, w * 0.8, h * 0.65);
  canvas.drawPath(blue, ink(const Color(0xFF2F5FD0)));
  canvas.drawPath(red, ink(const Color(0xFFD8402F)));
  final image = await recorder.endRecording().toImage(w, h);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

Widget _row(ThemeData theme, double tileWidth, Uint8List png) {
  const gap = 16.0;
  void noop() {}
  return ProviderScope(
    overrides: [
      libraryThumbnailImageProvider.overrideWithValue((_) => MemoryImage(png)),
    ],
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
                for (final t in _types)
                  SizedBox(
                    width: tileWidth,
                    height: tileWidth * 4 / 3 + 64,
                    child: DocumentCard(document: _doc(t), onTap: noop),
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
  late Uint8List png;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppTestFonts();
    png = await _inkPage(420, 594);
  });

  const sizes = {
    'tablet': (180.0, Size(640, 360)),
    'phone': (110.0, Size(400, 480)),
  };
  for (final entry in sizes.entries) {
    for (final mode in ['light', 'dark']) {
      testWidgets('library ink thumbnail tiles ${entry.key} $mode',
          (tester) async {
        tester.view.physicalSize = entry.value.$2;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_row(
          mode == 'light' ? AppTheme.light : AppTheme.dark,
          entry.value.$1,
          png,
        ));
        await tester.pump();
        await tester.runAsync(() async {
          for (final e in find.byType(Image).evaluate()) {
            await precacheImage((e.widget as Image).image, e);
          }
        });
        await tester.pumpAndSettle();
        expect(find.byType(Image), findsNWidgets(_types.length));
        final golden =
            'goldens/library_ink_thumbnail_tiles_${entry.key}_$mode.png';
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(golden),
        );
      });
    }
  }
}
