import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/pen_box/pen_preset_slot.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Show preset edit options
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: theme.penSlotSize,
        height: theme.penSlotSize,
        decoration: BoxDecoration(
          color: isDark 
              ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.5) 
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.4),
            style: BorderStyle.solid,
          ),
        ),
        child: Icon(
          Icons.add,
          color: colorScheme.onSurfaceVariant,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Text(
            preset.isEmpty ? 'Boş Slot' : 'Kalem Seçenekleri',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          if (!preset.isEmpty) ...[
            _buildOptionTile(
              context: context,
              icon: Icons.edit_outlined,
              label: 'Düzenle',
              color: colorScheme.primary,
              onTap: () {
                Navigator.pop(context);
                // MOCK: Would open preset editor
              },
            ),
            const SizedBox(height: 4),
            _buildOptionTile(
              context: context,
              icon: Icons.delete_outline,
              label: 'Sil',
              color: colorScheme.error,
              onTap: () {
                ref.read(penBoxPresetsProvider.notifier).removePreset(index);
                Navigator.pop(context);
              },
            ),
          ],
          if (preset.isEmpty)
            _buildOptionTile(
              context: context,
              icon: Icons.add_circle_outline,
              label: 'Mevcut Ayarları Ekle',
              color: colorScheme.primary,
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
  
  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
