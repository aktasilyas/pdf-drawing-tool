/// Compact color picker with tabs and HSV controls.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/providers/recent_colors_provider.dart';
import 'package:drawing_ui/src/widgets/color_picker_widgets.dart';
import 'package:drawing_ui/src/widgets/color_presets.dart';

/// Kompakt renk seçici - Fenci tarzı
class CompactColorPicker extends StatefulWidget {
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
  State<CompactColorPicker> createState() => _CompactColorPickerState();
}

class _CompactColorPickerState extends State<CompactColorPicker>
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

  Color get _currentColor {
    return _hsvColor.toColor().withValues(alpha: widget.showOpacity ? _opacity : 1.0);
  }

  void _updateColor(HSVColor hsv) {
    setState(() => _hsvColor = hsv);
  }

  void _updateOpacity(double opacity) {
    setState(() => _opacity = opacity);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    // Responsive height - max 60% of screen or 420px, whichever is smaller
    final maxContentHeight = (screenHeight * 0.55).clamp(280.0, 420.0);

    // Wrap in GestureDetector to absorb all taps and prevent propagation to underlying overlays
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {}, // Absorb taps - do nothing
      child: Container(
        width: 280,
        margin: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxHeight: maxContentHeight + 80, // 80 for header
        ),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerHighest : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ) : null,
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
            // Header with tabs
            _buildHeader(),
            // Tab content - flexible height
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildColorPaletteTab(),
                  _buildColorSetsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        // Close button
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  // Use callback if provided, otherwise try Navigator.pop
                  if (widget.onClose != null) {
                    widget.onClose!();
                  } else if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        // TabBar
        TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          indicatorColor: colorScheme.primary,
          indicatorWeight: 2,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: 'Renk paleti'),
            Tab(text: 'Renk Seti'),
          ],
        ),
      ],
    );
  }

  Widget _buildColorPaletteTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // HSV Picker Box
          HSVPickerBox(
            hsvColor: _hsvColor,
            onColorChanged: _updateColor,
          ),
          const SizedBox(height: 16),
          // Hue Slider
          HueSlider(
            hue: _hsvColor.hue,
            onChanged: (hue) => _updateColor(_hsvColor.withHue(hue)),
          ),
          const SizedBox(height: 12),
          // Opacity Slider
          if (widget.showOpacity) ...[
            OpacitySlider(
              color: _hsvColor.toColor(),
              opacity: _opacity,
              onChanged: _updateOpacity,
            ),
            const SizedBox(height: 16),
          ],
          // Hex + Opacity Input
          HexOpacityInput(
            color: _currentColor,
            opacity: _opacity,
            showOpacity: widget.showOpacity,
            onColorChanged: (color) {
              setState(() {
                _hsvColor = HSVColor.fromColor(color);
                _opacity = color.a;
              });
            },
            onSave: () => widget.onColorSelected(_currentColor),
          ),
          const SizedBox(height: 16),
          // Recent Colors - tap to apply immediately
          Consumer(
            builder: (context, ref, _) {
              final recentColors = ref.watch(recentColorsProvider);
              if (recentColors.isEmpty) return const SizedBox.shrink();
              
              return Column(
                children: [
                  const Divider(color: Color(0xFF424242), height: 1),
                  const SizedBox(height: 12),
                  RecentColorsRow(
                    colors: recentColors,
                    selectedColor: _currentColor,
                    onColorSelected: (color) {
                      // Apply immediately when recent color is tapped
                      widget.onColorSelected(color);
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColorSetsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPresetCategory('Classic note (light)', ColorPresets.classicLight),
          const SizedBox(height: 16),
          _buildPresetCategory('Classic note (dark)', ColorPresets.classicDark),
          const SizedBox(height: 16),
          _buildPresetCategory('Highlighter', ColorPresets.highlighter),
          const SizedBox(height: 16),
          _buildPresetCategory('Tape (cream)', ColorPresets.tapeCream),
          const SizedBox(height: 16),
          _buildPresetCategory('Tape (bright)', ColorPresets.tapeBright),
        ],
      ),
    );
  }

  Widget _buildPresetCategory(String title, List<Color> colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFE0E0E0),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((color) {
            final isSelected = _colorsMatch(color, _currentColor);
            return GestureDetector(
              onTap: () => widget.onColorSelected(
                color.withValues(alpha: widget.showOpacity ? _opacity : 1.0),
              ),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF4FC3F7)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  bool _colorsMatch(Color a, Color b) {
    return (a.r * 255).round() == (b.r * 255).round() &&
        (a.g * 255).round() == (b.g * 255).round() &&
        (a.b * 255).round() == (b.b * 255).round();
  }
}
