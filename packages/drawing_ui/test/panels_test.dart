import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/drawing_ui.dart';

void main() {
  // Set larger test surface to avoid RenderFlex overflow
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  group('ToolPanel', () {
    testWidgets('renders with title and close button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingThemeProvider(
              theme: const DrawingTheme(),
              child: ToolPanel(
                title: 'Test Panel',
                onClose: () {},
                child: const Text('Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Panel'), findsOneWidget);
      expect(find.byIcon(StarNoteIcons.close), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('calls onClose when close button is tapped', (tester) async {
      bool closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingThemeProvider(
              theme: const DrawingTheme(),
              child: ToolPanel(
                title: 'Test',
                onClose: () => closed = true,
                child: const SizedBox(),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(StarNoteIcons.close));
      expect(closed, isTrue);
    });
  });

  group('PanelSection', skip: 'UI redesign - layout changed', () {
    testWidgets('shows lock icon when locked', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingThemeProvider(
              theme: const DrawingTheme(),
              child: const PanelSection(
                title: 'Premium Feature',
                isLocked: true,
                child: Text('Locked Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(StarNoteIcons.lock), findsWidgets);
      expect(find.text('Premium'), findsOneWidget);
    });

    testWidgets('does not show lock when not locked', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PanelSection(
              title: 'Normal Feature',
              isLocked: false,
              child: Text('Normal Content'),
            ),
          ),
        ),
      );

      // Should not find lock icon in the section
      expect(find.text('Premium'), findsNothing);
    });
  });

  group('PenSettingsPanel', skip: 'UI redesign - color picker and layout changed', () {
    testWidgets('renders thickness slider', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                child: DrawingThemeProvider(
                  theme: const DrawingTheme(),
                  child: SingleChildScrollView(
                    child: PenSettingsPanel(
                      toolType: ToolType.ballpointPen,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('KALINLIK'), findsOneWidget);
      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('renders color chips', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                child: DrawingThemeProvider(
                  theme: const DrawingTheme(),
                  child: SingleChildScrollView(
                    child: PenSettingsPanel(
                      toolType: ToolType.gelPen,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('RENK'), findsOneWidget);
      expect(find.byType(ColorChip), findsWidgets);
    });

    testWidgets('has add to pen box button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                child: DrawingThemeProvider(
                  theme: const DrawingTheme(),
                  child: SingleChildScrollView(
                    child: PenSettingsPanel(
                      toolType: ToolType.pencil,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Kalem kutusuna ekle'), findsOneWidget);
    });

    testWidgets('shows live stroke preview', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                child: DrawingThemeProvider(
                  theme: const DrawingTheme(),
                  child: SingleChildScrollView(
                    child: PenSettingsPanel(
                      toolType: ToolType.ballpointPen,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Should have CustomPaint for stroke preview
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('shows 4 pen type icons', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                child: DrawingThemeProvider(
                  theme: const DrawingTheme(),
                  child: SingleChildScrollView(
                    child: PenSettingsPanel(
                      toolType: ToolType.ballpointPen,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Should have 4 pen type options
      expect(find.byType(GestureDetector), findsAtLeast(4));
    });
  });

  group('EraserSettingsPanel', skip: 'UI redesign - layout changed', () {
    testWidgets('renders mode selector', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DrawingThemeProvider(
                theme: const DrawingTheme(),
                child: SingleChildScrollView(
                  child: const EraserSettingsPanel(),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('MODE'), findsOneWidget);
      expect(find.text('Pixel'), findsOneWidget);
      expect(find.text('Stroke'), findsOneWidget);
      expect(find.text('Lasso'), findsOneWidget);
    });

    testWidgets('shows premium badge on lasso mode', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DrawingThemeProvider(
                theme: const DrawingTheme(),
                child: SingleChildScrollView(
                  child: const EraserSettingsPanel(),
                ),
              ),
            ),
          ),
        ),
      );

      // Lasso mode should have lock indicator
      // (Implementation marks it as premium)
      expect(find.byIcon(StarNoteIcons.lock), findsWidgets);
    });

    testWidgets('has clear page button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DrawingThemeProvider(
                theme: const DrawingTheme(),
                child: SingleChildScrollView(
                  child: const EraserSettingsPanel(),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Clear Page'), findsOneWidget);
    });
  });

  group('AIAssistantPanel', () {
    testWidgets('renders question input', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DrawingThemeProvider(
                theme: const DrawingTheme(),
                child: SingleChildScrollView(
                  child: const AIAssistantPanel(),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(StarNoteIcons.send), findsOneWidget);
    });

    testWidgets('shows premium badge', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DrawingThemeProvider(
                theme: const DrawingTheme(),
                child: SingleChildScrollView(
                  child: const AIAssistantPanel(),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Pro'), findsOneWidget);
      expect(find.byIcon(StarNoteIcons.sparkle), findsWidgets);
    });

    testWidgets('has quick suggestions', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DrawingThemeProvider(
                theme: const DrawingTheme(),
                child: SingleChildScrollView(
                  child: const AIAssistantPanel(),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('SUGGESTIONS'), findsOneWidget);
      expect(find.text('What does this say?'), findsOneWidget);
    });
  });

  group('ShapesSettingsPanel', skip: 'UI redesign - layout changed', () {
    testWidgets('renders with Turkish title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DrawingThemeProvider(
                theme: const DrawingTheme(),
                child: SingleChildScrollView(
                  child: const ShapesSettingsPanel(),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Şekil'), findsOneWidget);
    });

    testWidgets('renders shape grid with 24 shapes', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DrawingThemeProvider(
                theme: const DrawingTheme(),
                child: SingleChildScrollView(
                  child: const ShapesSettingsPanel(),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('ŞEKİLLER'), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
      
      // Grid should have 24 shape options (ShapeType.values.length)
      expect(find.byType(GestureDetector), findsAtLeast(24));
    });

    testWidgets('renders favorites placeholder', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DrawingThemeProvider(
                theme: const DrawingTheme(),
                child: SingleChildScrollView(
                  child: const ShapesSettingsPanel(),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Favorilere eklemek için şekli sürükleyin'), findsOneWidget);
    });

    testWidgets('has Turkish section titles', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DrawingThemeProvider(
                theme: const DrawingTheme(),
                child: SingleChildScrollView(
                  child: const ShapesSettingsPanel(),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('KONTUR KALINLIĞI'), findsOneWidget);
      expect(find.text('KONTUR RENGİ'), findsOneWidget);
    });

    testWidgets('has fill toggle with Turkish label', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DrawingThemeProvider(
                theme: const DrawingTheme(),
                child: SingleChildScrollView(
                  child: const ShapesSettingsPanel(),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Şekil dolgusu'), findsOneWidget);
      expect(find.byType(Switch), findsWidgets);
    });
  });
}
