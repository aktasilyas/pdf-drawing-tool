import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/canvas_color_scheme.dart';
import 'package:drawing_ui/src/canvas/page_background_painter.dart';
import 'package:drawing_ui/src/painters/cover/cover_texture_store.dart';

/// Combines cover image (if applicable) with pattern painter.
/// Use this instead of bare CustomPaint+PageBackgroundPatternPainter.
class PageBackgroundView extends StatelessWidget {
  final PageBackground background;
  final CanvasColorScheme? colorScheme;
  final Size pageSize;

  const PageBackgroundView({
    super.key,
    required this.background,
    required this.pageSize,
    this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = _coverImagePath;
    final isMaterialCover = _isMaterialCover;
    if (isMaterialCover) CoverTextureStore.ensureLoaded();
    Widget buildPainter(int revision) => CustomPaint(
          painter: PageBackgroundPatternPainter(
            background: background,
            colorScheme: colorScheme,
            textureRevision: revision,
          ),
          size: pageSize,
          isComplex: true,
          willChange: false,
        );
    final painter = isMaterialCover
        ? ValueListenableBuilder<int>(
            valueListenable: CoverTextureStore.revision,
            builder: (_, revision, __) => buildPainter(revision),
          )
        : buildPainter(0);

    if (imagePath == null) return painter;

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        painter,
      ],
    );
  }

  bool get _isMaterialCover {
    if (background.type != BackgroundType.cover || background.coverId == null) {
      return false;
    }
    return CoverRegistry.byId(background.coverId!)?.style ==
        CoverStyle.material;
  }

  String? get _coverImagePath {
    if (background.type != BackgroundType.cover || background.coverId == null) {
      return null;
    }
    final cover = CoverRegistry.byId(background.coverId!);
    if (cover?.style != CoverStyle.image) return null;
    return cover?.imagePath;
  }
}
