/// Settings tile for sync configuration.
///
/// Displays sync settings including:
/// - Auto sync toggle
/// - Last sync timestamp
/// - Manual sync button
/// - Pending changes count
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sync_provider.dart';

/// Settings tile for sync configuration
class SyncSettingsTile extends ConsumerWidget {
  /// Creates a sync settings tile
  const SyncSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusStreamProvider).value;
    final autoSyncEnabled = ref.watch(autoSyncEnabledProvider).value ?? true;
    final syncController = ref.read(syncControllerProvider.notifier);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.sync, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Senkronizasyon',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Auto Sync Toggle
          SwitchListTile(
            title: const Text('Otomatik Senkronizasyon'),
            subtitle: const Text(
              'Değişiklikler otomatik olarak senkronize edilir',
            ),
            value: autoSyncEnabled,
            onChanged: (value) {
              syncController.toggleAutoSync(value);
              ref.invalidate(autoSyncEnabledProvider);
            },
          ),

          // Last Sync Time
          if (syncStatus?.lastSyncedAt != null)
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Son Senkronizasyon'),
              subtitle: Text(
                _formatDateTime(syncStatus!.lastSyncedAt!),
              ),
            ),

          // Pending Changes
          if (syncStatus?.hasPendingChanges ?? false)
            ListTile(
              leading: const Icon(Icons.pending_actions),
              title: const Text('Bekleyen Değişiklikler'),
              subtitle: Text(
                '${syncStatus!.pendingChanges} öğe senkronize edilmeyi bekliyor',
              ),
            ),

          // Manual Sync Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: syncStatus?.isSyncing ?? false
                    ? null
                    : () {
                        syncController.syncAll();
                        ref.invalidate(syncStatusStreamProvider);
                      },
                icon: syncStatus?.isSyncing ?? false
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: Text(
                  syncStatus?.isSyncing ?? false
                      ? 'Senkronize Ediliyor...'
                      : 'Şimdi Senkronize Et',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Formats DateTime for display
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Az önce';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      // Format as dd.MM.yyyy HH:mm
      return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
