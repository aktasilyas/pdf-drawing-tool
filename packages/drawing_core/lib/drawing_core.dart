/// A UI-agnostic drawing engine core for Flutter.
///
/// This library provides the core data structures and algorithms for
/// building drawing applications. It is designed to be completely
/// independent of Flutter's UI framework, using only pure Dart.
///
/// ## Features
///
/// - **Models**: Immutable data structures for points, strokes, layers, and documents
/// - **Tools**: Drawing tools (pen, highlighter, brush) with customizable styles
/// - **History**: Command pattern implementation for undo/redo support
/// - **Input Processing**: Path smoothing and simplification utilities
///
/// ## Usage
///
/// ```dart
/// import 'package:drawing_core/drawing_core.dart';
///
/// // Create a document
/// final document = DrawingDocument.empty('My Drawing');
///
/// // Create a pen tool
/// final pen = PenTool();
///
/// // Draw a stroke
/// pen.onPointerDown(DrawingPoint(x: 0, y: 0));
/// pen.onPointerMove(DrawingPoint(x: 10, y: 10));
/// final stroke = pen.onPointerUp();
///
/// // Add to document with history
/// final history = HistoryManager();
/// final command = AddStrokeCommand(layerIndex: 0, stroke: stroke!);
/// final newDocument = history.execute(command, document);
/// ```
library drawing_core;

// Models
export 'src/models/bounding_box.dart';
export 'src/models/document.dart';
export 'src/models/drawing_point.dart';
export 'src/models/layer.dart';
export 'src/models/stroke.dart';
export 'src/models/stroke_style.dart';

// Tools
export 'src/tools/brush_tool.dart';
export 'src/tools/drawing_tool.dart';
export 'src/tools/highlighter_tool.dart';
export 'src/tools/pen_tool.dart';

// History
export 'src/history/add_stroke_command.dart';
export 'src/history/drawing_command.dart';
export 'src/history/history_manager.dart';
export 'src/history/remove_stroke_command.dart';

// Input Processing
export 'src/input/path_smoother.dart';

// Hit Testing
export 'src/hit_testing/hit_testing.dart';
