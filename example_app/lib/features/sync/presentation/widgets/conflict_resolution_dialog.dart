/// Dialog for resolving sync conflicts.
///
/// Displays conflict information and allows user to choose
/// between keeping local version, remote version, or both.
library;

import 'package:flutter/material.dart';
import 'package:example_app/features/sync/domain/entities/sync_conflict.dart';

/// Dialog for resolving sync conflicts
class ConflictResolutionDialog extends StatelessWidget {
  /// The conflict to resolve
  final SyncConflict conflict;

  /// Callback when resolution is selected
  final Function(ConflictResolution) onResolve;

  /// Creates a conflict resolution dialog
  const ConflictResolutionDialog({
    super.key,
    required this.conflict,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Senkronizasyon Çakışması'),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Belge: ${conflict.documentTitle}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildVersionInfo(
              context,
              'Yerel Değişiklik',
              conflict.localModified,
              conflict.isLocalNewer,
            ),
            const SizedBox(height: 12),
            _buildVersionInfo(
              context,
              'Sunucu Değişikliği',
              conflict.remoteModified,
              conflict.isRemoteNewer,
            ),
            const SizedBox(height: 24),
            Text(
              'Hangi sürümü korumak istersiniz?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onResolve(ConflictResolution.keepLocal);
          },
          child: const Text('Yerel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onResolve(ConflictResolution.keepRemote);
          },
          child: const Text('Sunucu'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onResolve(ConflictResolution.keepBoth);
          },
          child: const Text('Her İkisi'),
        ),
      ],
    );
  }

  /// Builds version information widget
  Widget _buildVersionInfo(
    BuildContext context,
    String label,
    DateTime timestamp,
    bool isNewer,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isNewer
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isNewer
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isNewer
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
              ),
              if (isNewer)
                Chip(
                  label: const Text('Daha Yeni'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 12,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${timestamp.day.toString().padLeft(2, '0')}.${timestamp.month.toString().padLeft(2, '0')}.${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
