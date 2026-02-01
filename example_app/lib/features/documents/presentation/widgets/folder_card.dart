import 'package:flutter/material.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';

class FolderCard extends StatelessWidget {
  final Folder folder;
  final VoidCallback onTap;
  final VoidCallback? onMorePressed;
  final bool isSelected;
  final bool isSelectionMode;

  const FolderCard({
    super.key,
    required this.folder,
    required this.onTap,
    this.onMorePressed,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Folder Icon and More button
                  Row(
                    children: [
                      Icon(
                        Icons.folder,
                        size: 48,
                        color: Color(folder.colorValue),
                      ),
                      const Spacer(),
                      if (!isSelectionMode && onMorePressed != null)
                        IconButton(
                          icon: const Icon(Icons.more_vert, size: 20),
                          onPressed: onMorePressed,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Daha fazla',
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Folder name
                  Text(
                    folder.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Document count
                  Text(
                    '${folder.documentCount} belge',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
          
          // Selection indicator
          if (isSelectionMode)
            Positioned(
              top: 8,
              right: 8,
              child: IgnorePointer(
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: Theme.of(context).colorScheme.onPrimary,
                        )
                      : null,
                ),
              ),
            ),
          
          // Selection overlay
          if (isSelected)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
