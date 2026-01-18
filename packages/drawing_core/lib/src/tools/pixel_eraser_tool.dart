import 'dart:math' as math;
import 'package:drawing_core/drawing_core.dart';

/// Pixel-based eraser that removes individual stroke segments.
/// Unlike stroke eraser, this only removes the touched portion.
class PixelEraserTool {
  PixelEraserTool({
    this.size = 20.0,
    this.pressureSensitive = true,
  });

  final double size;
  final bool pressureSensitive;
  
  /// Points collected during erase gesture
  final List<DrawingPoint> _erasePoints = [];
  
  /// Strokes affected during this gesture (for undo batching)
  final Map<String, List<int>> _affectedSegments = {};
  
  void onPointerDown(double x, double y, double pressure) {
    _erasePoints.clear();
    _affectedSegments.clear();
    _addErasePoint(x, y, pressure);
  }
  
  void onPointerMove(double x, double y, double pressure) {
    _addErasePoint(x, y, pressure);
  }
  
  /// Returns modified strokes and segments to remove
  EraseResult onPointerUp() {
    final result = EraseResult(
      affectedSegments: Map.from(_affectedSegments),
      erasePoints: List.from(_erasePoints),
    );
    _erasePoints.clear();
    _affectedSegments.clear();
    return result;
  }
  
  void _addErasePoint(double x, double y, double pressure) {
    final effectiveSize = pressureSensitive 
        ? size * (0.5 + pressure * 0.5)
        : size;
    
    // effectiveSize is calculated for future use (pressure-based erasing)
    // Currently tracked but not used in this version
    
    _erasePoints.add(DrawingPoint(
      x: x,
      y: y,
      pressure: pressure,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
  }
  
  /// Find stroke segments that intersect with eraser at given point
  List<SegmentHit> findSegmentsAt(
    List<Stroke> strokes,
    double x,
    double y,
    double eraserSize,
  ) {
    final hits = <SegmentHit>[];
    final tolerance = eraserSize / 2;
    
    for (final stroke in strokes) {
      // Bounding box pre-filter (ZORUNLU)
      if (!_boundsCheck(stroke.bounds, x, y, tolerance)) {
        continue;
      }
      
      // Check each segment
      for (int i = 0; i < stroke.points.length - 1; i++) {
        final p1 = stroke.points[i];
        final p2 = stroke.points[i + 1];
        
        final distance = _pointToSegmentDistance(x, y, p1.x, p1.y, p2.x, p2.y);
        final effectiveTolerance = tolerance + (stroke.style.thickness / 2);
        
        if (distance <= effectiveTolerance) {
          hits.add(SegmentHit(
            strokeId: stroke.id,
            segmentIndex: i,
            distance: distance,
          ));
        }
      }
    }
    
    return hits;
  }
  
  bool _boundsCheck(BoundingBox? bounds, double x, double y, double tolerance) {
    if (bounds == null) return false;
    return x >= bounds.left - tolerance &&
           x <= bounds.right + tolerance &&
           y >= bounds.top - tolerance &&
           y <= bounds.bottom + tolerance;
  }
  
  double _pointToSegmentDistance(
    double px, double py,
    double x1, double y1,
    double x2, double y2,
  ) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    
    if (dx == 0 && dy == 0) {
      return _distance(px, py, x1, y1);
    }
    
    final t = ((px - x1) * dx + (py - y1) * dy) / (dx * dx + dy * dy);
    final clampedT = t.clamp(0.0, 1.0);
    
    return _distance(px, py, x1 + clampedT * dx, y1 + clampedT * dy);
  }
  
  double _distance(double x1, double y1, double x2, double y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    return math.sqrt(dx * dx + dy * dy);
  }
}

/// Result of pixel erase operation
class EraseResult {
  const EraseResult({
    required this.affectedSegments,
    required this.erasePoints,
  });
  
  /// Map of strokeId -> list of segment indices to remove
  final Map<String, List<int>> affectedSegments;
  
  /// Points where eraser touched
  final List<DrawingPoint> erasePoints;
  
  bool get isEmpty => affectedSegments.isEmpty;
}

/// A hit on a specific stroke segment
class SegmentHit {
  const SegmentHit({
    required this.strokeId,
    required this.segmentIndex,
    required this.distance,
  });
  
  final String strokeId;
  final int segmentIndex;
  final double distance;
}
