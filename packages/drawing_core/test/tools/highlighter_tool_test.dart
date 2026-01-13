import 'package:test/test.dart';
import 'package:drawing_core/src/models/drawing_point.dart';
import 'package:drawing_core/src/models/stroke_style.dart';
import 'package:drawing_core/src/tools/highlighter_tool.dart';

void main() {
  group('HighlighterTool', () {
    group('Constructor', () {
      test('creates with default highlighter style', () {
        final tool = HighlighterTool();

        expect(tool.style.color, 0xFFFFEB3B); // yellow
        expect(tool.style.thickness, 20.0);
        expect(tool.style.opacity, 0.5);
        expect(tool.style.nibShape, NibShape.rectangle);
        expect(tool.isDrawing, false);
      });

      test('creates with custom style', () {
        final customStyle = StrokeStyle.highlighter(
          color: 0xFF00FF00, // green
          thickness: 15.0,
        );
        final tool = HighlighterTool(style: customStyle);

        expect(tool.style.color, 0xFF00FF00);
        expect(tool.style.thickness, 15.0);
        expect(tool.style.opacity, 0.5); // highlighter default
        expect(tool.style.nibShape, NibShape.rectangle);
      });

      test('opacity is 0.5 for default highlighter', () {
        final tool = HighlighterTool();
        expect(tool.style.opacity, 0.5);
      });

      test('nibShape is rectangle for default highlighter', () {
        final tool = HighlighterTool();
        expect(tool.style.nibShape, NibShape.rectangle);
      });
    });

    group('Drawing flow', () {
      test('complete drawing cycle produces correct stroke', () {
        final tool = HighlighterTool();

        tool.onPointerDown(DrawingPoint(x: 0, y: 0));
        tool.onPointerMove(DrawingPoint(x: 50, y: 5));
        tool.onPointerMove(DrawingPoint(x: 100, y: 0));
        tool.onPointerMove(DrawingPoint(x: 150, y: 5));
        tool.onPointerMove(DrawingPoint(x: 200, y: 0));

        final stroke = tool.onPointerUp();

        expect(stroke, isNotNull);
        expect(stroke!.pointCount, 5);
        expect(stroke.style.color, 0xFFFFEB3B);
        expect(stroke.style.opacity, 0.5);
        expect(stroke.style.nibShape, NibShape.rectangle);
      });

      test('stroke preserves highlighter style properties', () {
        final tool = HighlighterTool(
          style: StrokeStyle.highlighter(color: 0xFFFF00FF),
        );

        tool.onPointerDown(DrawingPoint(x: 10, y: 10));
        final stroke = tool.onPointerUp();

        expect(stroke!.style.opacity, 0.5);
        expect(stroke.style.nibShape, NibShape.rectangle);
        expect(stroke.style.color, 0xFFFF00FF);
      });

      test('multiple strokes work correctly', () {
        final tool = HighlighterTool();

        // First stroke
        tool.onPointerDown(DrawingPoint(x: 0, y: 0));
        tool.onPointerMove(DrawingPoint(x: 100, y: 0));
        final stroke1 = tool.onPointerUp();

        // Second stroke
        tool.onPointerDown(DrawingPoint(x: 0, y: 50));
        tool.onPointerMove(DrawingPoint(x: 100, y: 50));
        final stroke2 = tool.onPointerUp();

        expect(stroke1, isNotNull);
        expect(stroke2, isNotNull);
        expect(stroke1!.points[0].y, 0);
        expect(stroke2!.points[0].y, 50);
      });
    });

    group('Style updates', () {
      test('updateStyle changes future strokes', () {
        final tool = HighlighterTool();

        tool.updateStyle(StrokeStyle.highlighter(color: 0xFF0000FF));

        tool.onPointerDown(DrawingPoint(x: 0, y: 0));
        final stroke = tool.onPointerUp();

        expect(stroke!.style.color, 0xFF0000FF);
      });
    });

    group('Cancel', () {
      test('cancel clears drawing state', () {
        final tool = HighlighterTool();

        tool.onPointerDown(DrawingPoint(x: 0, y: 0));
        tool.onPointerMove(DrawingPoint(x: 50, y: 0));
        
        expect(tool.isDrawing, true);
        expect(tool.currentPointCount, 2);

        tool.cancel();

        expect(tool.isDrawing, false);
        expect(tool.currentPointCount, 0);
      });
    });
  });
}
