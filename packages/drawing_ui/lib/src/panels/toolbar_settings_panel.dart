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

    return Container(
      width: 320,
      constraints: const BoxConstraints(maxHeight: 500),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(context, ref),
          
          const Divider(height: 1),
          
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Access Toggle
                  _buildQuickAccessSection(context, ref, config),
                  
                  const SizedBox(height: 16),
                  
                  // Tools Section
                  _buildToolsSection(context),
                  
                  const SizedBox(height: 16),
                  
                  // Reset Button
                  _buildResetButton(context, ref),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.settings, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Araç Çubuğu Ayarları',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Switch(
                value: config.showQuickAccess,
                onChanged: (_) async {
                  await ref.read(toolbarConfigProvider.notifier).toggleQuickAccess();
                },
                activeColor: Colors.blue,
              ),
            ],
          ),
          Text(
            'Sık kullanılan renk ve kalınlıkları göster',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                'Araçlar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  'Sıralamak için sürükle',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const ReorderableToolList(),
      ],
    );
  }

  Widget _buildResetButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showResetConfirmation(context, ref),
          icon: const Icon(Icons.restore, size: 18),
          label: const Text('Varsayılana Sıfırla'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey.shade700,
            side: BorderSide(color: Colors.grey.shade300),
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
