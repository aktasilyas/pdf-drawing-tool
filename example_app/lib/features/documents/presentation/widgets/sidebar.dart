import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SidebarSection {
  documents,
  favorites,
  shared,
  store,
  trash,
}

class Sidebar extends ConsumerWidget {
  final SidebarSection selectedSection;
  final ValueChanged<SidebarSection> onSectionChanged;

  const Sidebar({
    super.key,
    required this.selectedSection,
    required this.onSectionChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              'StarNote',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ),

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

          const Spacer(),

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
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected 
            ? colorScheme.primaryContainer 
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
                  isSelected ? selectedIcon : icon,
                  size: 20,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
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
