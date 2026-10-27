import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:example_app/core/core.dart';
import 'package:example_app/features/editor/editor.dart';
import 'package:example_app/features/editor/presentation/widgets/editor_dialogs.dart';

import '../../../../helpers/l10n.dart';

class _MockSave extends Mock implements SaveDocumentUseCase {}

const _tr = Locale('tr');
const _en = Locale('en');

Future<void> _pump(WidgetTester tester, Locale locale, Widget home) async {
  tester.view.physicalSize = const Size(380, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: localizedApp(
        theme: AppTheme.light,
        locale: locale,
        home: MediaQuery.withClampedTextScaling(
          minScaleFactor: 1.3,
          maxScaleFactor: 1.3,
          child: home,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('RenameDocumentDialog', () {
    Widget host() => Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<String>(
              context: context,
              builder: (_) => const RenameDocumentDialog(initialTitle: 'Doc'),
            ),
            child: const Text('open'),
          ),
        );

    final cases = {
      _tr: ['Yeniden Adlandır', 'Belge Adı', 'İptal', 'Kaydet'],
      _en: ['Rename', 'Document name', 'Cancel', 'Save'],
    };
    for (final entry in cases.entries) {
      testWidgets('shows ${entry.key} copy at text scale 1.3', (tester) async {
        await _pump(tester, entry.key, Scaffold(body: host()));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        final texts = entry.value;
        expect(find.text(texts[0]), findsOneWidget);
        expect(find.text(texts[1]), findsOneWidget);
        expect(find.text(texts[2]), findsOneWidget);
        expect(find.text(texts[3]), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Save pops the trimmed title', (tester) async {
      String? result;
      await _pump(
        tester,
        _en,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await showDialog<String>(
                context: context,
                builder: (_) => const RenameDocumentDialog(initialTitle: 'Doc'),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '  New  ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(result, 'New');
    });
  });

  group('MoveToTrashDialog', () {
    testWidgets('tr and en copy, no overflow at 1.3', (tester) async {
      for (final (locale, title, message) in [
        (
          _tr,
          'Çöpe Taşı',
          'Bu belge çöpe taşınacak. Daha sonra geri yükleyebilirsiniz.',
        ),
        (
          _en,
          'Move to trash',
          'This document will be moved to the trash. You can restore it '
              'later.',
        ),
      ]) {
        await _pump(tester, locale, const MoveToTrashDialog());
        expect(find.text(title), findsWidgets);
        expect(find.text(message), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('EditorLoadErrorView', () {
    for (final (locale, texts) in [
      (_tr, ['Belge açılamadı', 'Geri dön', 'Tekrar dene']),
      (_en, ["Couldn't open the document", 'Go back', 'Try again']),
    ]) {
      testWidgets('shows $locale copy at text scale 1.3', (tester) async {
        var retried = false;
        await _pump(
          tester,
          locale,
          EditorLoadErrorView(onRetry: () => retried = true, onBack: () {}),
        );
        for (final t in texts) {
          expect(find.text(t), findsOneWidget);
        }
        await tester.tap(find.text(texts[2]));
        expect(retried, isTrue);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('SaveFailureBanner', () {
    for (final (locale, message, retry) in [
      (
        _tr,
        'Kaydedilemedi. Değişiklikleriniz henüz kaydedilmedi.',
        'Tekrar dene',
      ),
      (_en, "Couldn't save. Your changes haven't been saved yet.", 'Try again'),
    ]) {
      testWidgets('shows $locale copy at text scale 1.3', (tester) async {
        final save = _MockSave();
        registerFallbackValue(DrawingDocument.emptyMultiPage('fallback'));
        when(() => save(any()))
            .thenAnswer((_) async => const Left(CacheFailure('disk full')));
        tester.view.physicalSize = const Size(380, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final container = ProviderContainer(
          overrides: [saveDocumentUseCaseProvider.overrideWithValue(save)],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: localizedApp(
              theme: AppTheme.light,
              locale: locale,
              home: MediaQuery.withClampedTextScaling(
                minScaleFactor: 1.3,
                maxScaleFactor: 1.3,
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
        await container.read(autoSaveProvider.notifier).saveNow(
              DrawingDocument.emptyMultiPage('A').copyWith(id: 'doc_a'),
            );
        await tester.pump(const Duration(seconds: 10));
        expect(find.text(message), findsOneWidget);
        expect(find.text(retry), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
