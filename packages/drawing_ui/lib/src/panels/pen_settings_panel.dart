import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/widgets/unified_color_picker.dart';
import 'package:drawing_ui/src/widgets/floating_pen_box.dart' show RealisticPenPainter;
import 'package:drawing_ui/src/panels/tool_panel.dart';

/// Settings panel for pen tools (ballpoint, fountain, pencil, brush).
///
/// Allows configuring thickness, stabilization, color, and nib shape.
/// All changes update MOCK state only - no real drawing effect.
class PenSettingsPanel extends ConsumerWidget {
  const PenSettingsPanel({
    super.key,
    required this.toolType,
    this.onClose,
  });

  /// The type of pen tool being configured.
  final ToolType toolType;

  /// Callback when panel is closed.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(penSettingsProvider(toolType));
    final currentTool = ref.watch(currentToolProvider);

    return ToolPanel(
      title: _getTurkishTitle(toolType),
      onClose: onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live stroke preview (compact)
          _LiveStrokePreview(
            color: settings.color,
            thickness: settings.thickness,
            toolType: toolType,
          ),
          const SizedBox(height: 12),

          // 4 Pen type selector (compact)
          _PenTypeSelector(
            selectedType: currentTool,
            onTypeSelected: (type) {
              ref.read(currentToolProvider.notifier).state = type;
            },
          ),
          const SizedBox(height: 14),

          // Thickness slider (compact) - dynamic range based on tool
          _CompactSliderSection(
            title: 'Kalınlık',
            value: settings.thickness.clamp(_getMinThickness(toolType), _getMaxThickness(toolType)),
            min: _getMinThickness(toolType),
            max: _getMaxThickness(toolType),
            label: '${settings.thickness.toStringAsFixed(1)}mm',
            color: settings.color,
            onChanged: (value) {
              ref.read(penSettingsProvider(toolType).notifier).setThickness(value);
            },
          ),
          const SizedBox(height: 12),

          // Stabilization slider (compact)
          _CompactSliderSection(
            title: 'Sabitleme',
            value: settings.stabilization,
            min: 0.0,
            max: 1.0,
            label: '${(settings.stabilization * 100).round()}%',
            onChanged: (value) {
              ref.read(penSettingsProvider(toolType).notifier).setStabilization(value);
            },
          ),
          const SizedBox(height: 14),

          // Compact color row (6 colors + more on double tap)
          _CompactColorRow(
            selectedColor: settings.color,
            onColorSelected: (color) {
              ref.read(penSettingsProvider(toolType).notifier).setColor(color);
            },
          ),
          const SizedBox(height: 14),

          // Add to pen box button (compact)
          _CompactActionButton(
            label: 'Kalem kutusuna ekle',
            icon: Icons.add,
            onPressed: () => _addToPenBox(context, ref, settings),
          ),
        ],
      ),
    );
  }

  String _getTurkishTitle(ToolType type) {
    // Use PenType config for display name
    final penType = type.penType;
    if (penType != null) {
      return penType.config.displayNameTr;
    }
    return 'Kalem';
  }

  double _getMinThickness(ToolType type) {
    // Use PenType config for min thickness
    final penType = type.penType;
    if (penType != null) {
      return penType.config.minThickness;
    }
    return 0.1;
  }

  double _getMaxThickness(ToolType type) {
    // Use PenType config for max thickness
    final penType = type.penType;
    if (penType != null) {
      return penType.config.maxThickness;
    }
    return 20.0;
  }

  void _addToPenBox(BuildContext context, WidgetRef ref, PenSettings settings) {
    final presets = ref.read(penBoxPresetsProvider);
    // Güncel seçili kalem tipini al (popup'ta değişmiş olabilir)
    final currentTool = ref.read(currentToolProvider);
    // Güncel kalem tipinin ayarlarını al
    final currentSettings = ref.read(penSettingsProvider(currentTool));
    
    // Duplicate kontrolü - aynı tool, renk ve kalınlık varsa ekleme
    final isDuplicate = presets.any((p) => 
      !p.isEmpty &&
      p.toolType == currentTool &&
      p.color.value == currentSettings.color.value &&
      (p.thickness - currentSettings.thickness).abs() < 0.1
    );
    
    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu kalem zaten kalem kutusunda mevcut'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    final newPreset = PenPreset(
      id: 'preset_${DateTime.now().millisecondsSinceEpoch}',
      toolType: currentTool,
      color: currentSettings.color,
      thickness: currentSettings.thickness,
      nibShape: currentSettings.nibShape,
    );
    ref.read(penBoxPresetsProvider.notifier).addPreset(newPreset);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kalem kutusuna eklendi'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

/// Live stroke preview showing current pen settings (compact).
class _LiveStrokePreview extends StatelessWidget {
  const _LiveStrokePreview({
    required this.color,
    required this.thickness,
    required this.toolType,
  });

  final Color color;
  final double thickness;
  final ToolType toolType;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: CustomPaint(
          size: const Size(double.infinity, 36),
          painter: _StrokePreviewPainter(
            color: color,
            thickness: thickness,
            toolType: toolType,
          ),
        ),
      ),
    );
  }
}

/// Painter for stroke preview (compact).
class _StrokePreviewPainter extends CustomPainter {
  _StrokePreviewPainter({
    required this.color,
    required this.thickness,
    required this.toolType,
  });

  final Color color;
  final double thickness;
  final ToolType toolType;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness * 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final startY = size.height / 2;
    path.moveTo(16, startY);

    // Compact wave pattern
    for (var x = 16.0; x < size.width - 16; x += 24) {
      final amplitude = 8.0;
      path.quadraticBezierTo(x + 6, startY - amplitude, x + 12, startY);
      path.quadraticBezierTo(x + 18, startY + amplitude, x + 24, startY);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_StrokePreviewPainter oldDelegate) {
    return color != oldDelegate.color ||
        thickness != oldDelegate.thickness ||
        toolType != oldDelegate.toolType;
  }
}

/// Selector for all 9 pen types.
class _PenTypeSelector extends StatelessWidget {
  const _PenTypeSelector({
    required this.selectedType,
    required this.onTypeSelected,
  });

  final ToolType selectedType;
  final ValueChanged<ToolType> onTypeSelected;

  // All 9 pen types
  static const _penTypes = [
    ToolType.pencil,
    ToolType.hardPencil,
    ToolType.ballpointPen,
    ToolType.gelPen,
    ToolType.dashedPen,
    ToolType.highlighter,
    ToolType.brushPen,
    ToolType.marker,
    ToolType.neonHighlighter,
  ];

  @override
  Widget build(BuildContext context) {
    // Use Wrap instead of Row to handle 9 items
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: _penTypes.map((type) {
        final isSelected = type == selectedType;
        return _PenTypeOption(
          type: type,
          isSelected: isSelected,
          onTap: () => onTypeSelected(type),
        );
      }).toList(),
    );
  }
}

/// A single pen type option (compact).
class _PenTypeOption extends StatelessWidget {
  const _PenTypeOption({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  final ToolType type;
  final bool isSelected;
  final VoidCallback onTap;

  static const _selectedColor = Color(0xFF4A9DFF);

  @override
  Widget build(BuildContext context) {
    // Get display name from PenType config
    final displayName = type.penType?.config.displayNameTr ?? type.displayName;

    return Tooltip(
      message: displayName,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isSelected ? _selectedColor.withAlpha(20) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? _selectedColor : Colors.grey.shade300,
              width: isSelected ? 1.5 : 0.5,
            ),
          ),
          child: Center(
            child: CustomPaint(
              size: const Size(28, 28),
              painter: RealisticPenPainter(
                toolType: type,
                tipColor: isSelected ? _selectedColor : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact slider section with inline title and value.
class _CompactSliderSection extends StatelessWidget {
  const _CompactSliderSection({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    required this.onChanged,
    this.color,
  });

  final String title;
  final double value;
  final double min;
  final double max;
  final String label;
  final ValueChanged<double> onChanged;
  final Color? color;

  static const _accentColor = Color(0xFF4A9DFF);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 20,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: color ?? _accentColor,
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: color ?? _accentColor,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact color row using unified color system.
class _CompactColorRow extends StatelessWidget {
  const _CompactColorRow({
    required this.selectedColor,
    required this.onColorSelected,
  });

  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Renk',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        UnifiedColorPicker(
          selectedColor: selectedColor,
          onColorSelected: onColorSelected,
          quickColors: ColorSets.quickAccess,
          colorSets: ColorSets.all,
          chipSize: 28.0,
          spacing: 8.0,
        ),
      ],
    );
  }
}

/// Compact action button.
class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: const Color(0xFF374151)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
