import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/pdf_page_placeholder.dart';
import 'package:drawing_ui/src/providers/document_provider.dart';
import 'package:drawing_ui/src/providers/pdf_page_cache.dart';
import 'package:drawing_ui/src/providers/pdf_path_provider.dart';
import 'package:drawing_ui/src/providers/pdf_render_provider.dart';
import 'package:drawing_ui/src/providers/pdf_source_relink_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A valid 1x1 PNG.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGA'
  'hKmMIQAAAABJRU5ErkJggg==',
);

/// Mirrors the lazy PDF background: cached/rendered bytes, else the placeholder.
class _Page extends ConsumerWidget {
  const _Page(this.stored, this.pageNumber);

  final String stored;
  final int pageNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = '$stored|$pageNumber';
    final bytes = ref.watch(pdfPageCacheProvider)[key] ??
        ref.watch(pdfPageRenderProvider(key)).value;
    if (bytes != null) return Image.memory(bytes, width: 200, height: 300);
    return PdfPagePlaceholder(width: 200, height: 300, pdfFilePath: stored);
  }
}

void main() {
  group('evictPdfSource', () {
    test('removes only the entries of the given source', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final bytes = Uint8List.fromList([1]);
      container.read(pdfPageCacheProvider.notifier).state = {
        'pdfs/a.pdf|1': bytes,
        'pdfs/a.pdf|1@2.0x': bytes,
        'pdfs/a.pdf|12': bytes,
        'pdfs/ab.pdf|1': bytes,
        'pdfs/b.pdf|1': bytes,
      };
      container.read(pdfThumbnailCacheProvider.notifier).state = {
        'pdfs/a.pdf|2': bytes,
        'pdfs/b.pdf|2': bytes,
      };

      evictPdfSource(container, 'pdfs/a.pdf');

      expect(
        container.read(pdfPageCacheProvider).keys,
        unorderedEquals(['pdfs/ab.pdf|1', 'pdfs/b.pdf|1']),
      );
      expect(
        container.read(pdfThumbnailCacheProvider).keys,
        ['pdfs/b.pdf|2'],
      );
    });
  });

  group('re-link', () {
    late Directory root;
    const stored = 'pdfs/doc.pdf';

    setUp(() {
      root = Directory.systemTemp.createTempSync('pdf_relink_');
      Directory('${root.path}/pdfs').createSync();
    });

    tearDown(() => root.deleteSync(recursive: true));

    testWidgets('placeholder is gone and the page renders after re-link',
        (tester) async {
      final document = DrawingDocument.emptyMultiPage(
        'doc',
        background: PageBackground.pdfLazy(
          pageIndex: 1,
          pdfFilePath: stored,
        ),
      );
      var handlerCalls = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pdfPathResolverProvider
                .overrideWithValue(PdfPathResolver(root.path)),
            documentProvider.overrideWith(
              (ref) => DocumentNotifier()..updateDocument(document),
            ),
            // Returns bytes only once the file exists on disk.
            pdfFileRasterizerProvider.overrideWithValue(
              (path, page, quality) async =>
                  File(path).existsSync() ? _png : null,
            ),
            pdfSourceRelinkProvider.overrideWith(
              (ref) => (path) async {
                handlerCalls++;
                File('${root.path}/$path').writeAsBytesSync([1, 2, 3]);
                return true;
              },
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: _Page(stored, 1)),
          ),
        ),
      );
      // Render and existence check are real async work.
      Future<void> settle() async {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
      }

      await settle();

      expect(find.text('Kaynak PDF bulunamadı'), findsOneWidget);
      expect(find.byType(Image), findsNothing);

      await tester.tap(find.byKey(const Key('pdfLocateSourceButton')));
      await settle();
      await settle();

      expect(handlerCalls, 1);
      expect(find.byType(PdfPagePlaceholder), findsNothing);
      expect(find.text('Kaynak PDF bulunamadı'), findsNothing);
      expect(find.byType(Image), findsOneWidget);
    });
  });
}
