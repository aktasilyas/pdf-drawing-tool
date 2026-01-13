/// Core drawing logic, models, and abstractions for the StarNote drawing library.
///
/// This package provides platform-agnostic business logic for:
/// - Stroke and document models
/// - Drawing tool abstractions
/// - History management (undo/redo)
/// - Serialization interfaces
///
/// This package has minimal Flutter dependencies and can be used
/// in non-Flutter Dart environments with some limitations.
///
/// ## Usage
///
/// ```dart
/// import 'package:drawing_core/drawing_core.dart';
///
/// // Create a stroke
/// final stroke = Stroke(
///   id: 'stroke-1',
///   points: [...],
///   style: StrokeStyle.ballpoint(color: Colors.black, thickness: 2.0),
/// );
///
/// // Create a document
/// final document = DrawingDocument(
///   layers: [Layer(strokes: [stroke])],
/// );
/// ```
library drawing_core;

// Models
export 'src/models/drawing_point.dart';
export 'src/models/stroke.dart';
export 'src/models/stroke_style.dart';
export 'src/models/layer.dart';
export 'src/models/drawing_document.dart';
export 'src/models/nib_shape.dart';

// Tools
export 'src/tools/drawing_tool.dart';
export 'src/tools/tool_type.dart';
export 'src/tools/tool_settings.dart';

// History
export 'src/history/drawing_command.dart';
export 'src/history/history_manager.dart';

// Serialization
export 'src/serialization/serialization_codec.dart';
export 'src/serialization/document_serializer.dart';

// Utils
export 'src/utils/path_smoother.dart';
export 'src/utils/geometry_utils.dart';
