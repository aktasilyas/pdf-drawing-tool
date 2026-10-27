import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/src/canvas/page_background_view.dart';
import 'package:drawing_ui/src/canvas/canvas_color_scheme.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// Preview shown when swiping past the last page.
/// Shows the page at its correct aspect ratio with surrounding area.
class AddPagePreview extends StatelessWidget {
  const AddPagePreview({
    super.key,
    required this.background,
    required this.colorScheme,
    required this.canvasMode,
    required this.pageSize,
  });

  final core.PageBackground background;
  final CanvasColorScheme colorScheme;
  final core.CanvasMode canvasMode;
  final core.PageSize pageSize;

  @override
  Widget build(BuildContext context) {
    final bg = background;
    final surroundColor = canvasMode.isInfinite
        ? Color(bg.color)
        : Color(canvasMode.surroundingAreaColor);
    final materialTheme = Theme.of(context);
    final previewColorScheme = materialTheme.colorScheme;
    final brightness = materialTheme.brightness;

    return LayoutBuilder(builder: (_, constraints) {
      final vw = constraints.maxWidth;
      final vh = constraints.maxHeight;
      final pw = pageSize.width;
      final ph = pageSize.height;
      // Fit page within viewport with padding
      final fitZoom = (vw / pw < vh / ph ? vw / pw : vh / ph) * 0.88;
      final pageW = pw * fitZoom;
      final pageH = ph * fitZoom;

      return Container(
          color: surroundColor,
          child: Stack(children: [
            // Centered page with correct aspect ratio
            Positioned(
              left: (vw - pageW) / 2,
              top: (vh - pageH) / 2,
              width: pageW,
              height: pageH,
              child: Container(
                decoration: BoxDecoration(
                  color: Color(bg.color),
                  border: Border.all(
                      color: previewColorScheme.outlineVariant, width: 0.5),
                  boxShadow: DrawingShadows.page(brightness),
                ),
                child: PageBackgroundView(
                    background: bg,
                    colorScheme: colorScheme,
                    pageSize: Size(pageW, pageH)),
              ),
            ),
            // Hint overlay
            Positioned.fill(
                child: Center(
                    child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                  color: previewColorScheme.scrim.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 32),
                const SizedBox(height: 6),
                Text('Yeni sayfa eklemek için\nsürükleyip bırakın',
                    textAlign: TextAlign.center,
                    style: materialTheme.textTheme.bodySmall
                        ?.copyWith(fontSize: 13, color: Colors.white)),
              ]),
            ))),
          ]));
    });
  }
}
