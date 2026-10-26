import 'dart:io' show ProcessInfo;
import 'dart:math' as math;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart'
    show PDFDocumentMetadata, PDFExporter;
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';

const _pageCount = 200;
const _strokesPerPage = 6;

/// Upper bound for the `ProcessInfo.maxRss` growth while exporting.
/// First green emulator run measured 342 MB (17.1 MB PDF); ~75% headroom.
const _maxRssGrowthBytes = 600 * 1024 * 1024;

/// Log marker picked up by `.github/workflows/e2e.yml` (annotation).
const _marker = 'E2E_EXPORT_MEMORY';

Stroke _pencilStroke(int page, int n) {
  final rnd = math.Random(page * 31 + n);
  final x0 = 60 + rnd.nextDouble() * 200;
  final y0 = 80 + n * 110 + rnd.nextDouble() * 40;
  final points = <DrawingPoint>[
    for (var i = 0; i < 80; i++)
      DrawingPoint(
        x: x0 + i * 4.0,
        y: y0 + math.sin(i / 6) * 30 + rnd.nextDouble() * 2,
        pressure: 0.3 + 0.7 * rnd.nextDouble(),
        timestamp: i * 8,
      ),
  ];
  return Stroke.create(
    style: StrokeStyle(
      color: 0xFF333333,
      thickness: 2.5,
      nibShape: NibShape.circle,
      texture: StrokeTexture.pencil,
    ),
    points: points,
  );
}

Page _page(int index) {
  final base = Page.create(index: index);
  final layer = Layer(
    id: 'layer_$index',
    name: 'Katman 1',
    strokes: [
      for (var n = 0; n < _strokesPerPage; n++) _pencilStroke(index, n)
    ],
  );
  return Page(
    id: 'page_e2e_$index',
    index: index,
    size: base.size,
    layers: [layer],
    createdAt: base.createdAt,
    updatedAt: base.updatedAt,
  );
}

void main() {
  initE2E();

  testWidgets(
    'export: 200-page Pencil notebook stays within a bounded memory budget',
    (tester) async {
      final pages = [for (var i = 0; i < _pageCount; i++) _page(i)];

      final before = ProcessInfo.maxRss;
      final result = await tester.runAsync(
        () => PDFExporter().exportPages(
          pages: pages,
          metadata: const PDFDocumentMetadata(title: 'E2E Pencil 200'),
        ),
      );
      final growth = ProcessInfo.maxRss - before;

      expect(result, isNotNull);
      expect(result!.isSuccess, isTrue, reason: result.errorMessage);

      final mb = (result.fileSizeBytes / (1024 * 1024)).toStringAsFixed(1);
      final growthMb = (growth / (1024 * 1024)).toStringAsFixed(1);
      // ignore: avoid_print
      print('$_marker pages=$_pageCount pdf_mb=$mb maxrss_growth_mb=$growthMb');

      expect(growth, lessThan(_maxRssGrowthBytes),
          reason: 'maxRss grew by $growthMb MB exporting $_pageCount pages');
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
