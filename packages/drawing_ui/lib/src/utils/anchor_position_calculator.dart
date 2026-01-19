import 'package:flutter/material.dart';

/// Direction where the arrow should point
enum ArrowDirection {
  up,
  down,
  left,
  right,
}

/// Result of anchor position calculation
class AnchorPositionResult {
  const AnchorPositionResult({
    required this.offset,
    required this.alignment,
    required this.arrowDirection,
    required this.arrowOffset,
  });

  /// Offset for positioning the panel
  final Offset offset;

  /// Alignment of the panel relative to anchor
  final Alignment alignment;

  /// Direction where arrow should point to anchor
  final ArrowDirection arrowDirection;

  /// Horizontal/vertical offset of arrow from panel edge
  final double arrowOffset;
}

/// Calculates optimal position for anchored panels
class AnchorPositionCalculator {
  const AnchorPositionCalculator({
    required this.anchorKey,
    required this.panelSize,
    required this.screenSize,
    this.preferredDirection = ArrowDirection.down,
    this.padding = 8.0,
    this.arrowSize = 12.0,
  });

  final GlobalKey anchorKey;
  final Size panelSize;
  final Size screenSize;
  final ArrowDirection preferredDirection;
  final double padding;
  final double arrowSize;

  /// Calculate best position for the panel
  AnchorPositionResult? calculate() {
    final RenderBox? renderBox =
        anchorKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) {
      debugPrint('⚠️ Anchor renderBox is null');
      return null;
    }

    // Get anchor button position in global coordinates
    final anchorPosition = renderBox.localToGlobal(Offset.zero);
    final anchorSize = renderBox.size;

    // Try preferred direction first
    final preferred = _tryDirection(
      preferredDirection,
      anchorPosition,
      anchorSize,
    );
    if (preferred != null) return preferred;

    // Try other directions
    for (final direction in ArrowDirection.values) {
      if (direction == preferredDirection) continue;
      final result = _tryDirection(direction, anchorPosition, anchorSize);
      if (result != null) return result;
    }

    // Fallback: force preferred direction even if it goes offscreen
    return _calculatePosition(preferredDirection, anchorPosition, anchorSize);
  }

  AnchorPositionResult? _tryDirection(
    ArrowDirection direction,
    Offset anchorPosition,
    Size anchorSize,
  ) {
    final result = _calculatePosition(direction, anchorPosition, anchorSize);
    
    // Check if panel fits on screen
    if (_fitsOnScreen(result.offset)) {
      return result;
    }
    
    return null;
  }

  AnchorPositionResult _calculatePosition(
    ArrowDirection direction,
    Offset anchorPosition,
    Size anchorSize,
  ) {
    late Offset offset;
    late Alignment alignment;
    late double arrowOffset;

    final anchorCenterX = anchorPosition.dx + anchorSize.width / 2;
    final anchorCenterY = anchorPosition.dy + anchorSize.height / 2;

    switch (direction) {
      case ArrowDirection.down:
        // Panel below anchor
        offset = Offset(
          anchorCenterX - panelSize.width / 2,
          anchorPosition.dy + anchorSize.height + padding + arrowSize,
        );
        alignment = Alignment.topCenter;
        arrowOffset = panelSize.width / 2;
        break;

      case ArrowDirection.up:
        // Panel above anchor
        offset = Offset(
          anchorCenterX - panelSize.width / 2,
          anchorPosition.dy - panelSize.height - padding - arrowSize,
        );
        alignment = Alignment.bottomCenter;
        arrowOffset = panelSize.width / 2;
        break;

      case ArrowDirection.right:
        // Panel to the right of anchor
        offset = Offset(
          anchorPosition.dx + anchorSize.width + padding + arrowSize,
          anchorCenterY - panelSize.height / 2,
        );
        alignment = Alignment.centerLeft;
        arrowOffset = panelSize.height / 2;
        break;

      case ArrowDirection.left:
        // Panel to the left of anchor
        offset = Offset(
          anchorPosition.dx - panelSize.width - padding - arrowSize,
          anchorCenterY - panelSize.height / 2,
        );
        alignment = Alignment.centerRight;
        arrowOffset = panelSize.height / 2;
        break;
    }

    // Constrain to screen bounds
    offset = _constrainToScreen(offset, direction);

    return AnchorPositionResult(
      offset: offset,
      alignment: alignment,
      arrowDirection: direction,
      arrowOffset: arrowOffset,
    );
  }

  bool _fitsOnScreen(Offset offset) {
    return offset.dx >= 0 &&
        offset.dy >= 0 &&
        offset.dx + panelSize.width <= screenSize.width &&
        offset.dy + panelSize.height <= screenSize.height;
  }

  Offset _constrainToScreen(Offset offset, ArrowDirection direction) {
    double x = offset.dx;
    double y = offset.dy;

    // Horizontal constraint
    if (x < padding) {
      x = padding;
    } else if (x + panelSize.width > screenSize.width - padding) {
      x = screenSize.width - panelSize.width - padding;
    }

    // Vertical constraint
    if (y < padding) {
      y = padding;
    } else if (y + panelSize.height > screenSize.height - padding) {
      y = screenSize.height - panelSize.height - padding;
    }

    return Offset(x, y);
  }
}
