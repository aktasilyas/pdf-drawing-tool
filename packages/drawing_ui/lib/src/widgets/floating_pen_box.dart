import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/widgets/pen_icon_widget.dart';

/// Floating pen box that appears on the canvas.
/// Draggable, collapsible, with edit mode for removing pens.
class FloatingPenBox extends ConsumerStatefulWidget {
  const FloatingPenBox({
    super.key,
    this.onPositionChanged,
    this.position = const Offset(12, 12),
    this.onOpenPenSettings,
  });

  final ValueChanged<Offset>? onPositionChanged;
  final Offset position;
  final void Function(ToolType toolType)? onOpenPenSettings;

  @override
  ConsumerState<FloatingPenBox> createState() => _FloatingPenBoxState();
}

class _FloatingPenBoxState extends ConsumerState<FloatingPenBox> {
  bool _isExpanded = true;
  bool _isEditMode = false;

  bool get _shouldOpenHorizontally {
    final screenWidth = WidgetsBinding
            .instance.platformDispatcher.views.first.physicalSize.width /
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final x = widget.position.dx;
    final y = widget.position.dy;

    final isNearLeftEdge = x < 80;
    final isNearRightEdge = x > screenWidth - 150;
    final isNearTop = y < 200;

    return !isNearLeftEdge && !isNearRightEdge && isNearTop;
  }

  @override
  Widget build(BuildContext context) {
    final presets = ref.watch(penBoxPresetsProvider);
    final activePresets = presets.where((p) => !p.isEmpty).toList();

    if (activePresets.isEmpty) {
      return const SizedBox.shrink();
    }

    final content = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _isExpanded
          ? (_shouldOpenHorizontally
              ? _buildHorizontalExpandedView(activePresets, presets)
              : _buildVerticalExpandedView(activePresets, presets))
          : _buildCollapsedView(activePresets.length),
    );

    if (!_isExpanded) {
      return GestureDetector(
        onPanUpdate: (details) {
          widget.onPositionChanged?.call(details.delta);
        },
        child: content,
      );
    }

    return content;
  }

  Widget _buildCollapsedView(int count) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = true),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.brush_outlined, size: 18, color: Colors.grey.shade600),
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Color(0xFF4A9DFF),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalExpandedView(
      List<PenPreset> activePresets, List<PenPreset> allPresets) {
    final selectedIndex = ref.watch(selectedPresetIndexProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...activePresets.asMap().entries.map((entry) {
          final index = allPresets.indexOf(entry.value);
          final isSelected = index == selectedIndex;
          return _VerticalPenSlot(
            preset: entry.value,
            isSelected: isSelected,
            isEditMode: _isEditMode,
            onTap: () => _onPresetTap(index, entry.value),
            onDoubleTap: () => _onPresetDoubleTap(entry.value),
            onDelete: () => _deletePreset(index),
          );
        }),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildHorizontalExpandedView(
      List<PenPreset> activePresets, List<PenPreset> allPresets) {
    final selectedIndex = ref.watch(selectedPresetIndexProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...activePresets.asMap().entries.map((entry) {
          final index = allPresets.indexOf(entry.value);
          final isSelected = index == selectedIndex;
          return _HorizontalPenSlot(
            preset: entry.value,
            isSelected: isSelected,
            isEditMode: _isEditMode,
            onTap: () => _onPresetTap(index, entry.value),
            onDoubleTap: () => _onPresetDoubleTap(entry.value),
            onDelete: () => _deletePreset(index),
          );
        }),
        _buildRightBar(),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isEditMode = !_isEditMode),
            child: Icon(
              _isEditMode ? Icons.check : Icons.edit_outlined,
              size: 14,
              color: _isEditMode ? Colors.green : Colors.grey.shade500,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() {
              _isExpanded = false;
              _isEditMode = false;
            }),
            child: Icon(Icons.keyboard_arrow_up,
                size: 16, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildRightBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isEditMode = !_isEditMode),
            child: Icon(
              _isEditMode ? Icons.check : Icons.edit_outlined,
              size: 14,
              color: _isEditMode ? Colors.green : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() {
              _isExpanded = false;
              _isEditMode = false;
            }),
            child: Icon(Icons.keyboard_arrow_left,
                size: 16, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  void _onPresetTap(int index, PenPreset preset) {
    if (_isEditMode) return;
    ref.read(selectedPresetIndexProvider.notifier).state = index;
    ref.read(currentToolProvider.notifier).state = preset.toolType;
    ref.read(penSettingsProvider(preset.toolType).notifier)
      ..setColor(preset.color)
      ..setThickness(preset.thickness)
      ..setNibShape(preset.nibShape);
    ref.read(activePanelProvider.notifier).state = null;
  }

  void _onPresetDoubleTap(PenPreset preset) {
    if (_isEditMode) return;

    // Highlighter mı pen mi kontrol et ve uygun paneli aç
    if (preset.toolType == ToolType.highlighter ||
        preset.toolType == ToolType.neonHighlighter) {
      ref.read(activePanelProvider.notifier).state = ToolType.highlighter;
    } else {
      ref.read(activePanelProvider.notifier).state = preset.toolType;
    }
  }

  void _deletePreset(int index) {
    ref.read(penBoxPresetsProvider.notifier).removePreset(index);
  }
}

/// Vertical slot - kalem yatay, uç SAĞA bakıyor
/// Başlangıçta sadece uç ve şerit görünür, seçilince daha fazla görünür
class _VerticalPenSlot extends StatelessWidget {
  const _VerticalPenSlot({
    required this.preset,
    required this.isSelected,
    required this.isEditMode,
    required this.onTap,
    required this.onDelete,
    this.onDoubleTap,
  });

  final PenPreset preset;
  final bool isSelected;
  final bool isEditMode;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onDoubleTap;

  // Görünür alan
  static const double _slotWidth = 56;
  static const double _slotHeight = 48;

  // Kalem boyutu
  static const double _penSize = 50;

  @override
  Widget build(BuildContext context) {
    // Seçili: kalem sağa kayar (daha fazla görünür)
    // Seçili değil: kalem solda (sadece uç ve şerit görünür)
    final double leftOffset = isSelected ? 6 : -16;

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: _slotWidth,
        height: _slotHeight,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              left: leftOffset,
              top: (_slotHeight - _penSize) / 2,
              width: _penSize,
              height: _penSize,
              child: ToolPenIcon(
                toolType: preset.toolType,
                color: preset.color,
                isSelected: false,
                size: _penSize,
                orientation: PenOrientation.horizontal,
              ),
            ),
            if (isEditMode)
              Positioned(
                right: 2,
                top: 2,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.remove, size: 10, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal slot - kalem dikey, uç AŞAĞI bakıyor
/// Başlangıçta sadece uç ve şerit görünür, seçilince daha fazla görünür
class _HorizontalPenSlot extends StatelessWidget {
  const _HorizontalPenSlot({
    required this.preset,
    required this.isSelected,
    required this.isEditMode,
    required this.onTap,
    required this.onDelete,
    this.onDoubleTap,
  });

  final PenPreset preset;
  final bool isSelected;
  final bool isEditMode;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onDoubleTap;

  // Görünür alan
  static const double _slotWidth = 48;
  static const double _slotHeight = 56;

  // Kalem boyutu
  static const double _penSize = 50;

  @override
  Widget build(BuildContext context) {
    // Seçili: kalem aşağı kayar (daha fazla görünür)
    // Seçili değil: kalem yukarıda (sadece uç ve şerit görünür)
    final double topOffset = isSelected ? 6 : -16;

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: _slotWidth,
        height: _slotHeight,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              top: topOffset,
              left: (_slotWidth - _penSize) / 2,
              width: _penSize,
              height: _penSize,
              child: Transform.rotate(
                angle: 3.14159, // 180° - uç aşağı baksın
                child: ToolPenIcon(
                  toolType: preset.toolType,
                  color: preset.color,
                  isSelected: false,
                  size: _penSize,
                  orientation: PenOrientation.vertical,
                ),
              ),
            ),
            if (isEditMode)
              Positioned(
                right: 2,
                bottom: 2,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.remove, size: 10, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
