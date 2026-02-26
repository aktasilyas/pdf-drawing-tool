import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Captures the drawing canvas as a base64-encoded PNG image.
///
/// Uses RepaintBoundary to capture the canvas content.
/// The captured image is optimized for AI APIs:
/// - White background (not transparent)
/// - Max 1568px dimension (safe for all AI providers)
/// - PNG format for sharp stroke edges
class CanvasCaptureService {
  /// Capture the canvas and return a base64-encoded PNG string.
  ///
  /// [boundaryKey] is the GlobalKey of the RepaintBoundary wrapping the canvas.
  /// [pixelRatio] controls output resolution (2.0 → ~1024px on most devices).
  Future<String?> captureAsBase64(
    GlobalKey boundaryKey, {
    double pixelRatio = 2.0,
  }) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // Capture at specified pixel ratio
      final image = await boundary.toImage(pixelRatio: pixelRatio);

      // Add white background (AI models work better with opaque backgrounds)
      final whiteBackground = await _addWhiteBackground(image);

      // Resize if too large (max 1568px — Claude's optimal limit)
      final resized = await _resizeIfNeeded(
        whiteBackground,
        maxDimension: 1568,
      );

      // Encode to PNG bytes
      final byteData = await resized.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) return null;

      final bytes = byteData.buffer.asUint8List();
      return base64Encode(bytes);
    } catch (e) {
      debugPrint('CanvasCaptureService error: $e');
      return null;
    }
  }

  /// Adds a white background behind the captured image.
  /// AI models perform significantly better with dark strokes on white.
  Future<ui.Image> _addWhiteBackground(ui.Image original) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final size = Size(
      original.width.toDouble(),
      original.height.toDouble(),
    );

    // White background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFFFFFFF),
    );

    // Original image on top
    canvas.drawImage(original, Offset.zero, Paint());

    final picture = recorder.endRecording();
    return picture.toImage(original.width, original.height);
  }

  /// Resize image if any dimension exceeds [maxDimension].
  Future<ui.Image> _resizeIfNeeded(
    ui.Image image, {
    required int maxDimension,
  }) async {
    final maxSide = image.width > image.height ? image.width : image.height;
    if (maxSide <= maxDimension) return image;

    final scale = maxDimension / maxSide;
    final newWidth = (image.width * scale).round();
    final newHeight = (image.height * scale).round();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble()),
      Paint()..filterQuality = FilterQuality.high,
    );

    final picture = recorder.endRecording();
    return picture.toImage(newWidth, newHeight);
  }
}
