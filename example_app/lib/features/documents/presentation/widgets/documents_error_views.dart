import 'package:flutter/material.dart';
import 'package:example_app/core/theme/index.dart';

/// Error state view for documents feature.
class DocumentsErrorView extends StatelessWidget {
  const DocumentsErrorView({super.key, required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Hata: $error'),
        ],
      ),
    );
  }
}

/// Empty folder view for documents feature.
class DocumentsEmptyFolderView extends StatelessWidget {
  const DocumentsEmptyFolderView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Bu klasör boş',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
