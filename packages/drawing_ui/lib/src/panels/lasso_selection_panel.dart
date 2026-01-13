import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/panels/tool_panel.dart';

/// Settings panel for the lasso (kement) selection tool.
///
/// Allows configuring selection mode and selectable element types.
/// All changes update MOCK state only - no real selection effect.
class LassoSelectionPanel extends ConsumerWidget {
  const LassoSelectionPanel({
    super.key,
    this.onClose,
  });

  /// Callback when panel is closed.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(lassoSettingsProvider);

    return ToolPanel(
      title: 'Kement',
      onClose: onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mode selector
          _LassoModeSelector(
            selectedMode: settings.mode,
            onModeSelected: (mode) {
              ref.read(lassoSettingsProvider.notifier).setMode(mode);
            },
          ),
          const SizedBox(height: 24),

          // Selectable types section
          PanelSection(
            title: 'SEÇİLEBİLİR',
            child: Column(
              children: [
                _SelectableTypeToggle(
                  label: 'Şekil',
                  type: SelectableType.shape,
                  value: settings.selectableTypes[SelectableType.shape] ?? true,
                  onChanged: (value) {
                    ref.read(lassoSettingsProvider.notifier)
                        .setSelectableType(SelectableType.shape, value);
                  },
                ),
                const Divider(height: 1),
                _SelectableTypeToggle(
                  label: 'Resim/Çıkartma',
                  type: SelectableType.imageSticker,
                  value: settings.selectableTypes[SelectableType.imageSticker] ?? true,
                  onChanged: (value) {
                    ref.read(lassoSettingsProvider.notifier)
                        .setSelectableType(SelectableType.imageSticker, value);
                  },
                ),
                const Divider(height: 1),
                _SelectableTypeToggle(
                  label: 'Bant',
                  type: SelectableType.tape,
                  value: settings.selectableTypes[SelectableType.tape] ?? true,
                  onChanged: (value) {
                    ref.read(lassoSettingsProvider.notifier)
                        .setSelectableType(SelectableType.tape, value);
                  },
                ),
                const Divider(height: 1),
                _SelectableTypeToggle(
                  label: 'Metin kutusu',
                  type: SelectableType.textBox,
                  value: settings.selectableTypes[SelectableType.textBox] ?? true,
                  onChanged: (value) {
                    ref.read(lassoSettingsProvider.notifier)
                        .setSelectableType(SelectableType.textBox, value);
                  },
                ),
                const Divider(height: 1),
                _SelectableTypeToggle(
                  label: 'El yazısı',
                  type: SelectableType.handwriting,
                  value: settings.selectableTypes[SelectableType.handwriting] ?? true,
                  onChanged: (value) {
                    ref.read(lassoSettingsProvider.notifier)
                        .setSelectableType(SelectableType.handwriting, value);
                  },
                ),
                const Divider(height: 1),
                _SelectableTypeToggle(
                  label: 'Vurgulayıcı',
                  type: SelectableType.highlighter,
                  value: settings.selectableTypes[SelectableType.highlighter] ?? false,
                  onChanged: (value) {
                    ref.read(lassoSettingsProvider.notifier)
                        .setSelectableType(SelectableType.highlighter, value);
                  },
                ),
                const Divider(height: 1),
                _SelectableTypeToggle(
                  label: 'Bağlantı',
                  type: SelectableType.link,
                  value: settings.selectableTypes[SelectableType.link] ?? true,
                  onChanged: (value) {
                    ref.read(lassoSettingsProvider.notifier)
                        .setSelectableType(SelectableType.link, value);
                  },
                ),
                const Divider(height: 1),
                _SelectableTypeToggle(
                  label: 'Etiket',
                  type: SelectableType.label,
                  value: settings.selectableTypes[SelectableType.label] ?? true,
                  onChanged: (value) {
                    ref.read(lassoSettingsProvider.notifier)
                        .setSelectableType(SelectableType.label, value);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Selector for lasso selection modes.
class _LassoModeSelector extends StatelessWidget {
  const _LassoModeSelector({
    required this.selectedMode,
    required this.onModeSelected,
  });

  final LassoMode selectedMode;
  final ValueChanged<LassoMode> onModeSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LassoModeOption(
            mode: LassoMode.freeform,
            icon: Icons.gesture,
            label: 'Serbest\nkement',
            isSelected: selectedMode == LassoMode.freeform,
            onTap: () => onModeSelected(LassoMode.freeform),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _LassoModeOption(
            mode: LassoMode.rectangle,
            icon: Icons.crop_square,
            label: 'Dikdörtgen\nkement',
            isSelected: selectedMode == LassoMode.rectangle,
            onTap: () => onModeSelected(LassoMode.rectangle),
          ),
        ),
      ],
    );
  }
}

/// A single lasso mode option button.
class _LassoModeOption extends StatelessWidget {
  const _LassoModeOption({
    required this.mode,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final LassoMode mode;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.blue : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.2,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            // Selection indicator dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.blue : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Toggle row for selectable element types.
class _SelectableTypeToggle extends StatelessWidget {
  const _SelectableTypeToggle({
    required this.label,
    required this.type,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final SelectableType type;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: Colors.blue.shade200,
            activeThumbColor: Colors.blue,
          ),
        ],
      ),
    );
  }
}
