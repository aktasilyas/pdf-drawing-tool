import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:drawing_ui/src/providers/providers.dart';
import 'page_options_widgets.dart';

/// Background options panel for infinite/whiteboard canvas mode.
/// Shows two sections: background pattern and background color.
class InfiniteBackgroundPanel extends ConsumerWidget {
  const InfiniteBackgroundPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final page = ref.watch(currentPageProvider);
    final bg = page.background;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(onClose: onClose),
        pageOptionsDivider(cs),
        _PatternSection(background: bg, onClose: onClose),
        pageOptionsDivider(cs),
        _ColorSection(background: bg, onClose: onClose),
        const SizedBox(height: 12),
      ],
    );

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      shadowColor: Colors.black26,
      child: SizedBox(width: 280, child: content),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 10),
      child: Row(children: [
        Expanded(child: Text('Arka Plan',
          style: GoogleFonts.sourceSerif4(fontSize: 16, fontWeight: FontWeight.w600,
            color: cs.onSurface))),
        IconButton(
          icon: PhosphorIcon(PhosphorIconsLight.x, size: 20,
            color: cs.onSurfaceVariant),
          onPressed: onClose,
          visualDensity: VisualDensity.compact,
        ),
      ]),
    );
  }
}

/// Pattern selection: Düz, Noktalı, Izgara
class _PatternSection extends ConsumerWidget {
  const _PatternSection({required this.background, required this.onClose});
  final PageBackground background;
  final VoidCallback onClose;

  _PatternType get _currentPattern {
    if (background.type == BackgroundType.dotted) return _PatternType.dotted;
    if (background.type == BackgroundType.grid) return _PatternType.grid;
    if (background.type == BackgroundType.template) {
      if (background.templatePattern == TemplatePattern.mediumDots ||
          background.templatePattern == TemplatePattern.smallDots ||
          background.templatePattern == TemplatePattern.largeDots) {
        return _PatternType.dotted;
      }
      if (background.templatePattern == TemplatePattern.smallGrid ||
          background.templatePattern == TemplatePattern.mediumGrid ||
          background.templatePattern == TemplatePattern.largeGrid) {
        return _PatternType.grid;
      }
    }
    return _PatternType.plain;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final current = _currentPattern;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text('Arka Plan Deseni',
              style: GoogleFonts.sourceSerif4(fontSize: 13, fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant)),
          ),
          Row(children: [
            _PatternChip(
              label: 'Düz', type: _PatternType.plain,
              isSelected: current == _PatternType.plain,
              onTap: () => _apply(ref, _PatternType.plain),
            ),
            const SizedBox(width: 8),
            _PatternChip(
              label: 'Noktalı', type: _PatternType.dotted,
              isSelected: current == _PatternType.dotted,
              onTap: () => _apply(ref, _PatternType.dotted),
            ),
            const SizedBox(width: 8),
            _PatternChip(
              label: 'Izgara', type: _PatternType.grid,
              isSelected: current == _PatternType.grid,
              onTap: () => _apply(ref, _PatternType.grid),
            ),
          ]),
        ],
      ),
    );
  }

  void _apply(WidgetRef ref, _PatternType type) {
    final page = ref.read(currentPageProvider);
    final currentColor = background.color;
    final PageBackground newBg;
    switch (type) {
      case _PatternType.plain:
        newBg = PageBackground(type: BackgroundType.blank, color: currentColor);
      case _PatternType.dotted:
        newBg = PageBackground(type: BackgroundType.dotted, color: currentColor,
          gridSpacing: 20.0, lineColor: 0xFFCCCCCC);
      case _PatternType.grid:
        newBg = PageBackground(type: BackgroundType.grid, color: currentColor,
          gridSpacing: 25.0, lineColor: 0xFFCCCCCC);
    }
    ref.read(documentProvider.notifier).updatePageBackground(page.id, newBg);
    ref.read(pageManagerProvider.notifier).updateCurrentPage(
      page.copyWith(background: newBg));
  }
}

/// Color selection: Beyaz, Sarı, Siyah
class _ColorSection extends ConsumerWidget {
  const _ColorSection({required this.background, required this.onClose});
  final PageBackground background;
  final VoidCallback onClose;

  static const _white = 0xFFFFFFFF;
  static const _yellow = 0xFFFFF8E1;
  static const _black = 0xFF1E1E1E;

  int get _currentColorGroup {
    final c = background.color;
    if (c == _yellow) return _yellow;
    if (c == _black || _isDark(c)) return _black;
    return _white;
  }

  static bool _isDark(int argb) {
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    return (r * 299 + g * 587 + b * 114) / 1000 < 80;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final current = _currentColorGroup;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text('Arka Plan Rengi',
              style: GoogleFonts.sourceSerif4(fontSize: 13, fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant)),
          ),
          Row(children: [
            _ColorChip(label: 'Beyaz', color: _white,
              isSelected: current == _white,
              onTap: () => _applyColor(ref, _white)),
            const SizedBox(width: 8),
            _ColorChip(label: 'Sarı', color: _yellow,
              isSelected: current == _yellow,
              onTap: () => _applyColor(ref, _yellow)),
            const SizedBox(width: 8),
            _ColorChip(label: 'Siyah', color: _black,
              isSelected: current == _black,
              onTap: () => _applyColor(ref, _black)),
          ]),
        ],
      ),
    );
  }

  void _applyColor(WidgetRef ref, int colorArgb) {
    final page = ref.read(currentPageProvider);
    final bg = page.background;
    final newBg = PageBackground(
      type: bg.type,
      color: colorArgb,
      gridSpacing: bg.gridSpacing,
      lineSpacing: bg.lineSpacing,
      lineColor: _adjustLineColor(colorArgb, bg.lineColor),
      templatePattern: bg.templatePattern,
      templateSpacingMm: bg.templateSpacingMm,
      templateLineWidth: bg.templateLineWidth,
    );
    ref.read(documentProvider.notifier).updatePageBackground(page.id, newBg);
    ref.read(pageManagerProvider.notifier).updateCurrentPage(
      page.copyWith(background: newBg));
  }

  /// Adjusts line color for dark/light backgrounds.
  static int? _adjustLineColor(int bgColor, int? currentLineColor) {
    if (bgColor == _black) return 0xFF444444;
    return 0xFFCCCCCC;
  }
}

enum _PatternType { plain, dotted, grid }

class _PatternChip extends StatelessWidget {
  const _PatternChip({
    required this.label, required this.type,
    required this.isSelected, required this.onTap,
  });
  final String label;
  final _PatternType type;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: isSelected ? cs.primaryContainer : cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: cs.primary, width: 2)
                : Border.all(color: cs.outlineVariant, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PatternIcon(type: type, color: isSelected
                  ? cs.onPrimaryContainer : cs.onSurfaceVariant),
              const SizedBox(height: 4),
              Text(label, style: GoogleFonts.sourceSerif4(fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatternIcon extends StatelessWidget {
  const _PatternIcon({required this.type, required this.color});
  final _PatternType type;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24, height: 24,
      child: CustomPaint(painter: _MiniPatternPainter(type: type, color: color)),
    );
  }
}

class _MiniPatternPainter extends CustomPainter {
  const _MiniPatternPainter({required this.type, required this.color});
  final _PatternType type;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1;
    switch (type) {
      case _PatternType.plain:
        // Simple rectangle outline
        paint.style = PaintingStyle.stroke;
        canvas.drawRRect(
          RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(3)),
          paint);
      case _PatternType.dotted:
        paint.style = PaintingStyle.fill;
        const spacing = 6.0;
        for (double x = spacing; x < size.width; x += spacing) {
          for (double y = spacing; y < size.height; y += spacing) {
            canvas.drawCircle(Offset(x, y), 1, paint);
          }
        }
      case _PatternType.grid:
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 0.5;
        const spacing = 6.0;
        for (double x = spacing; x < size.width; x += spacing) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
        }
        for (double y = spacing; y < size.height; y += spacing) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniPatternPainter old) =>
      old.type != type || old.color != color;
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({
    required this.label, required this.color,
    required this.isSelected, required this.onTap,
  });
  final String label;
  final int color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = _ColorSection._isDark(color);
    // Use contrast-safe colors based on chip background, not theme
    final textColor = isDark
        ? const Color(0xFFF2F3F6)
        : const Color(0xFF1B1F23);
    final checkColor = isDark
        ? const Color(0xFFF2F3F6)
        : cs.primary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Color(color),
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: cs.primary, width: 2)
                : Border.all(color: cs.outlineVariant, width: 1),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected) ...[
                Icon(Icons.check, size: 14, color: checkColor),
                const SizedBox(width: 4),
              ],
              Text(label, style: GoogleFonts.sourceSerif4(fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: textColor)),
            ],
          ),
        ),
      ),
    );
  }
}
