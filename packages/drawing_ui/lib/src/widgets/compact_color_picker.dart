/// Samsung Notes-style color picker with Kartelalar (swatch) and Spektrum tabs.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/providers/recent_colors_provider.dart';
import 'package:drawing_ui/src/theme/chrome_roles.dart';
import 'package:drawing_ui/src/theme/chrome_tokens.dart';
import 'package:drawing_ui/src/theme/drawing_shadows.dart';
import 'package:drawing_ui/src/widgets/color_picker_actions.dart';
import 'package:drawing_ui/src/widgets/color_picker_info_bar.dart';
import 'package:drawing_ui/src/widgets/color_picker_logic.dart';
import 'package:drawing_ui/src/widgets/color_picker_recent_row.dart';
import 'package:drawing_ui/src/widgets/color_swatch_grid.dart';
import 'package:drawing_ui/src/widgets/spectrum_picker.dart';

/// Compact color picker — Samsung Notes inspired.
///
/// Reports the picked colour through [onColorSelected] when the user taps
/// "Bitti" (and records it as a recent colour); "İptal et" calls [onClose],
/// or pops the route when [onClose] is null.
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

  Color get _currentColor => ColorPickerLogic.compose(
        _hsvColor,
        _opacity,
        showOpacity: widget.showOpacity,
      );

  void _selectColor(Color color) {
    setState(() {
      _hsvColor = HSVColor.fromColor(color);
      _opacity = ColorPickerLogic.opacityOf(color);
    });
  }

  void _close() {
    widget.onClose != null ? widget.onClose!() : Navigator.maybePop(context);
  }

  void _done() {
    final color = _currentColor;
    ref.read(recentColorsProvider.notifier).addColor(color);
    widget.onColorSelected(color);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxH =
        (MediaQuery.of(context).size.height * 0.65).clamp(380.0, 560.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Container(
        width: 300,
        margin: const EdgeInsets.all(ChromeSpacing.sm),
        constraints: BoxConstraints(maxHeight: maxH),
        decoration: BoxDecoration(
          color: cs.pickerSurface,
          borderRadius: BorderRadius.circular(ChromeRadius.xl),
          border: cs.outlinedFloatingBorder,
          boxShadow: DrawingShadows.panel(Theme.of(context).brightness),
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
                    padding: const EdgeInsets.all(ChromeSpacing.lg),
                    child: ColorSwatchGrid(
                      selectedColor: _currentColor,
                      onColorSelected: _selectColor,
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(ChromeSpacing.lg),
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
            ColorPickerInfoBar(color: _currentColor),
            ColorPickerDottedDivider(color: cs.outlineVariant),
            ColorPickerRecentRow(
              onColorSelected: _selectColor,
              outlineColor: cs.outlineVariant,
              iconColor: cs.onSurfaceVariant,
            ),
            ColorPickerActions(
              onCancel: _close,
              onDone: _done,
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
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ChromeSpacing.lg,
        ChromeSpacing.lg,
        ChromeSpacing.lg,
        ChromeSpacing.sm,
      ),
      child: Container(
        height: ChromeSizes.minTouchTarget,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(ChromeSizes.minTouchTarget / 2),
        ),
        child: TabBar(
          controller: _tabController,
          labelColor: cs.onSurface,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicator: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius:
                BorderRadius.circular(ChromeSizes.minTouchTarget / 2),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerHeight: 0,
          labelStyle: textTheme.titleSmall?.copyWith(fontSize: 13),
          unselectedLabelStyle: textTheme.bodySmall?.copyWith(fontSize: 13),
          tabs: const [Tab(text: 'Kartelalar'), Tab(text: 'Spektrum')],
        ),
      ),
    );
  }
}
