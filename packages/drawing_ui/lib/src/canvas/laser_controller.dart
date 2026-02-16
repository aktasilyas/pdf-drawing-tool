import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'package:drawing_ui/src/canvas/laser_stroke.dart';
import 'package:drawing_ui/src/providers/drawing_providers.dart';

/// Controller for managing temporary laser pointer strokes.
///
/// Uses [ChangeNotifier] pattern (same as [DrawingController])
/// for high-performance repaint without setState.
class LaserController extends ChangeNotifier {
  LaserStroke? _activeStroke;
  final List<LaserStroke> _fadingStrokes = [];
  int _nextId = 0;

  /// The stroke currently being drawn (null when idle).
  LaserStroke? get activeStroke => _activeStroke;

  /// Strokes that are fading out after completion.
  List<LaserStroke> get fadingStrokes => _fadingStrokes;

  /// Whether there are any visible strokes (active or fading).
  bool get hasStrokes =>
      _activeStroke != null || _fadingStrokes.isNotEmpty;

  /// Whether the ticker should be running.
  bool get needsAnimation => hasStrokes;

  /// Starts a new laser stroke at [point].
  void startStroke(
    Offset point, {
    required Color color,
    required double thickness,
    required LaserMode mode,
  }) {
    _activeStroke = LaserStroke(
      id: _nextId++,
      points: [point],
      color: color,
      thickness: thickness,
      mode: mode,
      completedAt: DateTime.now(), // placeholder, updated on end
      fadeDuration: Duration.zero, // placeholder
    );
    notifyListeners();
  }

  /// Adds a point to the active stroke.
  ///
  /// In dot mode, replaces the single point instead of appending.
  void addPoint(Offset point) {
    final stroke = _activeStroke;
    if (stroke == null) return;

    if (stroke.mode == LaserMode.dot) {
      _activeStroke = stroke.copyWith(points: [point]);
    } else {
      stroke.points.add(point);
    }
    notifyListeners();
  }

  /// Completes the active stroke and moves it to the fading list.
  void endStroke(Duration fadeDuration) {
    final stroke = _activeStroke;
    if (stroke == null) return;

    _fadingStrokes.add(LaserStroke(
      id: stroke.id,
      points: List.unmodifiable(stroke.points),
      color: stroke.color,
      thickness: stroke.thickness,
      mode: stroke.mode,
      completedAt: DateTime.now(),
      fadeDuration: fadeDuration,
    ));
    _activeStroke = null;
    notifyListeners();
  }

  /// Cancels the active stroke without adding it to fading list.
  void cancelStroke() {
    if (_activeStroke == null) return;
    _activeStroke = null;
    notifyListeners();
  }

  /// Called every frame to remove expired (fully faded) strokes.
  ///
  /// Returns true if any strokes were removed.
  bool tick() {
    final now = DateTime.now();
    final before = _fadingStrokes.length;
    _fadingStrokes.removeWhere((s) => s.isExpired(now));
    if (_fadingStrokes.length != before) {
      notifyListeners();
      return true;
    }
    // Still notify for fade progress updates on fading strokes
    if (_fadingStrokes.isNotEmpty) {
      notifyListeners();
    }
    return false;
  }

  /// Clears all strokes (active and fading).
  void reset() {
    _activeStroke = null;
    _fadingStrokes.clear();
    notifyListeners();
  }
}
