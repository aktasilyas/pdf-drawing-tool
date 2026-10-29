import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:example_app/features/documents/documents.dart'
    show PdfRelinkError, PdfRelinkFailure, RelinkPdfSourceUseCase;
import 'package:example_app/features/editor/editor.dart';
import 'package:example_app/l10n/l10n.dart';

import '../../../../helpers/l10n.dart';

class _MockRelink extends Mock implements RelinkPdfSourceUseCase {}

const _stored = 'pdfs/doc.pdf';
const _picked = '/picked/doc.pdf';

void main() {
  late ProviderContainer container;
  late _MockRelink relink;

  setUp(() {
    container = ProviderContainer();
    relink = _MockRelink();
    container.read(documentProvider.notifier).updateDocument(
          DrawingDocument.emptyMultiPage(
            'doc',
            background:
                PageBackground.pdfLazy(pageIndex: 3, pdfFilePath: _stored),
          ),
        );
  });

  tearDown(() => container.dispose());

  void stubRelink(Either<PdfRelinkFailure, Unit> result) {
    when(
      () => relink(
        storedPath: any(named: 'storedPath'),
        pickedPath: any(named: 'pickedPath'),
        requiredPages: any(named: 'requiredPages'),
      ),
    ).thenAnswer((_) async => result);
  }

  /// Pumps a localized scaffold and returns a handler bound to its context.
  Future<PdfSourceRelinkHandler> pumpHandler(
    WidgetTester tester, {
    String? picked = _picked,
  }) async {
    late BuildContext context;
    await tester.pumpWidget(
      localizedApp(
        home: Scaffold(
          body: Builder(
            builder: (c) {
              context = c;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    return pdfRelinkHandlerFor(
      container.read,
      context,
      pickPdf: () async => picked,
      relink: relink,
    );
  }

  testWidgets('success relinks with the highest referenced page',
      (tester) async {
    stubRelink(const Right(unit));
    final handler = await pumpHandler(tester);

    final ok = await handler(_stored);
    await tester.pump();

    expect(ok, isTrue);
    verify(
      () => relink(storedPath: _stored, pickedPath: _picked, requiredPages: 3),
    ).called(1);
    expect(find.text('PDF yeniden bağlandı'), findsOneWidget);
  });

  testWidgets('cancelled picker does nothing', (tester) async {
    final handler = await pumpHandler(tester, picked: null);

    expect(await handler(_stored), isFalse);
    verifyZeroInteractions(relink);
  });

  testWidgets('too few pages reports the counts', (tester) async {
    stubRelink(
      const Left(
        PdfRelinkFailure(
          PdfRelinkError.pageCountMismatch,
          found: 2,
          required: 3,
        ),
      ),
    );
    final handler = await pumpHandler(tester);

    expect(await handler(_stored), isFalse);
    await tester.pump();

    expect(
      find.text('Bu PDF 2 sayfa; defter 3 sayfa gerektiriyor.'),
      findsOneWidget,
    );
  });

  testWidgets('an existing target counts as relinked', (tester) async {
    stubRelink(const Left(PdfRelinkFailure(PdfRelinkError.targetExists)));
    final handler = await pumpHandler(tester);

    expect(await handler(_stored), isTrue);
    await tester.pump();

    expect(find.byType(SnackBar), findsNothing);
  });

  test('failure copy covers every error', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    for (final error in PdfRelinkError.values) {
      expect(
        pdfRelinkFailureMessage(l10n, PdfRelinkFailure(error)),
        isNotEmpty,
      );
    }
    expect(
      pdfRelinkFailureMessage(
        l10n,
        const PdfRelinkFailure(PdfRelinkError.passwordProtected),
      ),
      l10n.editorErrorPdfPasswordProtected,
    );
  });
}
