import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';

void main() {
  group('PaperSizePicker', () {
    testWidgets('renders with selected size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaperSizePicker(
              selectedSize: PaperSize.a4,
              onSizeSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(PaperSizePicker), findsOneWidget);
      expect(find.text('A4'), findsOneWidget);
    });

    testWidgets('shows dropdown with all presets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaperSizePicker(
              selectedSize: PaperSize.a4,
              onSizeSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(DropdownButton<PaperSizePreset>), findsOneWidget);
    });

    testWidgets('shows orientation toggle by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaperSizePicker(
              selectedSize: PaperSize.a4,
              onSizeSelected: (_) {},
            ),
          ),
        ),
      );

      final orientationIcon = find.byWidgetPredicate(
        (widget) => widget is PhosphorIcon && widget.icon == StarNoteIcons.orientationPortrait,
      );
      expect(orientationIcon, findsOneWidget);
    });

    testWidgets('hides orientation toggle when showLandscapeToggle is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaperSizePicker(
              selectedSize: PaperSize.a4,
              onSizeSelected: (_) {},
              showLandscapeToggle: false,
            ),
          ),
        ),
      );

      final portraitIcon = find.byWidgetPredicate(
        (widget) => widget is PhosphorIcon && widget.icon == StarNoteIcons.orientationPortrait,
      );
      final landscapeIcon = find.byWidgetPredicate(
        (widget) => widget is PhosphorIcon && widget.icon == StarNoteIcons.orientationLandscape,
      );
      expect(portraitIcon, findsNothing);
      expect(landscapeIcon, findsNothing);
    });

    testWidgets('shows portrait icon for portrait orientation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaperSizePicker(
              selectedSize: PaperSize.a4, // Default is portrait
              onSizeSelected: (_) {},
            ),
          ),
        ),
      );

      final portraitIcon = find.byWidgetPredicate(
        (widget) => widget is PhosphorIcon && widget.icon == StarNoteIcons.orientationPortrait,
      );
      final landscapeIcon = find.byWidgetPredicate(
        (widget) => widget is PhosphorIcon && widget.icon == StarNoteIcons.orientationLandscape,
      );
      expect(portraitIcon, findsOneWidget);
      expect(landscapeIcon, findsNothing);
    });

    testWidgets('shows landscape icon for landscape orientation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaperSizePicker(
              selectedSize: PaperSize.a4.landscape,
              onSizeSelected: (_) {},
            ),
          ),
        ),
      );

      final landscapeIcon = find.byWidgetPredicate(
        (widget) => widget is PhosphorIcon && widget.icon == StarNoteIcons.orientationLandscape,
      );
      final portraitIcon = find.byWidgetPredicate(
        (widget) => widget is PhosphorIcon && widget.icon == StarNoteIcons.orientationPortrait,
      );
      expect(landscapeIcon, findsOneWidget);
      expect(portraitIcon, findsNothing);
    });

    testWidgets('calls onSizeSelected when preset changes', (tester) async {
      PaperSize? newSize;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaperSizePicker(
              selectedSize: PaperSize.a4,
              onSizeSelected: (size) {
                newSize = size;
              },
            ),
          ),
        ),
      );

      // Tap dropdown
      await tester.tap(find.byType(DropdownButton<PaperSizePreset>));
      await tester.pumpAndSettle();

      // Select A5
      await tester.tap(find.text('A5').last);
      await tester.pumpAndSettle();

      expect(newSize, isNotNull);
      expect(newSize?.preset, PaperSizePreset.a5);
    });

    testWidgets('preserves orientation when changing preset', (tester) async {
      PaperSize? newSize;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaperSizePicker(
              selectedSize: PaperSize.a4.landscape,
              onSizeSelected: (size) {
                newSize = size;
              },
            ),
          ),
        ),
      );

      // Tap dropdown
      await tester.tap(find.byType(DropdownButton<PaperSizePreset>));
      await tester.pumpAndSettle();

      // Select A5
      await tester.tap(find.text('A5').last);
      await tester.pumpAndSettle();

      expect(newSize, isNotNull);
      expect(newSize?.preset, PaperSizePreset.a5);
      expect(newSize?.isLandscape, true);
    });

    testWidgets('toggles orientation when toggle button tapped', (tester) async {
      PaperSize? newSize;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaperSizePicker(
              selectedSize: PaperSize.a4,
              onSizeSelected: (size) {
                newSize = size;
              },
            ),
          ),
        ),
      );

      // Tap orientation toggle
      final orientationIcon = find.byWidgetPredicate(
        (widget) => widget is PhosphorIcon && widget.icon == StarNoteIcons.orientationPortrait,
      );
      await tester.tap(orientationIcon);
      await tester.pumpAndSettle();

      expect(newSize, isNotNull);
      expect(newSize?.preset, PaperSizePreset.a4);
      expect(newSize?.isLandscape, true);
    });

    testWidgets('toggles from landscape to portrait', (tester) async {
      PaperSize? newSize;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaperSizePicker(
              selectedSize: PaperSize.a4.landscape,
              onSizeSelected: (size) {
                newSize = size;
              },
            ),
          ),
        ),
      );

      // Tap orientation toggle
      final orientationIcon = find.byWidgetPredicate(
        (widget) => widget is PhosphorIcon && widget.icon == StarNoteIcons.orientationLandscape,
      );
      await tester.tap(orientationIcon);
      await tester.pumpAndSettle();

      expect(newSize, isNotNull);
      expect(newSize?.preset, PaperSizePreset.a4);
      expect(newSize?.isLandscape, false);
    });

    testWidgets('displays correct names for all presets', (tester) async {
      final presetNames = {
        PaperSizePreset.a4: 'A4',
        PaperSizePreset.a5: 'A5',
        PaperSizePreset.a6: 'A6',
        PaperSizePreset.letter: 'Letter',
        PaperSizePreset.legal: 'Legal',
        PaperSizePreset.square: 'Kare',
        PaperSizePreset.widescreen: 'Geniş (16:9)',
      };

      for (final entry in presetNames.entries) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PaperSizePicker(
                selectedSize: PaperSize.fromPreset(entry.key),
                onSizeSelected: (_) {},
              ),
            ),
          ),
        );

        expect(find.text(entry.value), findsOneWidget);
      }
    });

    testWidgets('opens dropdown when tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaperSizePicker(
              selectedSize: PaperSize.a4,
              onSizeSelected: (_) {},
            ),
          ),
        ),
      );

      // Tap dropdown
      await tester.tap(find.byType(DropdownButton<PaperSizePreset>));
      await tester.pumpAndSettle();

      // Check that all options are visible
      expect(find.text('A4'), findsWidgets);
      expect(find.text('A5'), findsOneWidget);
      expect(find.text('Letter'), findsOneWidget);
    });

    testWidgets('uses theme colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.dark(
              surfaceContainerHigh: Colors.grey,
              onSurfaceVariant: Colors.white,
            ),
          ),
          home: Scaffold(
            body: PaperSizePicker(
              selectedSize: PaperSize.a4,
              onSizeSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(PaperSizePicker), findsOneWidget);
    });

    testWidgets('renders with different sizes', (tester) async {
      final sizes = [
        PaperSize.a4,
        PaperSize.a5,
        PaperSize.letter,
        PaperSize.legal,
      ];

      for (final size in sizes) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PaperSizePicker(
                selectedSize: size,
                onSizeSelected: (_) {},
              ),
            ),
          ),
        );

        expect(find.byType(PaperSizePicker), findsOneWidget);
      }
    });

    testWidgets('orientation toggle has correct padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaperSizePicker(
              selectedSize: PaperSize.a4,
              onSizeSelected: (_) {},
            ),
          ),
        ),
      );

      final orientationIcon = find.byWidgetPredicate(
        (widget) => widget is PhosphorIcon && widget.icon == StarNoteIcons.orientationPortrait,
      );
      final container = tester.widget<Container>(
        find.ancestor(
          of: orientationIcon,
          matching: find.byType(Container),
        ).first,
      );

      expect(container.padding, const EdgeInsets.all(8));
    });

    testWidgets('dropdown has correct styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaperSizePicker(
              selectedSize: PaperSize.a4,
              onSizeSelected: (_) {},
            ),
          ),
        ),
      );

      final dropdown = tester.widget<DropdownButton<PaperSizePreset>>(
        find.byType(DropdownButton<PaperSizePreset>),
      );

      expect(dropdown.icon, isA<Icon>());
    });
  });
}
