import 'package:drawing_ui/src/utils/drawing_log.dart';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Loads and caches the photographic (CC0) cover material tiles.
///
/// Tiles are desaturated 512 px WebP files shipped in `assets/covers/textures/`
/// (sources in `docs/design/ASSETS.md`). Loading is async, painting is sync:
/// painters call [ensureLoaded] (fire-and-forget) and draw a flat shaded cover
/// until [revision] ticks, which repaint-aware widgets listen to.
class CoverTextureStore {
  CoverTextureStore._();

  static final Map<CoverMaterial, ui.Image> _images = {};
  static Future<void>? _loading;

  /// Increments every time the set of loaded textures changes.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// Whether every material tile is available.
  static bool get isLoaded => _images.length == CoverMaterial.values.length;

  /// The tile for [material], or null while it is not loaded.
  static ui.Image? imageFor(CoverMaterial material) => _images[material];

  static String _name(CoverMaterial m) => switch (m) {
        CoverMaterial.linen => 'linen',
        CoverMaterial.leather => 'leather',
        CoverMaterial.kraft => 'kraft',
        CoverMaterial.felt => 'felt',
      };

  /// Starts (once) loading all tiles. Safe to call from `paint`.
  static Future<void> ensureLoaded() => _loading ??= _loadAll();

  static Future<void> _loadAll() async {
    for (final material in CoverMaterial.values) {
      final data = await _loadBytes(_name(material));
      if (data == null) continue;
      try {
        final codec = await ui.instantiateImageCodec(data);
        final frame = await codec.getNextFrame();
        _images[material] = frame.image;
        revision.value++;
      } catch (e) {
        DrawingLog.e('CoverTextureStore: decode failed for $material: $e');
      }
    }
  }

  static Future<Uint8List?> _loadBytes(String name) async {
    // Package-qualified key when used from an app, bare key inside the
    // package's own tests.
    for (final prefix in const ['packages/drawing_ui/', '']) {
      try {
        final d =
            await rootBundle.load('${prefix}assets/covers/textures/$name.webp');
        return d.buffer.asUint8List(d.offsetInBytes, d.lengthInBytes);
      } catch (_) {
        continue;
      }
    }
    DrawingLog.w('CoverTextureStore: texture $name not found');
    return null;
  }

  /// Test hook: forget everything so a test can reload.
  @visibleForTesting
  static void debugReset() {
    _images.clear();
    _loading = null;
  }
}
