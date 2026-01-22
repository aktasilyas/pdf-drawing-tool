import 'package:flutter/material.dart';
import '../constants/documents_strings.dart';
import '../../domain/entities/document_info.dart';

class DocumentContextMenu extends StatelessWidget {
  final DocumentInfo document;
  final bool isInTrash;
  final VoidCallback? onRename;
  final VoidCallback? onMove;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onMoveToTrash;
  final VoidCallback? onRestore;
  final VoidCallback? onDeletePermanently;

  const DocumentContextMenu({
    super.key,
    required this.document,
    this.isInTrash = false,
    this.onRename,
    this.onMove,
    this.onToggleFavorite,
    this.onMoveToTrash,
    this.onRestore,
    this.onDeletePermanently,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Document title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    document.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          if (isInTrash) ...[
            // Trash actions
            _MenuItem(
              icon: Icons.restore,
              title: DocumentsStrings.restore,
              onTap: onRestore,
            ),
            
            _MenuItem(
              icon: Icons.delete_forever,
              title: DocumentsStrings.deleteForever,
              isDestructive: true,
              onTap: onDeletePermanently,
            ),
          ] else ...[
            // Normal actions
            _MenuItem(
              icon: Icons.edit_outlined,
              title: DocumentsStrings.rename,
              onTap: onRename,
            ),
            
            _MenuItem(
              icon: Icons.drive_file_move_outlined,
              title: DocumentsStrings.move,
              onTap: onMove,
            ),
            
            _MenuItem(
              icon: document.isFavorite
                  ? Icons.favorite
                  : Icons.favorite_border,
              title: document.isFavorite
                  ? DocumentsStrings.removeFromFavorites
                  : DocumentsStrings.addToFavorites,
              onTap: onToggleFavorite,
            ),
            
            const Divider(height: 1),
            
            _MenuItem(
              icon: Icons.delete_outline,
              title: DocumentsStrings.moveToTrash,
              isDestructive: true,
              onTap: onMoveToTrash,
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDestructive;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.isDestructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : null;
    
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color),
      ),
      onTap: onTap,
    );
  }
}
