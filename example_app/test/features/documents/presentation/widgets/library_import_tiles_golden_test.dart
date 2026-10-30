import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart' as core;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/entities/paper_color.dart';
import 'package:example_app/features/documents/presentation/providers/document_preview_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/document_card.dart';

import '../../../../helpers/font_loader.dart';
import '../../../../helpers/l10n.dart';

/// Library tiles of imported PDFs and images (#468): every first page is
/// shown whole. Each preview has a coloured frame, so a cropped edge would
/// show as a missing border in the golden.
typedef _Import = ({
  String title,
  core.DocumentType type,
  bool portrait,
  double shortMm,
  double longMm,
  int imageWidth,
  int imageHeight,
});

const _imports = <_Import>[
  // Portrait A4 PDF: unchanged behaviour.
  (
    title: 'Ders PDF',
    type: core.DocumentType.pdf,
    portrait: true,
    shortMm: 210,
    longMm: 297,
    imageWidth: 210,
    imageHeight: 297,
  ),
  // 16:9 slide deck: landscape row from the first page.
  (
    title: 'Sunum 16:9',
    type: core.DocumentType.pdf,
    portrait: false,
    shortMm: 190.5,
    longMm: 338.7,
    imageWidth: 320,
    imageHeight: 180,
  ),
  // Mixed PDF whose stored row is A4 portrait while the first page is 4:3
  // landscape (rows imported before #468): BoxFit.contain on paper.
  (
    title: 'Karışık PDF',
    type: core.DocumentType.pdf,
    portrait: true,
    shortMm: 210,
    longMm: 297,
    imageWidth: 320,
    imageHeight: 240,
  ),
  // Landscape photo import.
  (
    title: 'Fotoğraf',
    type: core.DocumentType.image,
    portrait: false,
    shortMm: 210,
    longMm: 280,
    imageWidth: 400,
    imageHeight: 300,
  ),
];

final _updatedAt = DateTime(2026, 10, 1);

DocumentInfo _doc(_Import i) => DocumentInfo(
      id: i.title,
      title: i.title,
      templateId: 'blank',
      createdAt: _updatedAt,
      updatedAt: _updatedAt,
      hasCover: false,
      paperColor: PaperColor.white.storageKey,
      isPortrait: i.portrait,
      documentType: i.type,
      paperWidthMm: i.shortMm,
      paperHeightMm: i.longMm,
    );

/// A page image: light fill, a 6 px coloured frame and two content bars.
Future<Uint8List> _pageImage(int w, int h, Color frame) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final rect = Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());
  canvas.drawRect(rect, Paint()..color = const Color(0xFFF4F1EA));
  canvas.drawRect(
    rect.deflate(3),
    Paint()
      ..color = frame
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6,
  );
  final bar = Paint()..color = frame.withValues(alpha: 0.5);
  canvas.drawRect(Rect.fromLTWH(w * 0.15, h * 0.2, w * 0.7, h * 0.12), bar);
  canvas.drawRect(Rect.fromLTWH(w * 0.15, h * 0.45, w * 0.45, h * 0.08), bar);
  final image = await recorder.endRecording().toImage(w, h);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

const _frames = [
  Color(0xFF3B6FD8),
  Color(0xFFD8553B),
  Color(0xFF2F9E6B),
  Color(0xFF8A4FC7),
];

Widget _row(ThemeData theme, double tileWidth, Map<String, Uint8List> pages) {
  const gap = 16.0;
  void noop() {}
  return ProviderScope(
    overrides: [
      documentPreviewBackgroundProvider.overrideWith(
        (ref, key) async => core.PageBackground(
          type: core.BackgroundType.pdf,
          pdfData: pages[key.id],
        ),
      ),
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
                for (final i in _imports)
                  SizedBox(
                    width: tileWidth,
                    height: tileWidth * 4 / 3 + 64,
                    child: DocumentCard(document: _doc(i), onTap: noop),
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
  final pages = <String, Uint8List>{};

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppTestFonts();
    for (var n = 0; n < _imports.length; n++) {
      final i = _imports[n];
      final png = await _pageImage(i.imageWidth, i.imageHeight, _frames[n]);
      pages[i.title] = png;
    }
  });

  const sizes = {
    'tablet': (180.0, Size(840, 360)),
    'phone': (110.0, Size(400, 480)),
  };
  for (final entry in sizes.entries) {
    for (final mode in ['light', 'dark']) {
      testWidgets('library imported tiles ${entry.key} $mode', (tester) async {
        tester.view.physicalSize = entry.value.$2;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_row(
          mode == 'light' ? AppTheme.light : AppTheme.dark,
          entry.value.$1,
          pages,
        ));
        await tester.pump();
        await tester.runAsync(() async {
          for (final e in find.byType(Image).evaluate()) {
            await precacheImage((e.widget as Image).image, e);
          }
        });
        await tester.pumpAndSettle();
        expect(find.byType(Image), findsNWidgets(_imports.length));
        final golden = 'goldens/library_import_tiles_${entry.key}_$mode.png';
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(golden),
        );
      });
    }
  }
}
