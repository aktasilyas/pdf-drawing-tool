import 'package:flutter/material.dart';

enum SortOption { date, name, size }

class DocumentsHeader extends StatelessWidget {
  final String title;
  final VoidCallback onNewPressed;
  final SortOption sortOption;
  final ValueChanged<SortOption> onSortChanged;
  final bool isSelectionMode;
  final VoidCallback? onSelectionToggle;
  final GlobalKey? newButtonKey;

  const DocumentsHeader({
    super.key,
    required this.title,
    required this.onNewPressed,
    required this.sortOption,
    required this.onSortChanged,
    this.isSelectionMode = false,
    this.onSelectionToggle,
    this.newButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 32,
        isMobile ? 16 : 24,
        isMobile ? 16 : 32,
        16,
      ),
      child: Row(
        children: [
          // Title - Flexible to prevent overflow
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 24 : 32,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),

          const Spacer(),

          // New button - Compact on mobile
          FilledButton(
            key: newButtonKey,
            onPressed: onNewPressed,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 8 : 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: isMobile
                ? const Icon(Icons.add, size: 20)
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 18),
                      SizedBox(width: 6),
                      Text('Yeni'),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, size: 20),
                    ],
                  ),
          ),

          if (!isMobile) const SizedBox(width: 12),

          // Sort dropdown - Hidden on mobile, use icon button instead
          if (isMobile)
            PopupMenuButton<SortOption>(
              initialValue: sortOption,
              icon: const Icon(Icons.sort, size: 20),
              tooltip: 'Sıralama',
              onSelected: onSortChanged,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: SortOption.date,
                  child: Text('Tarih'),
                ),
                PopupMenuItem(
                  value: SortOption.name,
                  child: Text('İsim'),
                ),
                PopupMenuItem(
                  value: SortOption.size,
                  child: Text('Boyut'),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<SortOption>(
                  value: sortOption,
                  isDense: true,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                  items: const [
                    DropdownMenuItem(
                      value: SortOption.date,
                      child: Text('Tarih'),
                    ),
                    DropdownMenuItem(
                      value: SortOption.name,
                      child: Text('İsim'),
                    ),
                    DropdownMenuItem(
                      value: SortOption.size,
                      child: Text('Boyut'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) onSortChanged(value);
                  },
                ),
              ),
            ),

          if (!isMobile) const SizedBox(width: 12),

          // Selection mode toggle - Hidden on mobile (can be added to menu if needed)
          if (!isMobile)
            IconButton(
              onPressed: onSelectionToggle,
              icon: Icon(
                isSelectionMode ? Icons.check_circle : Icons.check_circle_outline,
                color: isSelectionMode
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              tooltip: 'Seçim modu',
            ),
        ],
      ),
    );
  }
}
