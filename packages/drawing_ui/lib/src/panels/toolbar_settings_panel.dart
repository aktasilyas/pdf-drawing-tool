import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/widgets/reorderable_tool_list.dart';
import 'package:drawing_ui/src/models/toolbar_config.dart';

/// Panel for customizing toolbar appearance and tool order.
class ToolbarSettingsPanel extends ConsumerWidget {
  const ToolbarSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(toolbarConfigProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    // Responsive maxHeight - increased for better visibility
    final maxHeight = (screenHeight * 0.7).clamp(400.0, 600.0);

    return Container(
      width: 280,
      // Esnek yükseklik - ekran boyutuna göre ayarlanır
      constraints: BoxConstraints(
        maxHeight: maxHeight,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: (isDark ? 60 : 38) / 255.0),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(context, ref),
          
          Divider(height: 1, color: colorScheme.outlineVariant),
          
          const SizedBox(height: 8),
          
          // Quick Access Toggle
          _buildQuickAccessSection(context, ref, config),
          
          const SizedBox(height: 12),
          
          // Tools Section (scrollable)
          Flexible(
            child: _buildToolsSection(context),
          ),
          
          const SizedBox(height: 12),
          
          // Reset Button
          _buildResetButton(context, ref),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          PhosphorIcon(StarNoteIcons.settings, size: StarNoteIcons.panelSize, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Araç Çubuğu Ayarları',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: PhosphorIcon(StarNoteIcons.close, size: StarNoteIcons.panelSize, color: colorScheme.onSurfaceVariant),
            onPressed: () {
              ref.read(activePanelProvider.notifier).state = null;
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessSection(
    BuildContext context,
    WidgetRef ref,
    ToolbarConfig config,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Hızlı Erişim Çubuğu',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: config.showQuickAccess,
                  onChanged: (_) async {
                    await ref.read(toolbarConfigProvider.notifier).toggleQuickAccess();
                  },
                  activeThumbColor: colorScheme.primary,
                ),
              ),
            ],
          ),
          Text(
            'Sık kullanılan renk ve kalınlıkları göster',
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Text(
                'Araçlar',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                'Sürükle',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Flexible(
          child: ReorderableToolList(),
        ),
      ],
    );
  }

  Widget _buildResetButton(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        width: double.infinity,
        height: 32,
        child: OutlinedButton.icon(
          onPressed: () => _showResetConfirmation(context, ref),
          icon: PhosphorIcon(StarNoteIcons.rotate, size: 14),
          label: const Text(
            'Varsayılana Sıfırla',
            style: TextStyle(fontSize: 11),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.onSurfaceVariant,
            side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text('Sıfırla', style: TextStyle(color: colorScheme.onSurface)),
        content: Text(
          'Araç çubuğu ayarları varsayılana döndürülecek. Devam etmek istiyor musunuz?',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(toolbarConfigProvider.notifier).resetToDefault();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
  }
}
