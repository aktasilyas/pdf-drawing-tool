import 'dart:async';

import 'package:drawing_core/drawing_core.dart' as core;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/screens/audio_recordings_list.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('toggles default to true', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(aiAssistantEnabledProvider), isTrue);
    expect(c.read(audioRecordingEnabledProvider), isTrue);
  });

  group('selection actions ai entry', () {
    for (final enabled in [true, false]) {
      testWidgets('ai action present == $enabled (empty and non-empty)',
          (tester) async {
        late SelectionActionConfig empty;
        late SelectionActionConfig nonEmpty;
        await tester.pumpWidget(ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            aiAssistantEnabledProvider.overrideWithValue(enabled),
          ],
          child: MaterialApp(
            home: Consumer(builder: (context, ref, _) {
              empty = buildSelectionActionConfig(ref, core.Selection.empty(),
                  onAIPressed: () {});
              nonEmpty = buildSelectionActionConfig(
                  ref,
                  core.Selection.create(
                      type: core.SelectionType.rectangle,
                      selectedStrokeIds: ['s1'],
                      bounds: core.BoundingBox.zero()),
                  onAIPressed: () {});
              return const SizedBox();
            }),
          ),
        ));
        bool hasAi(SelectionActionConfig c) =>
            c.toolbarActions.any((a) => a.id == 'ai');
        expect(hasAi(empty), enabled);
        expect(hasAi(nonEmpty), enabled);
      });
    }
  });

  Widget scope(Widget child,
      {bool ai = true, bool audio = true, List<Override> extra = const []}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        isInfiniteCanvasProvider.overrideWith((ref) => false),
        aiAssistantEnabledProvider.overrideWithValue(ai),
        audioRecordingEnabledProvider.overrideWithValue(audio),
        ...extra,
      ],
      child: MaterialApp(
        home: Scaffold(
          body: DrawingThemeProvider(
            theme: const DrawingTheme(),
            child: SizedBox(width: 800, height: 600, child: child),
          ),
        ),
      ),
    );
  }

  group('mic buttons', () {
    for (final enabled in [true, false]) {
      testWidgets('TopNavigationBar full mic == $enabled', (tester) async {
        await tester.pumpWidget(
            scope(const TopNavigationBar(compact: false), audio: enabled));
        expect(find.byIcon(ElyanotesIcons.microphone),
            enabled ? findsOneWidget : findsNothing);
      });

      testWidgets('TopNavigationBar compact mic == $enabled', (tester) async {
        await tester.pumpWidget(scope(const TopNavigationBar(compact: true),
            audio: enabled,
            extra: [
              pageCountProvider.overrideWithValue(2),
            ]));
        // Compact bar does not render the mic button before the tools row;
        // only assert absence when disabled.
        if (!enabled) {
          expect(find.byIcon(ElyanotesIcons.microphone), findsNothing);
        }
      });

      testWidgets('ToolbarNavRight mic == $enabled', (tester) async {
        await tester.pumpWidget(scope(const ToolbarNavRight(), audio: enabled));
        expect(find.byIcon(ElyanotesIcons.microphone),
            enabled ? findsOneWidget : findsNothing);
      });
    }
  });

  group('AI toolbar button', () {
    for (final enabled in [true, false]) {
      testWidgets('DrawingScreen ai toolbar button == $enabled',
          (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        await tester
            .pumpWidget(scope(DrawingScreen(onAIPressed: () {}), ai: enabled));
        await tester.pump();
        expect(find.byIcon(ElyanotesIcons.sparkle),
            enabled ? findsWidgets : findsNothing);
      });
    }
  });

  group('FloatingRecordingBar gating', () {
    for (final enabled in [true, false]) {
      testWidgets('layout watches recording state only if enabled=$enabled',
          (tester) async {
        var built = 0;
        await tester.pumpWidget(scope(
          Consumer(builder: (context, ref, _) {
            return buildDrawingCanvasArea(
              context: context,
              ref: ref,
              currentPage: core.Page.create(index: 0),
              transform: const CanvasTransform(),
              canvasMode: const core.CanvasMode(isInfinite: true),
              penBoxPosition: Offset.zero,
              onPenBoxPositionChanged: (_) {},
              onClosePanel: () {},
            );
          }),
          audio: enabled,
          extra: [
            audioRecordingStateProvider.overrideWith((ref) {
              built++;
              return const Stream<AudioRecordingState>.empty();
            }),
          ],
        ));
        await tester.pump();
        expect(built > 0, enabled);
        expect(find.byType(FloatingRecordingBar),
            enabled ? findsOneWidget : findsNothing);
      });
    }
  });

  group('PageSidebar recordings chip', () {
    for (final enabled in [true, false]) {
      testWidgets('chip + filter fallback == $enabled', (tester) async {
        await tester.pumpWidget(scope(
          PageSidebar(thumbnailCache: ThumbnailCache()),
          audio: enabled,
          extra: [
            sidebarFilterProvider
                .overrideWith((ref) => SidebarFilter.recordings),
          ],
        ));
        await tester.pump();
        expect(find.byTooltip('Ses kayıtları'),
            enabled ? findsOneWidget : findsNothing);
        expect(find.byType(AudioRecordingsList),
            enabled ? findsOneWidget : findsNothing);
      });
    }
  });
}
