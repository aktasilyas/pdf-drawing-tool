import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/widgets/color_presets.dart';
import 'package:drawing_ui/src/widgets/compact_slider.dart';
import 'package:drawing_ui/src/widgets/unified_color_picker.dart';
import 'package:drawing_ui/src/widgets/pen_icon_widget.dart';
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
    final currentTool = ref.watch(currentToolProvider);
    // Aktif kalem tipine göre settings al (değişime duyarlı)
    final activePenTool = _isPenTool(currentTool) ? currentTool : toolType;
    final settings = ref.watch(penSettingsProvider(activePenTool));

    return ToolPanel(
      title: _getTurkishTitle(activePenTool),
      onClose: onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live stroke preview (compact)
          _LiveStrokePreview(
            color: settings.color,
            thickness: settings.thickness,
            toolType: activePenTool,
          ),
          const SizedBox(height: 8),

          // Pen type selector (compact)
          _PenTypeSelector(
            selectedType: currentTool,
            selectedColor: settings.color,
            onTypeSelected: (type) {
              ref.read(currentToolProvider.notifier).state = type;
            },
          ),
          const SizedBox(height: 10),

          // Thickness slider (compact) - dynamic range based on tool
          CompactSlider(
            title: 'Kalınlık',
            value: settings.thickness.clamp(_getMinThickness(activePenTool),
                _getMaxThickness(activePenTool)),
            min: _getMinThickness(activePenTool),
            max: _getMaxThickness(activePenTool),
            label: '${settings.thickness.toStringAsFixed(1)}mm',
            activeColor: settings.color,
            onChanged: (value) {
              ref
                  .read(penSettingsProvider(activePenTool).notifier)
                  .setThickness(value);
            },
          ),
          const SizedBox(height: 8),

          // Stabilization slider (compact)
          CompactSlider(
            title: 'Sabitleme',
            value: settings.stabilization,
            min: 0.0,
            max: 1.0,
            label: '${(settings.stabilization * 100).round()}%',
            onChanged: (value) {
              ref
                  .read(penSettingsProvider(activePenTool).notifier)
                  .setStabilization(value);
            },
          ),
          const SizedBox(height: 10),

          // Compact color row (6 colors + more on double tap)
          Builder(
            builder: (context) {
              final notifier = ref.read(penSettingsProvider(activePenTool).notifier);
              return _CompactColorRow(
                selectedColor: settings.color,
                onColorSelected: (color) {
                  notifier.setColor(color);
                },
              );
            },
          ),
          const SizedBox(height: 10),

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

  /// Pen tool check
  bool _isPenTool(ToolType tool) {
    return const [
      ToolType.pencil,
      ToolType.hardPencil,
      ToolType.ballpointPen,
      ToolType.gelPen,
      ToolType.dashedPen,
      ToolType.brushPen,
      ToolType.rulerPen,
    ].contains(tool);
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
        (p.thickness - currentSettings.thickness).abs() < 0.1);

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
      height: 28,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: CustomPaint(
          size: const Size(double.infinity, 28),
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

/// Selector for pen types - GoodNotes/Fenci style toolbar.
/// Pens are vertical, tip UP, bottom clipped by container.
/// Selected pen rises up to show more body.
class _PenTypeSelector extends StatelessWidget {
  const _PenTypeSelector({
    required this.selectedType,
    required this.selectedColor,
    required this.onTypeSelected,
  });

  final ToolType selectedType;
  final Color selectedColor;
  final ValueChanged<ToolType> onTypeSelected;

  static const _penTypes = [
    ToolType.pencil,
    ToolType.hardPencil,
    ToolType.ballpointPen,
    ToolType.gelPen,
    ToolType.dashedPen,
    ToolType.brushPen,
    ToolType.rulerPen,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // ÖNEMLİ: clipBehavior ile taşan kısımları kes
      clipBehavior: Clip.hardEdge,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _penTypes.map((type) {
          final isSelected = type == selectedType;
          return _PenSlot(
            type: type,
            isSelected: isSelected,
            selectedColor: selectedColor,
            onTap: () => onTypeSelected(type),
          );
        }).toList(),
      ),
    );
  }
}

/// Single pen slot with proper clipping and animation.
/// Pen is taller than visible area, bottom gets clipped.
/// Selected pen rises up to reveal more of the body.
class _PenSlot extends StatelessWidget {
  const _PenSlot({
    required this.type,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  final ToolType type;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  // Pen dimensions - kompakt
  static const double _penHeight = 56; // Kalem tam yüksekliği
  static const double _slotHeight = 44; // Görünür alan (container height)
  static const double _slotWidth = 32; // Her slot genişliği

  // Vertical offsets (negative = pen moves UP, showing more body)
  static const double _selectedTopOffset = -6; // Seçili: yukarı çık
  static const double _unselectedTopOffset = 4; // Seçili değil: aşağıda kal

  @override
  Widget build(BuildContext context) {
    final displayName = type.penType?.config.displayNameTr ?? type.displayName;

    return Tooltip(
      message: displayName,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: _slotWidth,
          height: _slotHeight,
          // ClipRect - kalem taşmasını keser
          child: ClipRect(
            child: OverflowBox(
              maxHeight: _penHeight + 20, // Animasyon için ekstra alan
              alignment: Alignment.topCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                height: _penHeight,
                margin: EdgeInsets.only(
                  top: isSelected
                      ? _selectedTopOffset + 10
                      : _unselectedTopOffset + 10,
                ),
                child: ToolPenIcon(
                  toolType: type,
                  color: isSelected ? selectedColor : Colors.grey.shade400,
                  isSelected: false, // Selection handled by color
                  size: _penHeight,
                  orientation: PenOrientation.vertical,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// _CompactSliderSection removed - using shared CompactSlider widget

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
        const SizedBox(height: 6),
        UnifiedColorPicker(
          selectedColor: selectedColor,
          onColorSelected: onColorSelected,
          quickColors: ColorSets.quickAccess,
          colorSets: ColorSets.all,
          chipSize: 24.0,
          spacing: 6.0,
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: const Color(0xFF374151)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
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
