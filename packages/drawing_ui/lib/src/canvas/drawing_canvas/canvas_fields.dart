part of 'package:drawing_ui/src/canvas/drawing_canvas.dart';

/// Mutable per-State fields of [DrawingCanvasState].
mixin _CanvasFields on DrawingCanvasGestureHandlers<DrawingCanvas> {
  /// Controller for managing active stroke state.
  /// Uses ChangeNotifier instead of setState for performance.
  late final DrawingController _drawingController;

  /// Controller for managing temporary laser pointer strokes.
  late final LaserController _laserController;

  /// Whether a laser drawing operation is in progress.
  bool _isLaserDrawing = false;

  /// Cached renderer instance - shared across all painters.
  final FlutterStrokeRenderer _renderer = FlutterStrokeRenderer();

  // ─────────────────────────────────────────────────────────────────────────
  // GESTURE HANDLING - Performance optimizations
  // ─────────────────────────────────────────────────────────────────────────

  /// Last recorded point position for distance filtering.
  Offset? _lastPoint;

  // ─────────────────────────────────────────────────────────────────────────
  // ZOOM/PAN GESTURE TRACKING
  // ─────────────────────────────────────────────────────────────────────────

  /// Number of active pointers (fingers) on the canvas.
  /// Used to distinguish between drawing (1 finger) and zoom/pan (2 fingers).
  int _pointerCount = 0;

  /// Last focal point for scale gesture (zoom/pan center point).
  Offset? _lastFocalPoint;

  /// Last scale value for calculating zoom delta.
  double? _lastScale;

  // ─────────────────────────────────────────────────────────────────────────
  // SELECTION TRACKING
  // ─────────────────────────────────────────────────────────────────────────

  /// Whether a selection operation is in progress.
  bool _isSelecting = false;

  // ─────────────────────────────────────────────────────────────────────────
  // SHAPE TRACKING
  // ─────────────────────────────────────────────────────────────────────────

  /// Whether a shape drawing operation is in progress.
  bool _isDrawingShape = false;

  /// Active shape tool instance.
  core.ShapeTool? _activeShapeTool;

  // ─────────────────────────────────────────────────────────────────────────
  // STRAIGHT LINE MODE TRACKING (for highlighters)
  // ─────────────────────────────────────────────────────────────────────────

  /// Whether straight line drawing is in progress.
  bool _isStraightLineDrawing = false;

  /// Start point for straight line.
  core.DrawingPoint? _straightLineStart;

  /// Current end point for straight line (for preview).
  core.DrawingPoint? _straightLineEnd;

  /// Style for straight line.
  core.StrokeStyle? _straightLineStyle;

  // ─────────────────────────────────────────────────────────────────────────
  // ERASER SHAPE TRACKING
  // ─────────────────────────────────────────────────────────────────────────

  /// Shape IDs erased in current gesture session.
  final Set<String> _erasedShapeIds = {};

  // ─────────────────────────────────────────────────────────────────────────
  // PIXEL ERASER TRACKING
  // ─────────────────────────────────────────────────────────────────────────

  /// Accumulated segment hits for pixel eraser during a gesture.
  final Map<String, List<int>> _pixelEraseHits = {};

  /// Original strokes affected by pixel eraser (for undo).
  final List<core.Stroke> _pixelEraseOriginalStrokes = [];

  /// Path swept by the pixel eraser during a gesture (canvas units).
  final core.EraserSweep _pixelEraseSweep = core.EraserSweep();

  /// Note ID -> set of internal stroke IDs erased in current gesture.
  final Map<String, Set<String>> _erasedNoteStrokeIds = {};

  /// Note ID -> set of internal shape IDs erased in current gesture.
  final Map<String, Set<String>> _erasedNoteShapeIds = {};

  /// Note ID -> (stroke ID -> segment indices) for pixel erasure inside notes.
  final Map<String, Map<String, List<int>>> _pixelEraseNoteHits = {};

  /// Note ID -> original strokes for pixel erasure inside notes.
  final Map<String, List<core.Stroke>> _pixelEraseNoteOriginalStrokes = {};

  // ─────────────────────────────────────────────────────────────────────────
  // INITIALIZATION TRACKING
  // ─────────────────────────────────────────────────────────────────────────

  /// Image cache manager for decoded ui.Image objects.
  final ImageCacheManager _imageCacheManager = ImageCacheManager();

  /// Whether canvas has been initialized for limited mode.
  bool _hasInitialized = false;

  /// Last viewport size for detecting orientation changes.
  Size? _lastViewportSize;

  /// Last page size for detecting paper format/orientation changes.
  Size? _lastPageSize;

  /// Sticky note that constrains the current stroke (if drawing inside one).
  core.StickyNote? _drawingInsideNote;

  /// Focal point at the start of a scale gesture (for swipe detection).
  Offset? _scaleStartFocalPoint;

  /// Whether the current scale gesture has been classified as zoom (not swipe).
  bool _scaleGestureIsZoom = false;
}
