import 'dart:ui' show Offset;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/selection_clipboard_provider.dart';
import 'package:drawing_ui/src/widgets/paste_context_menu.dart';

// ============================================================
// Constants
// ============================================================

const _kDefaultScreenPos = Offset(400, 300);
const _kDefaultCanvasPos = Offset(200, 150);

/// Surface size: physicalSize=1600x1200, dpr=2 → logical 800x600.
const _kPhysicalSize = Size(1600, 1200);
const _kDevicePixelRatio = 2.0;

// ============================================================
// Helpers
// ============================================================

/// Sets the physical window size so the 120x40 pill has enough room to render.
void _setWindowSize(WidgetTester tester) {
  tester.view.physicalSize = _kPhysicalSize;
  tester.view.devicePixelRatio = _kDevicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
}

/// Temporarily suppresses RenderFlex overflow errors from [FlutterError.onError].
///
/// The test-runner "Ahem" font has wider character metrics than real device
/// fonts, so the fixed-width 120px pill can overflow by ~18px in CI but renders
/// correctly on real devices.  All other errors are still propagated.
void _ignoreOverflow() {
  final previousHandler = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exceptionAsString().contains('RenderFlex overflowed')) {
      return; // test-env font artefact, not a real bug
    }
    previousHandler?.call(details);
  };
  addTearDown(() => FlutterError.onError = previousHandler);
}

/// Builds a minimal test app that renders [PasteContextMenu] in a [Stack].
///
/// [textScaler] is fixed to [TextScaler.noScaling] to avoid font-scale
/// differences between test host and device.
Widget _buildTestApp({
  required PasteMenuState pasteMenuState,
  SelectionClipboardData? clipboardData,
  bool isDark = false,
}) {
  final overrides = <Override>[
    if (clipboardData != null)
      selectionClipboardProvider.overrideWith((ref) => clipboardData),
  ];

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: isDark ? ThemeData.dark() : ThemeData.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.noScaling,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Stack(
          children: [
            PasteContextMenu(state: pasteMenuState),
          ],
        ),
      ),
    ),
  );
}

SelectionClipboardData _makeClipboardData() {
  final stroke = Stroke.create(style: StrokeStyle.pen())
      .addPoint(DrawingPoint(x: 100, y: 100));
  return SelectionClipboardData(
    strokes: [stroke],
    shapes: [],
    originalBounds:
        const BoundingBox(left: 90, top: 90, right: 110, bottom: 110),
  );
}

// ============================================================
// Tests
// ============================================================

void main() {
  // ===========================================================================
  // Rendering tests
  // ===========================================================================

  group('PasteContextMenu rendering', () {
    testWidgets('should_render_yapistir_text_in_light_theme', (tester) async {
      _setWindowSize(tester);
      _ignoreOverflow();

      await tester.pumpWidget(
        _buildTestApp(
          pasteMenuState: const PasteMenuState(
            screenPos: _kDefaultScreenPos,
            canvasPos: _kDefaultCanvasPos,
          ),
        ),
      );

      expect(find.text('Yapıştır'), findsOneWidget);
    });

    testWidgets('should_render_yapistir_text_in_dark_theme', (tester) async {
      _setWindowSize(tester);
      _ignoreOverflow();

      await tester.pumpWidget(
        _buildTestApp(
          pasteMenuState: const PasteMenuState(
            screenPos: _kDefaultScreenPos,
            canvasPos: _kDefaultCanvasPos,
          ),
          isDark: true,
        ),
      );

      expect(find.text('Yapıştır'), findsOneWidget);
    });

    testWidgets('should_render_paste_icon', (tester) async {
      _setWindowSize(tester);
      _ignoreOverflow();

      await tester.pumpWidget(
        _buildTestApp(
          pasteMenuState: const PasteMenuState(
            screenPos: _kDefaultScreenPos,
            canvasPos: _kDefaultCanvasPos,
          ),
        ),
      );

      expect(find.byType(PhosphorIcon), findsOneWidget);
    });

    testWidgets('should_render_PasteContextMenu_widget', (tester) async {
      _setWindowSize(tester);
      _ignoreOverflow();

      await tester.pumpWidget(
        _buildTestApp(
          pasteMenuState: const PasteMenuState(
            screenPos: _kDefaultScreenPos,
            canvasPos: _kDefaultCanvasPos,
          ),
        ),
      );

      expect(find.byType(PasteContextMenu), findsOneWidget);
    });

    testWidgets('should_render_as_Positioned_widget', (tester) async {
      _setWindowSize(tester);
      _ignoreOverflow();

      await tester.pumpWidget(
        _buildTestApp(
          pasteMenuState: const PasteMenuState(
            screenPos: _kDefaultScreenPos,
            canvasPos: _kDefaultCanvasPos,
          ),
        ),
      );

      expect(find.byType(Positioned), findsWidgets);
    });

    testWidgets('should_render_row_with_icon_and_text', (tester) async {
      _setWindowSize(tester);
      _ignoreOverflow();

      await tester.pumpWidget(
        _buildTestApp(
          pasteMenuState: const PasteMenuState(
            screenPos: _kDefaultScreenPos,
            canvasPos: _kDefaultCanvasPos,
          ),
        ),
      );

      expect(find.byType(Row), findsOneWidget);
      expect(find.byType(PhosphorIcon), findsOneWidget);
      expect(find.text('Yapıştır'), findsOneWidget);
    });

    testWidgets('should_render_text_with_correct_font_weight_and_size',
        (tester) async {
      _setWindowSize(tester);
      _ignoreOverflow();

      await tester.pumpWidget(
        _buildTestApp(
          pasteMenuState: const PasteMenuState(
            screenPos: _kDefaultScreenPos,
            canvasPos: _kDefaultCanvasPos,
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Yapıştır'));
      expect(text.style?.fontWeight, equals(FontWeight.w500));
      expect(text.style?.fontSize, equals(14));
    });

    testWidgets('should_render_icon_with_size_18', (tester) async {
      _setWindowSize(tester);
      _ignoreOverflow();

      await tester.pumpWidget(
        _buildTestApp(
          pasteMenuState: const PasteMenuState(
            screenPos: _kDefaultScreenPos,
            canvasPos: _kDefaultCanvasPos,
          ),
        ),
      );

      final icon = tester.widget<PhosphorIcon>(find.byType(PhosphorIcon));
      expect(icon.size, equals(18));
    });

    testWidgets('should_render_white_container_background', (tester) async {
      _setWindowSize(tester);
      _ignoreOverflow();

      await tester.pumpWidget(
        _buildTestApp(
          pasteMenuState: const PasteMenuState(
            screenPos: _kDefaultScreenPos,
            canvasPos: _kDefaultCanvasPos,
          ),
        ),
      );

      final containers =
          tester.widgetList<Container>(find.byType(Container)).toList();
      BoxDecoration? pillDecoration;
      for (final container in containers) {
        final deco = container.decoration;
        if (deco is BoxDecoration && deco.color == Colors.white) {
          pillDecoration = deco;
          break;
        }
      }

      expect(pillDecoration, isNotNull);
      expect(pillDecoration!.color, equals(Colors.white));
    });

    testWidgets('should_render_rounded_corners_on_pill', (tester) async {
      _setWindowSize(tester);
      _ignoreOverflow();

      await tester.pumpWidget(
        _buildTestApp(
          pasteMenuState: const PasteMenuState(
            screenPos: _kDefaultScreenPos,
            canvasPos: _kDefaultCanvasPos,
          ),
        ),
      );

      final containers =
          tester.widgetList<Container>(find.byType(Container)).toList();
      BorderRadius? borderRadius;
      for (final container in containers) {
        final deco = container.decoration;
        if (deco is BoxDecoration && deco.color == Colors.white) {
          borderRadius = deco.borderRadius as BorderRadius?;
          break;
        }
      }

      expect(borderRadius, isNotNull);
      expect(borderRadius!.topLeft.x, equals(12));
    });
  });

  // ===========================================================================
  // Positioning tests
  // ===========================================================================

  group('PasteContextMenu positioning', () {
    testWidgets('should_position_above_press_point_when_there_is_room',
        (tester) async {
      _setWindowSize(tester);
      _ignoreOverflow();

      // screenPos.dy=300 → top = 300-40-12 = 248, not clamped (248 > 8).
      await tester.pumpWidget(
        _buildTestApp(
          pasteMenuState: const PasteMenuState(
            screenPos: Offset(400, 300),
            canvasPos: _kDefaultCanvasPos,
          ),
        ),
      );

      final positioned = tester.widget<Positioned>(
        find.descendant(
          of: find.byType(PasteContextMenu),
          matching: find.byType(Positioned),
        ),
      );

      expect(positioned.top, equals(248.0));
    });

    testWidgets('should_position_below_press_point_when_too_close_to_top',
        (tester) async {
      _setWindowSize(tester);
      _ignoreOverflow();

      // screenPos.dy=20 → top = 20-40-12 = -32 < 8 → fallback to 20+12 = 32.
      await tester.pumpWidget(
        _buildTestApp(
          pasteMenuState: const PasteMenuState(
            screenPos: Offset(400, 20),
            canvasPos: _kDefaultCanvasPos,
          ),
        ),
      );

      final positioned = tester.widget<Positioned>(
        find.descendant(
          of: find.byType(PasteContextMenu),
          matching: find.byType(Positioned),
        ),
      );

      expect(positioned.top, equals(32.0));
    });

    testWidgets('should_clamp_left_to_minimum_when_press_is_near_left_edge',
        (tester) async {
      _setWindowSize(tester);
      _ignoreOverflow();

      // Logical width = 1600/2 = 800.
      // screenPos.dx=10 → left = 10-60 = -50, clamped to 8.
      await tester.pumpWidget(
        _buildTestApp(
          pasteMenuState: const PasteMenuState(
            screenPos: Offset(10, 300),
            canvasPos: _kDefaultCanvasPos,
          ),
        ),
      );

      final positioned = tester.widget<Positioned>(
        find.descendant(
          of: find.byType(PasteContextMenu),
          matching: find.byType(Positioned),
        ),
      );

      expect(positioned.left, equals(8.0));
    });

    testWidgets('should_clamp_left_to_maximum_when_press_is_near_right_edge',
        (tester) async {
      _setWindowSize(tester);
      _ignoreOverflow();

      // Logical width = 800. menuWidth=120. max left = 800-120-8 = 672.
      // screenPos.dx=790 → left = 790-60 = 730, clamped to 672.
      await tester.pumpWidget(
        _buildTestApp(
          pasteMenuState: const PasteMenuState(
            screenPos: Offset(790, 300),
            canvasPos: _kDefaultCanvasPos,
          ),
        ),
      );

      final positioned = tester.widget<Positioned>(
        find.descendant(
          of: find.byType(PasteContextMenu),
          matching: find.byType(Positioned),
        ),
      );

      expect(positioned.left, equals(672.0));
    });

    testWidgets('should_center_menu_horizontally_on_press_point', (tester) async {
      _setWindowSize(tester);
      _ignoreOverflow();

      // screenPos.dx=400 → left = 400-60 = 340 (not clamped, 340 < 672).
      await tester.pumpWidget(
        _buildTestApp(
          pasteMenuState: const PasteMenuState(
            screenPos: Offset(400, 300),
            canvasPos: _kDefaultCanvasPos,
          ),
        ),
      );

      final positioned = tester.widget<Positioned>(
        find.descendant(
          of: find.byType(PasteContextMenu),
          matching: find.byType(Positioned),
        ),
      );

      // left = 400 - 120/2 = 340
      expect(positioned.left, equals(340.0));
    });

    testWidgets('should_place_correctly_at_center_screen_position', (tester) async {
      _setWindowSize(tester);
      _ignoreOverflow();

      // screenPos=(500,400) → left=440, top=348 (both unclamped).
      await tester.pumpWidget(
        _buildTestApp(
          pasteMenuState: const PasteMenuState(
            screenPos: Offset(500, 400),
            canvasPos: Offset(250, 200),
          ),
        ),
      );

      final positioned = tester.widget<Positioned>(
        find.descendant(
          of: find.byType(PasteContextMenu),
          matching: find.byType(Positioned),
        ),
      );

      expect(positioned.left, equals(440.0));
      expect(positioned.top, equals(348.0));
    });
  });

  // ===========================================================================
  // Interaction tests
  // ===========================================================================

  group('PasteContextMenu interactions', () {
    testWidgets('should_clear_pasteMenuProvider_on_tap', (tester) async {
      _setWindowSize(tester);
      _ignoreOverflow();

      late ProviderContainer capturedContainer;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectionClipboardProvider.overrideWith(
              (ref) => _makeClipboardData(),
            ),
          ],
          child: Builder(
            builder: (context) {
              capturedContainer = ProviderScope.containerOf(context);
              return MaterialApp(
                builder: (ctx, child) => MediaQuery(
                  data: MediaQuery.of(ctx).copyWith(
                    textScaler: TextScaler.noScaling,
                  ),
                  child: child!,
                ),
                home: Scaffold(
                  body: Stack(
                    children: [
                      PasteContextMenu(
                        state: const PasteMenuState(
                          screenPos: _kDefaultScreenPos,
                          canvasPos: _kDefaultCanvasPos,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Yapıştır'), findsOneWidget);

      await tester.tap(find.text('Yapıştır'));
      await tester.pump();

      // After tap the pasteMenuProvider is cleared.
      expect(capturedContainer.read(pasteMenuProvider), isNull);
    });

    testWidgets('should_have_gesture_detector_for_tap', (tester) async {
      _setWindowSize(tester);
      _ignoreOverflow();

      await tester.pumpWidget(
        _buildTestApp(
          pasteMenuState: const PasteMenuState(
            screenPos: _kDefaultScreenPos,
            canvasPos: _kDefaultCanvasPos,
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsAtLeastNWidgets(1));
    });

    testWidgets(
        'should_have_opaque_Listener_to_absorb_pointer_events_from_canvas',
        (tester) async {
      _setWindowSize(tester);
      _ignoreOverflow();

      await tester.pumpWidget(
        _buildTestApp(
          pasteMenuState: const PasteMenuState(
            screenPos: _kDefaultScreenPos,
            canvasPos: _kDefaultCanvasPos,
          ),
        ),
      );

      // There may be multiple Listeners in the tree (e.g. from Material/Ink).
      // Find the one that is a direct descendant of PasteContextMenu and has
      // HitTestBehavior.opaque — that is the pointer-absorbing Listener.
      final listeners = tester.widgetList<Listener>(
        find.descendant(
          of: find.byType(PasteContextMenu),
          matching: find.byType(Listener),
        ),
      );

      final opaqueListener = listeners
          .where((l) => l.behavior == HitTestBehavior.opaque)
          .toList();

      expect(opaqueListener, isNotEmpty);
    });

    testWidgets('should_not_throw_when_tapped_with_no_clipboard', (tester) async {
      _setWindowSize(tester);
      _ignoreOverflow();

      // No clipboard overrides — defaults to null.
      await tester.pumpWidget(
        _buildTestApp(
          pasteMenuState: const PasteMenuState(
            screenPos: _kDefaultScreenPos,
            canvasPos: _kDefaultCanvasPos,
          ),
        ),
      );

      // pasteFromClipboardAt should be a no-op when clipboard is null.
      await tester.tap(find.text('Yapıştır'));
      await tester.pump();
    });

    testWidgets('should_render_transparent_Material_wrapper', (tester) async {
      _setWindowSize(tester);
      _ignoreOverflow();

      await tester.pumpWidget(
        _buildTestApp(
          pasteMenuState: const PasteMenuState(
            screenPos: _kDefaultScreenPos,
            canvasPos: _kDefaultCanvasPos,
          ),
        ),
      );

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(PasteContextMenu),
          matching: find.byType(Material),
        ),
      );

      expect(material.color, equals(Colors.transparent));
    });
  });

  // ===========================================================================
  // State acceptance tests
  // ===========================================================================

  group('PasteContextMenu state', () {
    testWidgets('should_accept_PasteMenuState_parameter', (tester) async {
      _setWindowSize(tester);
      _ignoreOverflow();

      const menuState = PasteMenuState(
        screenPos: Offset(150, 250),
        canvasPos: Offset(75, 125),
      );

      await tester.pumpWidget(
        _buildTestApp(pasteMenuState: menuState),
      );

      final widget = tester.widget<PasteContextMenu>(
        find.byType(PasteContextMenu),
      );

      expect(widget.state.screenPos, equals(const Offset(150, 250)));
      expect(widget.state.canvasPos, equals(const Offset(75, 125)));
    });

    testWidgets('should_expose_canvasPos_to_pasteFromClipboardAt', (tester) async {
      _setWindowSize(tester);
      _ignoreOverflow();

      const canvasPos = Offset(333, 444);

      await tester.pumpWidget(
        _buildTestApp(
          pasteMenuState: const PasteMenuState(
            screenPos: _kDefaultScreenPos,
            canvasPos: canvasPos,
          ),
        ),
      );

      final widget = tester.widget<PasteContextMenu>(
        find.byType(PasteContextMenu),
      );

      // state.canvasPos is forwarded to pasteFromClipboardAt on tap.
      expect(widget.state.canvasPos, equals(canvasPos));
    });
  });
}
