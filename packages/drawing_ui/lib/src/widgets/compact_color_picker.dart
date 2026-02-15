/// Samsung Notes-style color picker with Kartelalar (swatch) and Spektrum tabs.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';
import 'package:drawing_ui/src/providers/recent_colors_provider.dart';
import 'package:drawing_ui/src/widgets/color_swatch_grid.dart';
import 'package:drawing_ui/src/widgets/spectrum_picker.dart';

/// Compact color picker — Samsung Notes inspired.
class CompactColorPicker extends ConsumerStatefulWidget {
  const CompactColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    this.showOpacity = true,
    this.onClose,
  });

  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final bool showOpacity;
  final VoidCallback? onClose;

  @override
  ConsumerState<CompactColorPicker> createState() => _CompactColorPickerState();
}

class _CompactColorPickerState extends ConsumerState<CompactColorPicker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late HSVColor _hsvColor;
  late double _opacity;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _hsvColor = HSVColor.fromColor(widget.selectedColor);
    _opacity = widget.selectedColor.a;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color get _currentColor =>
      _hsvColor.toColor().withValues(alpha: widget.showOpacity ? _opacity : 1.0);

  void _selectColor(Color color) {
    setState(() {
      _hsvColor = HSVColor.fromColor(color);
      _opacity = color.a.clamp(0.01, 1.0);
    });
  }

  void _close() {
    widget.onClose != null ? widget.onClose!() : Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxH = (MediaQuery.of(context).size.height * 0.65).clamp(380.0, 560.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Container(
        width: 300,
        margin: const EdgeInsets.all(8),
        constraints: BoxConstraints(maxHeight: maxH),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHighest : cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: isDark
              ? Border.all(color: cs.outline.withValues(alpha: 0.2))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTabBar(cs),
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: ColorSwatchGrid(
                      selectedColor: _currentColor,
                      onColorSelected: _selectColor,
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: SpectrumPicker(
                      hsvColor: _hsvColor,
                      onColorChanged: (hsv) => setState(() => _hsvColor = hsv),
                      showOpacity: widget.showOpacity,
                      opacity: _opacity,
                      onOpacityChanged: (v) => setState(() => _opacity = v),
                    ),
                  ),
                ],
              ),
            ),
            _ColorInfoBar(color: _currentColor),
            _DottedDivider(color: cs.outlineVariant),
            _RecentColorsRow(
              onColorSelected: _selectColor,
              outlineColor: cs.outlineVariant,
              iconColor: cs.onSurfaceVariant,
            ),
            _ActionButtons(
              onCancel: _close,
              onDone: () {
                ref.read(recentColorsProvider.notifier).addColor(_currentColor);
                widget.onColorSelected(_currentColor);
              },
              textColor: cs.onSurface,
              primaryColor: cs.primary,
              dividerColor: cs.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        child: TabBar(
          controller: _tabController,
          labelColor: cs.onSurface,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicator: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerHeight: 0,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: const [Tab(text: 'Kartelalar'), Tab(text: 'Spektrum')],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared bottom-section widgets
// ---------------------------------------------------------------------------

/// Color preview + hex + RGB info.
class _ColorInfoBar extends StatelessWidget {
  const _ColorInfoBar({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    final hex = r.toRadixString(16).padLeft(2, '0') +
        g.toRadixString(16).padLeft(2, '0') +
        b.toRadixString(16).padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(children: [
        // Preview rectangle
        Container(
          width: 48,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 8),
        _infoCol('Altıgen', '#${hex.toUpperCase()}', cs),
        _infoCol('Kırmızı', '$r', cs),
        _infoCol('Yeşil', '$g', cs),
        _infoCol('Mavi', '$b', cs),
      ]),
    );
  }

  Widget _infoCol(String label, String value, ColorScheme cs) {
    return Expanded(
      child: Column(children: [
        Text(label,
            style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.onSurface)),
      ]),
    );
  }
}

/// Dotted line separator (Samsung Notes style).
class _DottedDivider extends StatelessWidget {
  const _DottedDivider({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: LayoutBuilder(builder: (_, c) {
        final count = (c.maxWidth / 5).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => Container(
              width: 2,
              height: 2,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        );
      }),
    );
  }
}

/// 5 recent-color slots + eyedropper icon.
class _RecentColorsRow extends StatelessWidget {
  const _RecentColorsRow({
    required this.onColorSelected,
    required this.outlineColor,
    required this.iconColor,
  });

  final ValueChanged<Color> onColorSelected;
  final Color outlineColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Consumer(builder: (context, ref, _) {
        final recent = ref.watch(recentColorsProvider);
        return Row(children: [
          ...List.generate(5, (i) {
            if (i < recent.length) {
              return _slot(
                child: GestureDetector(
                  onTap: () => onColorSelected(recent[i]),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: recent[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: outlineColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              );
            }
            return _slot(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: outlineColor),
                ),
              ),
            );
          }),
          const Spacer(),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: outlineColor),
            ),
            child: PhosphorIcon(
                StarNoteIcons.colorize, size: 16, color: iconColor),
          ),
        ]);
      }),
    );
  }

  Widget _slot({required Widget child}) =>
      Padding(padding: const EdgeInsets.only(right: 8), child: child);
}

/// Cancel / Done action buttons.
class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.onCancel,
    required this.onDone,
    required this.textColor,
    required this.primaryColor,
    required this.dividerColor,
  });

  final VoidCallback onCancel;
  final VoidCallback onDone;
  final Color textColor;
  final Color primaryColor;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(children: [
        Expanded(
          child: GestureDetector(
            onTap: onCancel,
            behavior: HitTestBehavior.opaque,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text('İptal et',
                    style: TextStyle(fontSize: 15, color: textColor)),
              ),
            ),
          ),
        ),
        Container(width: 1, height: 20, color: dividerColor),
        Expanded(
          child: GestureDetector(
            onTap: onDone,
            behavior: HitTestBehavior.opaque,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text('Bitti',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: primaryColor)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
