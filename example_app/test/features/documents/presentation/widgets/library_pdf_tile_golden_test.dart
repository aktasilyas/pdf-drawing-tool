import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/drawing_ui.dart'
    show libraryPreviewWidth, pdfWidthRasterizerProvider;
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

/// Library tiles of imported PDFs that were never opened (#529): the first
/// page is rendered at tile width x DPR, so thin text lines stay crisp on a
/// 2x tablet instead of being upscaled from a 120 px sidebar thumbnail.
typedef _Pdf = ({String title, bool portrait, int w, int h});

const _pdfs = <_Pdf>[
  (title: 'Ders PDF', portrait: true, w: 210, h: 297),
  (title: 'Sunum 16:9', portrait: false, w: 320, h: 180),
];

const _dpr = 2.0;
const _tileWidth = 180.0;
final _updatedAt = DateTime(2026, 10, 1);

DocumentInfo _doc(_Pdf p) => DocumentInfo(
      id: p.title,
      title: p.title,
      templateId: 'blank',
      createdAt: _updatedAt,
      updatedAt: _updatedAt,
      hasCover: false,
      paperColor: PaperColor.white.storageKey,
      isPortrait: p.portrait,
      documentType: core.DocumentType.pdf,
      paperWidthMm: p.portrait ? 210 : 190.5,
      paperHeightMm: p.portrait ? 297 : 338.7,
    );

/// A text-like page [width] px wide: a heading bar and 1 px text lines,
/// which blur visibly when a small render is scaled up.
Future<Uint8List> _pageImage(int width, _Pdf p, Color ink) async {
  final height = (width * p.h / p.w).round();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final w = width.toDouble();
  final h = height.toDouble();
  canvas.drawRect(
    Rect.fromLTWH(0, 0, w, h),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  canvas.drawRect(
    Rect.fromLTWH(w * 0.1, h * 0.08, w * 0.6, h * 0.05),
    Paint()..color = ink,
  );
  final line = Paint()
    ..color = const Color(0xFF333333)
    ..strokeWidth = 1;
  for (var y = h * 0.2; y < h * 0.9; y += 6) {
    canvas.drawLine(Offset(w * 0.1, y), Offset(w * 0.9, y), line);
  }
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

Widget _row(ThemeData theme, Map<String, Uint8List> pages, List<int> widths) {
  const gap = 16.0;
  void noop() {}
  return ProviderScope(
    overrides: [
      documentPreviewBackgroundProvider.overrideWith(
        (ref, key) async =>
            core.PageBackground.pdfLazy(pageIndex: 1, pdfFilePath: key.id),
      ),
      pdfWidthRasterizerProvider.overrideWithValue((path, page, width) async {
        widths.add(width);
        return pages[path];
      }),
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
                for (final p in _pdfs)
                  SizedBox(
                    width: _tileWidth,
                    height: _tileWidth * 4 / 3 + 64,
                    child: DocumentCard(document: _doc(p), onTap: noop),
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
    const inks = [Color(0xFF3B6FD8), Color(0xFFD8553B)];
    for (var n = 0; n < _pdfs.length; n++) {
      final p = _pdfs[n];
      pages[p.title] = await _pageImage(libraryPreviewWidth(_dpr), p, inks[n]);
    }
  });

  for (final mode in ['light', 'dark']) {
    testWidgets('library lazy PDF tiles tablet $mode', (tester) async {
      tester.view.physicalSize = const Size(440, 360) * _dpr;
      tester.view.devicePixelRatio = _dpr;
      addTearDown(tester.view.reset);
      final widths = <int>[];

      await tester.pumpWidget(_row(
        mode == 'light' ? AppTheme.light : AppTheme.dark,
        pages,
        widths,
      ));
      await tester.pump();
      await tester.pump();
      await tester.runAsync(() async {
        for (final e in find.byType(Image).evaluate()) {
          await precacheImage((e.widget as Image).image, e);
        }
      });
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsNWidgets(_pdfs.length));
      expect(widths, everyElement(greaterThanOrEqualTo(_tileWidth * _dpr)));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/library_pdf_tiles_tablet_$mode.png'),
      );
    });
  }
}
