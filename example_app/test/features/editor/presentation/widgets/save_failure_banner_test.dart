import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:example_app/core/core.dart';
import 'package:example_app/features/editor/editor.dart';
import 'package:example_app/features/editor/presentation/widgets/save_failure_banner.dart';

class _MockSave extends Mock implements SaveDocumentUseCase {}

void main() {
  late _MockSave save;

  setUpAll(() {
    registerFallbackValue(DrawingDocument.emptyMultiPage('fallback'));
  });

  setUp(() => save = _MockSave());

  const failed = Left<Failure, void>(CacheFailure('disk full'));
  const saved = Right<Failure, void>(null);

  Future<ProviderContainer> pumpBanner(
    WidgetTester tester, {
    double width = 380,
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [saveDocumentUseCaseProvider.overrideWithValue(save)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery.withClampedTextScaling(
            minScaleFactor: textScale,
            maxScaleFactor: textScale,
            child: const Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: SaveFailureBanner(),
              ),
            ),
          ),
        ),
      ),
    );
    return container;
  }

  testWidgets('renders nothing while the last save succeeded', (tester) async {
    await pumpBanner(tester);
    expect(find.textContaining('Kaydedilemedi'), findsNothing);
    expect(find.text('Tekrar dene'), findsNothing);
  });

  testWidgets('a failed save shows a banner; Retry re-saves', (tester) async {
    final doc = DrawingDocument.emptyMultiPage('A').copyWith(id: 'doc_a');
    when(() => save(any())).thenAnswer((_) async => failed);
    final container = await pumpBanner(tester);

    await container.read(autoSaveProvider.notifier).saveNow(doc);
    await tester.pump(const Duration(seconds: 10));
    expect(find.textContaining('Kaydedilemedi'), findsOneWidget);

    final retry = find.widgetWithText(TextButton, 'Tekrar dene');
    expect(tester.getSize(retry).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(retry).width, greaterThanOrEqualTo(48));

    when(() => save(any())).thenAnswer((_) async => saved);
    await tester.tap(retry);
    await tester.pumpAndSettle();

    verify(() => save(doc)).called(2);
    expect(find.textContaining('Kaydedilemedi'), findsNothing);
  });

  testWidgets('no overflow at 380dp width and textScaler 1.3', (tester) async {
    final doc = DrawingDocument.emptyMultiPage('A').copyWith(id: 'doc_a');
    when(() => save(any())).thenAnswer((_) async => failed);
    final container = await pumpBanner(tester, textScale: 1.3);
    await container.read(autoSaveProvider.notifier).saveNow(doc);
    await tester.pump();
    expect(find.textContaining('Kaydedilemedi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
