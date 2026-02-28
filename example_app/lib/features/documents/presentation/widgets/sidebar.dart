import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';

enum SidebarSection {
  documents,
  favorites,
  shared,
  store,
  trash,
  folder, // For when a specific folder is selected
}

class Sidebar extends ConsumerWidget {
  final SidebarSection selectedSection;
  final ValueChanged<SidebarSection> onSectionChanged;
  final String? selectedFolderId; // For folder selection
  final ValueChanged<String>? onFolderSelected; // Callback for folder tap
  final VoidCallback? onCreateFolder; // Callback for create folder button

  const Sidebar({
    super.key,
    required this.selectedSection,
    required this.onSectionChanged,
    this.selectedFolderId,
    this.onFolderSelected,
    this.onCreateFolder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersProvider);
    
    return Container(
      width: 240,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo / App name
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Text(
              'ElyaNotes',
              style: GoogleFonts.lobsterTwo(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),

          // All scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Navigation items
                  _SidebarItem(
                    icon: Icons.folder_outlined,
                    selectedIcon: Icons.folder,
                    label: 'Belgeler',
                    isSelected: selectedSection == SidebarSection.documents,
                    onTap: () => onSectionChanged(SidebarSection.documents),
                  ),
                  _SidebarItem(
                    icon: Icons.star_outline,
                    selectedIcon: Icons.star,
                    label: 'Sık Kullanılanlar',
                    isSelected: selectedSection == SidebarSection.favorites,
                    onTap: () => onSectionChanged(SidebarSection.favorites),
                  ),
                  
                  // Folders section header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          'Klasörler',
                          style: AppTypography.labelMedium.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                letterSpacing: 0.5,
                              ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          onPressed: onCreateFolder,
                          tooltip: 'Yeni Klasör',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          iconSize: 18,
                          style: IconButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Folders list
                  foldersAsync.when(
                    data: (folders) {
                      // Only show root folders (parentId == null) in sidebar
                      final rootFolders = folders.where((f) => f.parentId == null).toList();
                      
                      if (rootFolders.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.sm,
                          ),
                          child: Text(
                            'Klasör yok',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        );
                      }
                      
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: rootFolders.map((folder) {
                          final isSelected = selectedSection == SidebarSection.folder && 
                                           selectedFolderId == folder.id;
                          
                          return _SidebarItem(
                            icon: Icons.folder_outlined,
                            selectedIcon: Icons.folder,
                            label: folder.name,
                            isSelected: isSelected,
                            trailing: Text(
                              '${folder.documentCount}',
                              style: AppTypography.caption.copyWith(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.onPrimaryContainer
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            iconColor: Color(folder.colorValue),
                            onTap: () {
                              onFolderSelected?.call(folder.id);
                            },
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  
                  _SidebarItem(
                    icon: Icons.people_outline,
                    selectedIcon: Icons.people,
                    label: 'Paylaşılan',
                    isSelected: selectedSection == SidebarSection.shared,
                    onTap: () => onSectionChanged(SidebarSection.shared),
                  ),
                  _SidebarItem(
                    icon: Icons.storefront_outlined,
                    selectedIcon: Icons.storefront,
                    label: 'Mağaza',
                    isSelected: selectedSection == SidebarSection.store,
                    onTap: () => onSectionChanged(SidebarSection.store),
                  ),

                  const Divider(height: 1),

                  // Trash at bottom
                  _SidebarItem(
                    icon: Icons.delete_outline,
                    selectedIcon: Icons.delete,
                    label: 'Çöp',
                    isSelected: selectedSection == SidebarSection.trash,
                    onTap: () => onSectionChanged(SidebarSection.trash),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? iconColor;

  const _SidebarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.trailing,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
      ),
      child: Material(
        color: isSelected
            ? colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  size: 20,
                  color: iconColor ?? (isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
