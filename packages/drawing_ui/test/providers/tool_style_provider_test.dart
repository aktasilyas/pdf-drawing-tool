import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/drawing_providers.dart';
import 'package:drawing_ui/src/providers/tool_style_provider.dart';
import 'package:drawing_ui/src/models/tool_type.dart';

void main() {
  // ===========================================================================
  // activeStrokeStyleProvider Tests
  // ===========================================================================

  group('activeStrokeStyleProvider', () {
    test('returns pen style when ballpointPen is selected', () {
      final container = ProviderContainer();

      // Default tool is ballpointPen
      final style = container.read(activeStrokeStyleProvider);

      expect(style.isEraser, false);
      expect(style.opacity, 1.0);
      expect(style.blendMode, DrawingBlendMode.normal);

      container.dispose();
    });

    test('returns pen style with correct settings', () {
      final container = ProviderContainer();

      // Default ballpointPen settings
      final style = container.read(activeStrokeStyleProvider);

      // Default thickness is 1.5 for ballpointPen
      expect(style.thickness, 1.5);
      // Default color is black (0xFF000000)
      expect(style.color, 0xFF000000);
      expect(style.nibShape, NibShape.circle);

      container.dispose();
    });

    test('returns highlighter style with 0.4 opacity', () {
      final container = ProviderContainer(
        overrides: [
          currentToolProvider.overrideWith((ref) => CurrentToolNotifier(null, initialTool: ToolType.highlighter)),
        ],
      );

      final style = container.read(activeStrokeStyleProvider);

      expect(style.opacity, 0.4); // Updated from 0.5 to 0.4
      expect(style.nibShape, NibShape.rectangle);
      expect(style.isEraser, false);

      container.dispose();
    });

    test('returns eraser style with isEraser true', () {
      final container = ProviderContainer(
        overrides: [
          currentToolProvider.overrideWith((ref) => CurrentToolNotifier(null, initialTool: ToolType.pixelEraser)),
        ],
      );

      final style = container.read(activeStrokeStyleProvider);

      expect(style.isEraser, true);
      expect(style.color, 0xFFFFFFFF); // White

      container.dispose();
    });

    test('returns brush style with ellipse nib', () {
      final container = ProviderContainer(
        overrides: [
          currentToolProvider.overrideWith((ref) => CurrentToolNotifier(null, initialTool: ToolType.brushPen)),
        ],
      );

      final style = container.read(activeStrokeStyleProvider);

      expect(style.nibShape, NibShape.ellipse);
      expect(style.isEraser, false);

      container.dispose();
    });

    test('returns default style for non-drawing tools', () {
      final container = ProviderContainer(
        overrides: [
          currentToolProvider.overrideWith((ref) => CurrentToolNotifier(null, initialTool: ToolType.shapes)),
        ],
      );

      final style = container.read(activeStrokeStyleProvider);

      // Should return default pen style
      expect(style.isEraser, false);

      container.dispose();
    });

    test('updates when tool changes', () {
      final container = ProviderContainer();

      // Initial: ballpointPen
      var style = container.read(activeStrokeStyleProvider);
      expect(style.opacity, 1.0);

      // Change to highlighter
      container.read(currentToolProvider.notifier).selectTool(ToolType.highlighter);
      style = container.read(activeStrokeStyleProvider);
      expect(style.opacity, 0.4); // Updated from 0.5 to 0.4

      container.dispose();
    });

    test('updates when pen color changes', () {
      final container = ProviderContainer();

      // Initial color
      var style = container.read(activeStrokeStyleProvider);
      expect(style.color, 0xFF000000); // Black

      // Change color
      container
          .read(penSettingsProvider(ToolType.ballpointPen).notifier)
          .setColor(const Color(0xFFFF0000)); // Red
      style = container.read(activeStrokeStyleProvider);
      expect(style.color, 0xFFFF0000);

      container.dispose();
    });

    test('updates when pen thickness changes', () {
      final container = ProviderContainer();

      // Initial thickness
      var style = container.read(activeStrokeStyleProvider);
      expect(style.thickness, 1.5); // Updated from 2.0 to 1.5

      // Change thickness
      container
          .read(penSettingsProvider(ToolType.ballpointPen).notifier)
          .setThickness(5.0);
      style = container.read(activeStrokeStyleProvider);
      expect(style.thickness, 5.0);

      container.dispose();
    });
  });

  // ===========================================================================
  // isDrawingToolProvider Tests
  // ===========================================================================

  group('isDrawingToolProvider', () {
    test('returns true for ballpointPen', () {
      final container = ProviderContainer();
      expect(container.read(isDrawingToolProvider), true);
      container.dispose();
    });

    test('returns true for fountainPen', () {
      final container = ProviderContainer(
        overrides: [
          currentToolProvider.overrideWith((ref) => CurrentToolNotifier(null, initialTool: ToolType.gelPen)),
        ],
      );
      expect(container.read(isDrawingToolProvider), true);
      container.dispose();
    });

    test('returns true for pencil', () {
      final container = ProviderContainer(
        overrides: [
          currentToolProvider.overrideWith((ref) => CurrentToolNotifier(null, initialTool: ToolType.pencil)),
        ],
      );
      expect(container.read(isDrawingToolProvider), true);
      container.dispose();
    });

    test('returns true for brush', () {
      final container = ProviderContainer(
        overrides: [
          currentToolProvider.overrideWith((ref) => CurrentToolNotifier(null, initialTool: ToolType.brushPen)),
        ],
      );
      expect(container.read(isDrawingToolProvider), true);
      container.dispose();
    });

    test('returns true for highlighter', () {
      final container = ProviderContainer(
        overrides: [
          currentToolProvider.overrideWith((ref) => CurrentToolNotifier(null, initialTool: ToolType.highlighter)),
        ],
      );
      expect(container.read(isDrawingToolProvider), true);
      container.dispose();
    });

    test('returns true for pixelEraser', () {
      final container = ProviderContainer(
        overrides: [
          currentToolProvider.overrideWith((ref) => CurrentToolNotifier(null, initialTool: ToolType.pixelEraser)),
        ],
      );
      expect(container.read(isDrawingToolProvider), true);
      container.dispose();
    });

    test('returns true for strokeEraser', () {
      final container = ProviderContainer(
        overrides: [
          currentToolProvider.overrideWith((ref) => CurrentToolNotifier(null, initialTool: ToolType.strokeEraser)),
        ],
      );
      expect(container.read(isDrawingToolProvider), true);
      container.dispose();
    });

    test('returns true for lassoEraser', () {
      final container = ProviderContainer(
        overrides: [
          currentToolProvider.overrideWith((ref) => CurrentToolNotifier(null, initialTool: ToolType.lassoEraser)),
        ],
      );
      expect(container.read(isDrawingToolProvider), true);
      container.dispose();
    });

    test('returns false for shapes', () {
      final container = ProviderContainer(
        overrides: [
          currentToolProvider.overrideWith((ref) => CurrentToolNotifier(null, initialTool: ToolType.shapes)),
        ],
      );
      expect(container.read(isDrawingToolProvider), false);
      container.dispose();
    });

    test('returns false for text', () {
      final container = ProviderContainer(
        overrides: [
          currentToolProvider.overrideWith((ref) => CurrentToolNotifier(null, initialTool: ToolType.text)),
        ],
      );
      expect(container.read(isDrawingToolProvider), false);
      container.dispose();
    });

    test('returns false for selection', () {
      final container = ProviderContainer(
        overrides: [
          currentToolProvider.overrideWith((ref) => CurrentToolNotifier(null, initialTool: ToolType.selection)),
        ],
      );
      expect(container.read(isDrawingToolProvider), false);
      container.dispose();
    });

    test('returns false for panZoom', () {
      final container = ProviderContainer(
        overrides: [
          currentToolProvider.overrideWith((ref) => CurrentToolNotifier(null, initialTool: ToolType.panZoom)),
        ],
      );
      expect(container.read(isDrawingToolProvider), false);
      container.dispose();
    });
  });

  // ===========================================================================
  // isEraserToolProvider Tests
  // ===========================================================================

  group('isEraserToolProvider', () {
    test('returns false for pen tools', () {
      final container = ProviderContainer();
      expect(container.read(isEraserToolProvider), false);
      container.dispose();
    });

    test('returns true for pixelEraser', () {
      final container = ProviderContainer(
        overrides: [
          currentToolProvider.overrideWith((ref) => CurrentToolNotifier(null, initialTool: ToolType.pixelEraser)),
        ],
      );
      expect(container.read(isEraserToolProvider), true);
      container.dispose();
    });

    test('returns true for strokeEraser', () {
      final container = ProviderContainer(
        overrides: [
          currentToolProvider.overrideWith((ref) => CurrentToolNotifier(null, initialTool: ToolType.strokeEraser)),
        ],
      );
      expect(container.read(isEraserToolProvider), true);
      container.dispose();
    });

    test('returns true for lassoEraser', () {
      final container = ProviderContainer(
        overrides: [
          currentToolProvider.overrideWith((ref) => CurrentToolNotifier(null, initialTool: ToolType.lassoEraser)),
        ],
      );
      expect(container.read(isEraserToolProvider), true);
      container.dispose();
    });
  });

  // ===========================================================================
  // isPenToolProvider Tests
  // ===========================================================================

  group('isPenToolProvider', () {
    test('returns true for all pen types', () {
      for (final toolType in [
        ToolType.ballpointPen,
        ToolType.gelPen,
        ToolType.pencil,
        ToolType.brushPen,
        ToolType.highlighter,
      ]) {
        final container = ProviderContainer(
          overrides: [
            currentToolProvider.overrideWith((ref) => CurrentToolNotifier(null, initialTool: toolType)),
          ],
        );
        expect(container.read(isPenToolProvider), true,
            reason: '$toolType should be a pen tool');
        container.dispose();
      }
    });

    test('returns false for eraser tools', () {
      for (final toolType in [
        ToolType.pixelEraser,
        ToolType.strokeEraser,
        ToolType.lassoEraser,
      ]) {
        final container = ProviderContainer(
          overrides: [
            currentToolProvider.overrideWith((ref) => CurrentToolNotifier(null, initialTool: toolType)),
          ],
        );
        expect(container.read(isPenToolProvider), false,
            reason: '$toolType should not be a pen tool');
        container.dispose();
      }
    });
  });
}
