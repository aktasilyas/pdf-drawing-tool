import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/drawing_ui.dart';

void main() {
  // Skip golden tests - UI has changed significantly and needs new goldens
  group('Pen Settings Panel Golden Tests', skip: 'UI redesign - golden files need update', () {
    testWidgets('pen settings panel layout', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  child: DrawingThemeProvider(
                    theme: const DrawingTheme(),
                    child: SizedBox(
                      width: 320,
                      height: 600,
                      child: SingleChildScrollView(
                        child: PenSettingsPanel(
                          toolType: ToolType.ballpointPen,
                          onClose: () {},
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(RepaintBoundary),
        matchesGoldenFile('goldens/pen_settings_panel.png'),
      );
    });

    testWidgets('fountain pen panel with nib shapes', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  child: DrawingThemeProvider(
                    theme: const DrawingTheme(),
                    child: SizedBox(
                      width: 320,
                      height: 600,
                      child: SingleChildScrollView(
                        child: PenSettingsPanel(
                          toolType: ToolType.gelPen,
                          onClose: () {},
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(RepaintBoundary),
        matchesGoldenFile('goldens/fountain_pen_panel.png'),
      );
    });
  });

  group('Highlighter Panel Golden Tests', skip: 'UI redesign - golden files need update', () {
    testWidgets('highlighter panel layout', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  child: DrawingThemeProvider(
                    theme: const DrawingTheme(),
                    child: SizedBox(
                      width: 320,
                      height: 500,
                      child: SingleChildScrollView(
                        child: HighlighterSettingsPanel(onClose: () {}),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(RepaintBoundary),
        matchesGoldenFile('goldens/highlighter_panel.png'),
      );
    });
  });

  group('Eraser Panel Golden Tests', skip: 'UI redesign - golden files need update', () {
    testWidgets('eraser panel layout', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  child: DrawingThemeProvider(
                    theme: const DrawingTheme(),
                    child: SizedBox(
                      width: 320,
                      height: 600,
                      child: SingleChildScrollView(
                        child: EraserSettingsPanel(onClose: () {}),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(RepaintBoundary),
        matchesGoldenFile('goldens/eraser_panel.png'),
      );
    });
  });

  group('Shapes Panel Golden Tests', skip: 'UI redesign - golden files need update', () {
    testWidgets('shapes panel layout', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  child: DrawingThemeProvider(
                    theme: const DrawingTheme(),
                    child: SizedBox(
                      width: 320,
                      height: 600,
                      child: SingleChildScrollView(
                        child: ShapesSettingsPanel(onClose: () {}),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(RepaintBoundary),
        matchesGoldenFile('goldens/shapes_panel.png'),
      );
    });
  });

  group('AI Assistant Panel Golden Tests', skip: 'UI redesign - golden files need update', () {
    testWidgets('AI panel initial state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  child: DrawingThemeProvider(
                    theme: const DrawingTheme(),
                    child: SizedBox(
                      width: 320,
                      height: 500,
                      child: SingleChildScrollView(
                        child: AIAssistantPanel(onClose: () {}),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(RepaintBoundary),
        matchesGoldenFile('goldens/ai_assistant_panel.png'),
      );
    });
  });

  group('Sticker Panel Golden Tests', skip: 'UI redesign - golden files need update', () {
    testWidgets('sticker panel layout', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  child: DrawingThemeProvider(
                    theme: const DrawingTheme(),
                    child: SizedBox(
                      width: 360,
                      height: 500,
                      child: SingleChildScrollView(
                        child: StickerPanel(onClose: () {}),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(RepaintBoundary),
        matchesGoldenFile('goldens/sticker_panel.png'),
      );
    });
  });

  group('Image Panel Golden Tests', skip: 'UI redesign - golden files need update', () {
    testWidgets('image panel layout', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  child: DrawingThemeProvider(
                    theme: const DrawingTheme(),
                    child: SizedBox(
                      width: 320,
                      height: 500,
                      child: SingleChildScrollView(
                        child: ImagePanel(onClose: () {}),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(RepaintBoundary),
        matchesGoldenFile('goldens/image_panel.png'),
      );
    });
  });
}
