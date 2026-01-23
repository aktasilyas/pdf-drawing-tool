import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/features/documents/presentation/constants/documents_strings.dart';

enum SidebarSection {
  allDocuments,
  favorites,
  recent,
  trash,
}

class Sidebar extends ConsumerWidget {
  final SidebarSection selectedSection;
  final Function(SidebarSection) onSectionTap;
  final String? selectedFolderId;
  final Function(String?) onFolderTap;
  final VoidCallback onNewFolderPressed;

  const Sidebar({
    super.key,
    required this.selectedSection,
    required this.onSectionTap,
    this.selectedFolderId,
    required this.onFolderTap,
    required this.onNewFolderPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Navigation sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _SidebarItem(
                  icon: Icons.description_outlined,
                  title: DocumentsStrings.myDocuments,
                  isSelected: selectedSection == SidebarSection.allDocuments,
                  onTap: () => onSectionTap(SidebarSection.allDocuments),
                ),
                
                _SidebarItem(
                  icon: Icons.favorite_border,
                  title: DocumentsStrings.favorites,
                  isSelected: selectedSection == SidebarSection.favorites,
                  onTap: () => onSectionTap(SidebarSection.favorites),
                ),
                
                _SidebarItem(
                  icon: Icons.access_time,
                  title: DocumentsStrings.recent,
                  isSelected: selectedSection == SidebarSection.recent,
                  onTap: () => onSectionTap(SidebarSection.recent),
                ),
                
                _SidebarItem(
                  icon: Icons.delete_outline,
                  title: DocumentsStrings.trash,
                  isSelected: selectedSection == SidebarSection.trash,
                  onTap: () => onSectionTap(SidebarSection.trash),
                ),
                
                const Divider(height: 24),
                
                // Folders section header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        DocumentsStrings.folders,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      
                      const Spacer(),
                      
                      InkWell(
                        onTap: onNewFolderPressed,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.add,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // TODO: Folder tree will be displayed here
                // This will be implemented with FolderTree widget
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Klasörler yakında eklenecek',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final int? count;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                
                if (count != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count.toString(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
