import 'dart:async';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/painters/cover/cover_details.dart';
import 'package:drawing_ui/src/painters/cover/cover_geometry.dart';
import 'package:drawing_ui/src/painters/cover/cover_layers.dart';
import 'package:drawing_ui/src/painters/cover/cover_texture_store.dart';

/// Paints the "material" cover family as a notebook object: spine with hinge
/// crease, page edges, rounded fore-edge corners, depth shading and a
/// photographic material grain tinted with the cover colour.
///
/// Each (cover, size) is recorded once into a `ui.Picture` and cached, so
/// [paint] only replays it. Until the material tiles are loaded (see
/// [CoverTextureStore]) the cover renders flat-shaded and re-records itself
/// when the tiles arrive.
class CoverRenderer {
  CoverRenderer._();

  static const int _maxSizesPerCover = 4;
  static final Map<String, List<_Entry>> _cache = {};

  /// Title zone for a cover of [size]; the kraft label plate sits here.
  static ui.Rect labelPlateRect(ui.Size size) =>
      CoverGeometry.of(size).titleRect;

  /// Zone for the typed title of [cover]: the label plate for kraft, the
  /// upper third of the face for everything else.
  static ui.Rect titleZone(ui.Size size, Cover cover) {
    final g = CoverGeometry.of(size);
    return CoverDetails.hasLabelPlate(cover) ? g.plateRect : g.titleRect;
  }

  /// Draws [cover] into [size] on [canvas]. The title is drawn by the widget.
  static void paint(ui.Canvas canvas, ui.Size size, Cover cover) {
    if (!CoverTextureStore.isLoaded) {
      unawaited(CoverTextureStore.ensureLoaded());
    }
    canvas.drawPicture(_pictureFor(cover, size));
  }

  /// Whether a repaint is needed between two covers.
  static bool needsRepaint(Cover a, Cover b) => a.id != b.id;

  static ui.Picture _pictureFor(Cover cover, ui.Size size) {
    final loaded = CoverTextureStore.isLoaded;
    final list = _cache.putIfAbsent(cover.id, () => <_Entry>[]);
    for (final e in list) {
      if (e.loaded == loaded && e.size == size) return e.picture;
    }
    // A flat-shaded picture is obsolete once the textures are in.
    list.removeWhere((e) {
      final stale = e.loaded != loaded;
      if (stale) e.picture.dispose();
      return stale;
    });
    if (list.length >= _maxSizesPerCover) list.removeAt(0).picture.dispose();
    final entry = _Entry(size, loaded, _record(cover, size));
    list.add(entry);
    return entry.picture;
  }

  static ui.Picture _record(Cover cover, ui.Size size) {
    final recorder = ui.PictureRecorder();
    final c = ui.Canvas(recorder, ui.Offset.zero & size);
    final g = CoverGeometry.of(size);
    CoverLayers.shadow(c, g);
    CoverLayers.pages(c, g);
    CoverDetails.behindBoard(c, g, cover);
    c.save();
    c.clipRRect(g.coverRRect);
    CoverLayers.body(c, g, cover);
    CoverDetails.onBoard(c, g, cover);
    c.restore();
    CoverLayers.bevel(c, g,
        strength: cover.material == CoverMaterial.linen ? 1.4 : 1.0);
    return recorder.endRecording();
  }
}

class _Entry {
  _Entry(this.size, this.loaded, this.picture);
  final ui.Size size;
  final bool loaded;
  final ui.Picture picture;
}
