import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/widgets/reorderable_tool_list.dart';
import 'package:drawing_ui/src/models/toolbar_config.dart';

/// Panel for customizing toolbar appearance and tool order.
class ToolbarSettingsPanel extends ConsumerWidget {
  const ToolbarSettingsPanel({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(toolbarConfigProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    // Responsive maxHeight - smaller on smaller screens
    final maxHeight = (screenHeight * 0.5).clamp(280.0, 400.0);

    return Container(
      width: 280,
      // Esnek yükseklik - ekran boyutuna göre ayarlanır
      constraints: BoxConstraints(
        maxHeight: maxHeight,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(38), // 0.15 * 255 ≈ 38
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
          
          const Divider(height: 1),
          
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.settings, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Araç Çubuğu Ayarları',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () {
              if (onClose != null) {
                onClose!();
              } else {
                ref.read(activePanelProvider.notifier).state = null;
              }
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Hızlı Erişim Çubuğu',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
                  activeColor: Colors.blue,
                ),
              ),
            ],
          ),
          Text(
            'Sık kullanılan renk ve kalınlıkları göster',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsSection(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Text(
                'Araçlar',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                'Sürükle',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        width: double.infinity,
        height: 32,
        child: OutlinedButton.icon(
          onPressed: () => _showResetConfirmation(context, ref),
          icon: const Icon(Icons.restore, size: 14),
          label: const Text(
            'Varsayılana Sıfırla',
            style: TextStyle(fontSize: 11),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey.shade700,
            side: BorderSide(color: Colors.grey.shade300),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sıfırla'),
        content: const Text(
          'Araç çubuğu ayarları varsayılana döndürülecek. Devam etmek istiyor musunuz?',
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
