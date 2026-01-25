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
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
      child: Row(
        children: [
          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),

          const Spacer(),

          // New button
          FilledButton(
            key: newButtonKey,
            onPressed: onNewPressed,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Row(
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

          const SizedBox(width: 12),

          // Sort dropdown
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

          const SizedBox(width: 12),

          // Selection mode toggle
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
