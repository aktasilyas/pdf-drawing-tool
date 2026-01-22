/// Widget displaying current sync status with icon and label.
///
/// Shows different icons and colors based on sync state:
/// - Online + synced: green cloud check
/// - Syncing: animated spinner
/// - Offline: gray cloud off
/// - Error: red sync problem
/// - Pending: orange cloud upload
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/sync_status.dart';
import '../providers/sync_provider.dart';

/// Displays current sync status indicator
class SyncStatusIndicator extends ConsumerWidget {
  /// Whether to show status label
  final bool showLabel;

  /// Icon size
  final double iconSize;

  /// Creates a sync status indicator
  const SyncStatusIndicator({
    super.key,
    this.showLabel = true,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusStreamProvider);
    final isOnline = ref.watch(connectivityStreamProvider).value ?? true;

    return syncStatus.when(
      data: (status) => _buildIndicator(context, status, isOnline),
      loading: () => _buildLoading(),
      error: (_, __) => _buildError(),
    );
  }

  /// Builds loading indicator
  Widget _buildLoading() {
    return SizedBox(
      width: iconSize,
      height: iconSize,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          Colors.grey.shade400,
        ),
      ),
    );
  }

  /// Builds error indicator
  Widget _buildError() {
    return Icon(
      Icons.error_outline,
      size: iconSize,
      color: Colors.red,
    );
  }

  /// Builds status indicator based on sync state
  Widget _buildIndicator(
    BuildContext context,
    SyncStatus status,
    bool isOnline,
  ) {
    final IconData icon;
    final Color color;
    final String label;

    if (!isOnline) {
      icon = Icons.cloud_off;
      color = Colors.grey;
      label = 'Çevrimdışı';
    } else if (status.isSyncing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: 8),
            Text(
              'Senkronize ediliyor...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
            ),
          ],
        ],
      );
    } else if (status.hasError) {
      icon = Icons.sync_problem;
      color = Colors.red;
      label = 'Hata';
    } else if (status.hasPendingChanges) {
      icon = Icons.cloud_upload;
      color = Colors.orange;
      label = '${status.pendingChanges} bekliyor';
    } else {
      icon = Icons.cloud_done;
      color = Colors.green;
      label = 'Güncel';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: color),
        if (showLabel) ...[
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                ),
          ),
        ],
      ],
    );
  }
}
