import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:example_app/features/documents/domain/repositories/document_repository.dart';
import 'package:example_app/features/editor/editor.dart';
import 'package:example_app/features/editor/presentation/providers/library_thumbnail_writer.dart';

class _MockSave extends Mock implements SaveDocumentUseCase {}

class _MockRepo extends Mock implements DocumentRepository {}

void main() {
  late _MockSave save;
  late DrawingDocument doc;
  late int leaveCalls;

  setUpAll(() {
    registerFallbackValue(DrawingDocument.emptyMultiPage('fallback'));
    registerFallbackValue(Uint8List(0));
  });

  tearDown(DismissibleOverlays.instance.reset);

  setUp(() {
    save = _MockSave();
    when(() => save(any())).thenAnswer((_) async => const Right(null));
    doc = DrawingDocument.emptyMultiPage('A').copyWith(id: 'doc_a');
    leaveCalls = 0;
  });

  Future<ProviderContainer> pumpGuard(
    WidgetTester tester, {
    Future<void> Function()? onLeave,
    List<Override> overrides = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          saveDocumentUseCaseProvider.overrideWithValue(save),
          ...overrides,
        ],
        child: MaterialApp(
          home: EditorLeaveGuard(
            onLeave: onLeave ?? () async => leaveCalls++,
            child: const SizedBox(),
          ),
        ),
      ),
    );
    return ProviderScope.containerOf(tester.element(find.byType(SizedBox)));
  }

  void setLifecycle(WidgetTester tester, List<AppLifecycleState> states) {
    for (final state in states) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
  }

  testWidgets('pausing the app within the debounce saves the stroke',
      (tester) async {
    final container = await pumpGuard(tester);
    container.read(autoSaveProvider.notifier).documentChanged(doc);

    await tester.pump(const Duration(milliseconds: 500));
    setLifecycle(tester, const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]);
    await tester.pump();

    verify(() => save(doc)).called(1);

    await tester.pump(const Duration(seconds: 5));
    verifyNoMoreInteractions(save);

    setLifecycle(tester, const [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]);
  });

  testWidgets('system back goes through onLeave', (tester) async {
    await pumpGuard(tester);

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(leaveCalls, 1);
    expect(find.byType(SizedBox), findsOneWidget);
  });

  testWidgets('a second back while leaving is ignored', (tester) async {
    final done = Completer<void>();
    await pumpGuard(
      tester,
      onLeave: () {
        leaveCalls++;
        return done.future;
      },
    );

    await tester.binding.handlePopRoute();
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(leaveCalls, 1);

    done.complete();
    await tester.pump();
  });

  group('system back (#482)', () {
    testWidgets('closes an open overlay and does not leave', (tester) async {
      await pumpGuard(tester);
      var closed = 0;
      DismissibleOverlays.instance.register(() => closed++);

      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(closed, 1);
      expect(leaveCalls, 0);
    });

    testWidgets('leaves once nothing is open', (tester) async {
      await pumpGuard(tester);
      DismissibleOverlays.instance.register(() {});

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(leaveCalls, 0);

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(leaveCalls, 1);
    });
  });

  group('text being typed (#489)', () {
    void type(ProviderContainer container, String value) {
      final notifier = container.read(textToolProvider.notifier);
      notifier.startNewText(10, 20, layerIndex: 0);
      final active = container.read(textToolProvider).activeText!;
      notifier.updateText(active.copyWith(text: value));
    }

    List<String> savedTexts() {
      final saved =
          verify(() => save(captureAny())).captured.last as DrawingDocument;
      return saved.layers.first.texts.map((t) => t.text).toList();
    }

    testWidgets('Back saves the typed text before leaving', (tester) async {
      late ProviderContainer container;
      container = await pumpGuard(
        tester,
        onLeave: () async {
          await saveBeforeLeavingEditor(container.read);
          leaveCalls++;
        },
      );
      type(container, 'Hello');

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump();

      expect(leaveCalls, 1);
      expect(savedTexts(), ['Hello']);
    });

    testWidgets('pausing the app saves the typed text', (tester) async {
      final container = await pumpGuard(tester);
      type(container, 'Hello');

      setLifecycle(tester, const [AppLifecycleState.inactive]);
      expect(container.read(textToolProvider).isEditing, isTrue);

      setLifecycle(tester, const [
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]);
      await tester.pump();

      expect(container.read(textToolProvider).isEditing, isFalse);
      expect(savedTexts(), ['Hello']);

      setLifecycle(tester, const [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]);
    });
  });

  group('library preview on backgrounding (#528)', () {
    late _MockRepo repo;
    late int renders;
    late LibraryThumbnailWriter writer;

    setUp(() {
      repo = _MockRepo();
      renders = 0;
      when(() => repo.saveThumbnail(any(), any()))
          .thenAnswer((_) async => const Right('thumb.png'));
      writer = LibraryThumbnailWriter(
        enabled: true,
        repository: () => repo,
        render: (page, width, height) async {
          renders++;
          return Uint8List(1);
        },
        idleDelay: const Duration(seconds: 20),
      );
    });

    void resume(WidgetTester tester) => setLifecycle(tester, const [
          AppLifecycleState.hidden,
          AppLifecycleState.inactive,
          AppLifecycleState.resumed,
        ]);

    testWidgets('pausing writes the pending preview without the idle delay',
        (tester) async {
      final container = await pumpGuard(
        tester,
        overrides: [libraryThumbnailWriterProvider.overrideWithValue(writer)],
      );
      container.read(autoSaveProvider.notifier).documentChanged(doc);

      setLifecycle(tester, const [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]);
      await tester.pump();
      await tester.pump();

      verify(() => save(doc)).called(1);
      expect(renders, 1);
      verify(() => repo.saveThumbnail('doc_a', any())).called(1);

      await tester.pump(const Duration(seconds: 30));
      expect(renders, 1);
      resume(tester);
    });

    testWidgets('the observer is removed when the editor closes',
        (tester) async {
      await pumpGuard(
        tester,
        overrides: [libraryThumbnailWriterProvider.overrideWithValue(writer)],
      );
      // The editor closes; the app-wide provider scope stays.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            saveDocumentUseCaseProvider.overrideWithValue(save),
            libraryThumbnailWriterProvider.overrideWithValue(writer),
          ],
          child: const MaterialApp(home: SizedBox()),
        ),
      );
      writer.request(doc);

      setLifecycle(tester, const [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]);
      await tester.pump();
      expect(renders, 0);

      // Only the idle delay writes it now.
      await tester.pump(const Duration(seconds: 20));
      await tester.pump();
      expect(renders, 1);
      resume(tester);
    });
  });
}
