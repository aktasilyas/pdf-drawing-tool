import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the canvas is in infinite/whiteboard mode.
/// Set by [DrawingScreen] based on the provided [CanvasMode].
final isInfiniteCanvasProvider = StateProvider<bool>((ref) => true);

/// GlobalKey for the RepaintBoundary wrapping the canvas.
/// Used to capture screenshots for PNG/PDF export.
final canvasBoundaryKeyProvider = Provider<GlobalKey>((ref) => GlobalKey());
