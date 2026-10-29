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

/// Stand-in render result; the test only checks that bytes arrive.
final Uint8List _bytes = Uint8List.fromList([1, 2, 3]);

const _rendered = Key('pdfRendered');

/// Mirrors the lazy PDF background: rendered bytes, else the placeholder.
class _Page extends ConsumerWidget {
  const _Page(this.stored, this.pageNumber);

  final String stored;
  final int pageNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = '$stored|$pageNumber';
    final bytes = ref.watch(pdfPageCacheProvider)[key] ??
        ref.watch(pdfPageRenderProvider(key)).value;
    if (bytes != null) {
      return const SizedBox(key: _rendered, width: 200, height: 300);
    }
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
    const stored = 'pdfs/doc.pdf';

    testWidgets('placeholder is gone and the page renders after re-link',
        (tester) async {
      final document = DrawingDocument.emptyMultiPage(
        'doc',
        background: PageBackground.pdfLazy(
          pageIndex: 1,
          pdfFilePath: stored,
        ),
      );
      // Stands in for the file on disk; the handler "puts it back".
      var fileBack = false;
      var handlerCalls = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            documentProvider.overrideWith(
              (ref) => DocumentNotifier()..updateDocument(document),
            ),
            pdfSourceMissingProvider.overrideWith(
              (ref, path) async => !fileBack,
            ),
            // Returns bytes only once the file is back.
            pdfFileRasterizerProvider.overrideWithValue(
              (path, page, quality) async => fileBack ? _bytes : null,
            ),
            pdfSourceRelinkProvider.overrideWith(
              (ref) => (path) async {
                handlerCalls++;
                fileBack = true;
                return true;
              },
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: _Page(stored, 1)),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Kaynak PDF bulunamadı'), findsOneWidget);
      expect(find.byKey(_rendered), findsNothing);

      await tester.tap(find.byKey(const Key('pdfLocateSourceButton')));
      for (var i = 0; i < 3; i++) {
        await tester.pump();
      }

      expect(handlerCalls, 1);
      expect(find.byType(PdfPagePlaceholder), findsNothing);
      expect(find.text('Kaynak PDF bulunamadı'), findsNothing);
      expect(find.byKey(_rendered), findsOneWidget);
    });
  });
}
