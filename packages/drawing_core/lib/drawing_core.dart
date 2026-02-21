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
/// final document = DrawingDocument.emptyMultiPage('My Drawing');
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
export 'src/models/audio_recording.dart';
export 'src/models/bounding_box.dart';
export 'src/models/canvas_mode.dart';
export 'src/models/cover.dart';
export 'src/models/document.dart';
export 'src/models/document_settings.dart';
export 'src/models/document_type.dart';
export 'src/models/drawing_point.dart';
export 'src/models/layer.dart';
export 'src/models/page.dart';
export 'src/models/page_background.dart';
export 'src/models/page_size.dart';
export 'src/models/paper_size.dart';
export 'src/models/pen_type.dart';
export 'src/models/selection.dart';
export 'src/models/shape.dart';
export 'src/models/shape_type.dart';
export 'src/models/stroke.dart';
export 'src/models/stroke_style.dart';
export 'src/models/template.dart';
export 'src/models/template_category.dart';
export 'src/models/template_pattern.dart';
export 'src/models/text_element.dart';
export 'src/models/image_element.dart';
export 'src/models/sticky_note.dart';

// Tools
export 'src/tools/arrow_tool.dart';
export 'src/tools/brush_tool.dart';
export 'src/tools/drawing_tool.dart';
export 'src/tools/ellipse_tool.dart';
export 'src/tools/eraser_tool.dart';
export 'src/tools/generic_shape_tool.dart';
export 'src/tools/highlighter_tool.dart';
export 'src/tools/lasso_eraser_tool.dart';
export 'src/tools/lasso_selection_tool.dart';
export 'src/tools/line_tool.dart';
export 'src/tools/pen_tool.dart';
export 'src/tools/pixel_eraser_tool.dart';
export 'src/tools/rect_selection_tool.dart';
export 'src/tools/rectangle_tool.dart';
export 'src/tools/selection_tool.dart';
export 'src/tools/shape_tool.dart';
export 'src/tools/text_tool.dart';

// History
export 'src/history/add_shape_command.dart';
export 'src/history/add_stroke_command.dart';
export 'src/history/clear_layer_command.dart';
export 'src/history/delete_selection_command.dart';
export 'src/history/drawing_command.dart';
export 'src/history/erase_points_command.dart';
export 'src/history/erase_strokes_command.dart';
export 'src/history/history_manager.dart';
export 'src/history/move_selection_command.dart';
export 'src/history/remove_shape_command.dart';
export 'src/history/remove_stroke_command.dart';
export 'src/history/add_text_command.dart';
export 'src/history/remove_text_command.dart';
export 'src/history/update_text_command.dart';
export 'src/history/add_image_command.dart';
export 'src/history/remove_image_command.dart';
export 'src/history/update_image_command.dart';
export 'src/history/rotate_selection_command.dart';
export 'src/history/duplicate_selection_command.dart';
export 'src/history/change_selection_style_command.dart';
export 'src/history/add_sticky_note_command.dart';
export 'src/history/remove_sticky_note_command.dart';
export 'src/history/update_sticky_note_command.dart';

// Input Processing
export 'src/input/path_smoother.dart';

// Hit Testing
export 'src/hit_testing/hit_testing.dart';

// Managers
export 'src/managers/page_manager.dart';

// Services
export 'src/services/cover_registry.dart';
export 'src/services/template_registry.dart';
