import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter/services.dart' show rootBundle;

import 'package:drawing_ui/src/canvas/page_background_painter.dart';
import 'package:drawing_ui/src/painters/cover/cover_texture_store.dart';

/// Paints a page background off-screen exactly as the canvas shows it.
///
/// Mirrors `PageBackgroundView`: base color, then the image cover asset (if
/// any), then [PageBackgroundPatternPainter] (grid / lines / dots, every
/// `TemplatePattern` through `TemplatePatternPainter`, material and other
/// covers). Shared by thumbnails and PDF/PNG export so there is one
/// background renderer.
abstract final class PageBackgroundRaster {
  /// Loads everything [paint] needs for [background] that is asynchronous:
  /// material cover textures and the image cover asset.
  ///
  /// Returns the decoded image cover (the caller disposes it), or null for
  /// every other background or when the asset cannot be loaded (the base
  /// color stays visible).
  static Future<ui.Image?> prepare(PageBackground background) async {
    if (background.type != BackgroundType.cover) return null;
    final id = background.coverId;
    final cover = id == null ? null : CoverRegistry.byId(id);
    if (cover == null) return null;
    if (cover.style == CoverStyle.material) {
      await CoverTextureStore.ensureLoaded();
      return null;
    }
    final path = cover.imagePath;
    if (cover.style != CoverStyle.image || path == null) return null;
    try {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      return (await codec.getNextFrame()).image;
    } catch (_) {
      return null;
    }
  }

  /// Paints [background] into `Offset.zero & size` in page coordinates.
  ///
  /// [coverImage] is the result of [prepare].
  static void paint(
    Canvas canvas,
    PageBackground background,
    Size size,
    ui.Image? coverImage,
  ) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Color(background.color),
    );
    if (coverImage != null) {
      canvas.drawImageRect(
        coverImage,
        Rect.fromLTWH(
            0, 0, coverImage.width.toDouble(), coverImage.height.toDouble()),
        Offset.zero & size,
        Paint()..filterQuality = FilterQuality.medium,
      );
    }
    PageBackgroundPatternPainter(background: background).paint(canvas, size);
  }
}
