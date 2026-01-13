import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/drawing_theme.dart';
import '../providers/drawing_providers.dart';
import 'pen_preset_slot.dart';

/// The left sidebar containing pen preset slots.
///
/// Displays up to 16 pen presets that users can quickly switch between.
/// Each slot shows a nib preview, color indicator, and thickness.
class PenBox extends ConsumerWidget {
  const PenBox({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = DrawingTheme.of(context);
    final presets = ref.watch(penBoxPresetsProvider);
    final selectedIndex = ref.watch(selectedPresetIndexProvider);

    return Container(
      width: theme.penBoxWidth,
      decoration: BoxDecoration(
        color: theme.penBoxBackground,
        border: Border(
          right: BorderSide(
            color: theme.panelBorderColor,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            // Scrollable preset list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: presets.length,
                itemBuilder: (context, index) {
                  final preset = presets[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: PenPresetSlot(
                      preset: preset,
                      isSelected: index == selectedIndex,
                      onTap: () => _onPresetTapped(ref, index, preset),
                      onLongPress: () => _onPresetLongPressed(context, ref, index),
                    ),
                  );
                },
              ),
            ),
            // Add preset button
            Padding(
              padding: const EdgeInsets.all(8),
              child: _AddPresetButton(
                onTap: () => _onAddPresetTapped(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPresetTapped(WidgetRef ref, int index, PenPreset preset) {
    if (preset.isEmpty) return;

    // Select the preset
    ref.read(selectedPresetIndexProvider.notifier).state = index;

    // Update current tool to match preset
    ref.read(currentToolProvider.notifier).state = preset.toolType;

    // Update tool settings to match preset
    ref.read(penSettingsProvider(preset.toolType).notifier)
      ..setColor(preset.color)
      ..setThickness(preset.thickness)
      ..setNibShape(preset.nibShape);

    // Close any open panel
    ref.read(activePanelProvider.notifier).state = null;
  }

  void _onPresetLongPressed(BuildContext context, WidgetRef ref, int index) {
    // Show preset edit options
    showModalBottomSheet(
      context: context,
      builder: (context) => _PresetOptionsSheet(index: index),
    );
  }

  void _onAddPresetTapped(BuildContext context, WidgetRef ref) {
    // Add current settings as a new preset
    final currentTool = ref.read(currentToolProvider);
    final settings = ref.read(penSettingsProvider(currentTool));

    final newPreset = PenPreset(
      id: 'preset_${DateTime.now().millisecondsSinceEpoch}',
      toolType: currentTool,
      color: settings.color,
      thickness: settings.thickness,
      nibShape: settings.nibShape,
    );

    ref.read(penBoxPresetsProvider.notifier).addPreset(newPreset);
  }
}

/// Button to add a new preset slot.
class _AddPresetButton extends StatelessWidget {
  const _AddPresetButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = DrawingTheme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: theme.penSlotSize,
        height: theme.penSlotSize,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.shade400,
            style: BorderStyle.solid,
          ),
        ),
        child: const Icon(
          Icons.add,
          color: Colors.grey,
          size: 20,
        ),
      ),
    );
  }
}

/// Bottom sheet for preset options (edit, delete).
class _PresetOptionsSheet extends ConsumerWidget {
  const _PresetOptionsSheet({required this.index});

  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presets = ref.watch(penBoxPresetsProvider);
    final preset = presets[index];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            preset.isEmpty ? 'Empty Slot' : 'Preset Options',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          if (!preset.isEmpty) ...[
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Preset'),
              onTap: () {
                Navigator.pop(context);
                // MOCK: Would open preset editor
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Preset', style: TextStyle(color: Colors.red)),
              onTap: () {
                ref.read(penBoxPresetsProvider.notifier).removePreset(index);
                Navigator.pop(context);
              },
            ),
          ],
          if (preset.isEmpty)
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add Current Settings'),
              onTap: () {
                final currentTool = ref.read(currentToolProvider);
                final settings = ref.read(penSettingsProvider(currentTool));
                ref.read(penBoxPresetsProvider.notifier).updatePreset(
                      index,
                      PenPreset(
                        id: preset.id,
                        toolType: currentTool,
                        color: settings.color,
                        thickness: settings.thickness,
                        nibShape: settings.nibShape,
                      ),
                    );
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
}
