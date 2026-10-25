/// Non-page cells of the page sidebar: the dashed "Sayfa ekle" cell and the
/// empty bookmarks state (docs/specs/52-editor-chrome.md, section 4).
import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import 'package:drawing_ui/src/panels/panels.dart';
import 'package:drawing_ui/src/theme/chrome_palette.dart';
import 'package:drawing_ui/src/theme/chrome_tokens.dart';
import 'package:drawing_ui/src/theme/elyanotes_icons.dart';
import 'package:drawing_ui/src/widgets/widgets.dart';

import 'page_sidebar_widgets.dart';

/// Dashed "Sayfa ekle" cell; opens the same popover as the toolbar's
/// add-page button.
class AddPageCell extends StatefulWidget {
  const AddPageCell({super.key});

  @override
  State<AddPageCell> createState() => _AddPageCellState();
}

class _AddPageCellState extends State<AddPageCell> {
  final PopoverController _popover = PopoverController();
  final GlobalKey _anchorKey = GlobalKey();

  @override
  void dispose() {
    _popover.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_popover.isShowing) {
      _popover.hide();
      return;
    }
    _popover.show(
      context: context,
      anchorKey: _anchorKey,
      maxWidth: 320,
      onDismiss: () {},
      child: AddPagePanel(onClose: () => _popover.hide(), embedded: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: 'Sayfa ekle',
            excludeSemantics: true,
            child: GestureDetector(
              key: _anchorKey,
              onTap: _toggle,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(kPageGridRingInset),
                child: CustomPaint(
                  painter: DashedOutlinePainter(color: palette.border),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PhosphorIcon(
                        ElyanotesIcons.plus,
                        size: ChromeIconSizes.lg,
                        color: palette.textMuted,
                      ),
                      const SizedBox(height: ChromeSpacing.xs),
                      Text(
                        'Sayfa ekle',
                        style: textTheme.labelMedium?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: ChromeSizes.minTouchTarget),
      ],
    );
  }
}

/// 1dp dashed rounded-rect outline (radius sm, 4 on / 4 off).
///
/// The dash path is built once per size and reused across repaints.
class DashedOutlinePainter extends CustomPainter {
  DashedOutlinePainter({required this.color});

  final Color color;

  static const double _dash = 4;
  static const double _gap = 4;

  late final Paint _paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  Path? _dashes;
  Size? _dashesSize;

  Path _buildDashes(Size size) {
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.5),
          const Radius.circular(ChromeRadius.sm),
        ),
      );
    final dashes = Path();
    for (final metric in outline.computeMetrics()) {
      for (double d = 0; d < metric.length; d += _dash + _gap) {
        dashes.addPath(metric.extractPath(d, d + _dash), Offset.zero);
      }
    }
    return dashes;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_dashes == null || _dashesSize != size) {
      _dashes = _buildDashes(size);
      _dashesSize = size;
    }
    canvas.drawPath(_dashes!, _paint);
  }

  @override
  bool shouldRepaint(DashedOutlinePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Bookmarks filter with no bookmarked pages.
class EmptyBookmarksState extends StatelessWidget {
  const EmptyBookmarksState({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ChromeSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              ElyanotesIcons.bookmark,
              size: ChromeIconSizes.lg,
              color: palette.textMuted,
            ),
            const SizedBox(height: ChromeSpacing.sm),
            Text(
              'Henüz yer imi yok',
              textAlign: TextAlign.center,
              style: textTheme.titleSmall?.copyWith(
                color: palette.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: ChromeSpacing.xs),
            Text(
              'Bir sayfayı işaretlemek için küçük resmindeki yer imi '
              'simgesine dokunun.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
