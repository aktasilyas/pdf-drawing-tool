import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:example_app/core/config/feature_flags.dart';
import 'package:example_app/features/ai/data/services/canvas_capture_service.dart';
import 'package:example_app/features/ai/domain/repositories/ai_repository.dart';
import 'package:example_app/features/ai/presentation/providers/ai_providers.dart';
import 'package:example_app/features/ai/presentation/widgets/ai_chat_floating.dart';
import 'package:example_app/features/ai/presentation/widgets/ai_chat_sidebar.dart';
import 'package:example_app/features/editor/presentation/widgets/editor_body.dart';

class _MockAIRepository extends Mock implements AIRepository {}

/// Chat notifier that never touches Supabase.
class _FakeChatNotifier extends AIChatNotifier {
  _FakeChatNotifier()
      : super(
          repository: _MockAIRepository(),
          captureService: CanvasCaptureService(),
        );

  @override
  Future<void> initialize({String? existingConversationId}) async {}
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pumpBody(
    WidgetTester tester, {
    required FeatureFlags flags,
    bool aiOpen = false,
    AIChatViewMode? mode,
  }) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          featureFlagsProvider.overrideWithValue(flags),
          sharedPreferencesProvider.overrideWithValue(prefs),
          aiChatProvider.overrideWith((ref) => _FakeChatNotifier()),
          aiSidebarOpenProvider.overrideWith((ref) => aiOpen),
          if (mode != null) aiChatViewModeProvider.overrideWith((ref) => mode),
        ],
        child: MaterialApp(
          home: EditorBody(
            documentTitle: 't',
            canvasMode: CanvasMode.whiteboard,
            onHomePressed: () {},
            onRenameDocument: () {},
            onDeleteDocument: () {},
            onDocumentChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  DrawingScreen screen(WidgetTester tester) =>
      tester.widget<DrawingScreen>(find.byType(DrawingScreen));

  group('AI off', () {
    testWidgets('onAIPressed is null and no AI panels, even if "open"',
        (tester) async {
      await pumpBody(tester, flags: FeatureFlags.allOff, aiOpen: true);
      expect(screen(tester).onAIPressed, isNull);
      expect(screen(tester).isExternalLeftSidebarOpen, isFalse);
      expect(screen(tester).externalLeftSidebar, isNull);
      expect(find.byType(AIChatSidebar), findsNothing);
      expect(find.byType(AIFloatingChat), findsNothing);
    });

    testWidgets('floating mode shows no floating chat', (tester) async {
      await pumpBody(
        tester,
        flags: FeatureFlags.allOff,
        aiOpen: true,
        mode: AIChatViewMode.floating,
      );
      expect(find.byType(AIFloatingChat), findsNothing);
    });
  });

  group('AI on', () {
    testWidgets('onAIPressed is wired and sidebar is provided', (tester) async {
      await pumpBody(tester, flags: const FeatureFlags(aiChat: true));
      expect(screen(tester).onAIPressed, isNotNull);
      expect(screen(tester).externalLeftSidebar, isA<AIChatSidebar>());
    });
  });
}
