import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/widgets/reorderable_tool_list.dart';

/// Panel for customizing toolbar appearance and tool order.
class ToolbarSettingsPanel extends ConsumerWidget {
  const ToolbarSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = (screenHeight * 0.75).clamp(420.0, 660.0);

    return Container(
      width: 300,
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context, ref, cs),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Flexible(child: _buildToolsSection(context, cs)),
          const SizedBox(height: 12),
          _buildExtraToolsSection(context, ref, cs),
          const SizedBox(height: 12),
          _buildResetButton(context, ref, cs),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    ColorScheme cs,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              StarNoteIcons.settings,
              size: 15,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Araç Çubuğu Ayarları',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: PhosphorIcon(
              StarNoteIcons.close,
              size: 16,
              color: cs.onSurfaceVariant,
            ),
            onPressed: () {
              ref.read(activePanelProvider.notifier).state = null;
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildToolsSection(BuildContext context, ColorScheme cs) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Araçlar',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                'Sırala',
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              PhosphorIcon(
                StarNoteIcons.dragHandle,
                size: 13,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Flexible(
          child: ReorderableToolList(),
        ),
      ],
    );
  }

  Widget _buildExtraToolsSection(
    BuildContext context,
    WidgetRef ref,
    ColorScheme cs,
  ) {
    final config = ref.watch(toolbarConfigProvider);
    final rulerVisible = config.extraToolVisible('ruler');
    final audioVisible = config.extraToolVisible('audio');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 10),
          Text(
            'Ek Araçlar',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          _ExtraToolTile(
            icon: StarNoteIcons.ruler,
            label: 'Cetvel',
            subtitle: 'Düz çizgi çizme aracı',
            isVisible: rulerVisible,
            onToggle: () => ref
                .read(toolbarConfigProvider.notifier)
                .toggleExtraTool('ruler'),
          ),
          const SizedBox(height: 4),
          _ExtraToolTile(
            icon: StarNoteIcons.microphone,
            label: 'Ses Kaydı',
            subtitle: 'Ses kaydetme özelliği',
            isVisible: audioVisible,
            onToggle: () => ref
                .read(toolbarConfigProvider.notifier)
                .toggleExtraTool('audio'),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton(
    BuildContext context,
    WidgetRef ref,
    ColorScheme cs,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 36,
        child: OutlinedButton.icon(
          onPressed: () => _showResetConfirmation(context, ref),
          icon: PhosphorIcon(StarNoteIcons.rotate, size: 14),
          label: const Text(
            'Varsayılana Sıfırla',
            style: TextStyle(fontSize: 12),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: cs.onSurfaceVariant,
            side: BorderSide(
              color: cs.outline.withValues(alpha: 0.3),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    // Close the popover first so the dialog is not hidden behind it.
    ref.read(activePanelProvider.notifier).state = null;

    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text(
          'Sıfırla',
          style: TextStyle(color: cs.onSurface),
        ),
        content: Text(
          'Araç çubuğu ayarları varsayılana döndürülecek. '
          'Devam etmek istiyor musunuz?',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              await ref
                  .read(toolbarConfigProvider.notifier)
                  .resetToDefault();
              if (dialogCtx.mounted) {
                Navigator.pop(dialogCtx);
              }
            },
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
  }
}

/// Fixed (non-reorderable) extra tool tile with toggle.
class _ExtraToolTile extends StatelessWidget {
  const _ExtraToolTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isVisible,
    required this.onToggle,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool isVisible;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconColor = isVisible
        ? cs.onSurface
        : cs.onSurfaceVariant.withValues(alpha: 0.5);
    final textColor = isVisible
        ? cs.onSurface
        : cs.onSurfaceVariant.withValues(alpha: 0.6);

    return Container(
      padding: const EdgeInsets.only(left: 10, top: 2, bottom: 2, right: 0),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          PhosphorIcon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor,
                    decoration: isVisible ? null : TextDecoration.lineThrough,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.7,
            child: Switch(
              value: isVisible,
              onChanged: (_) => onToggle(),
              activeThumbColor: cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}
