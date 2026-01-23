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
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.5,
            ),
          ),

          const Spacer(),

          // New button
          FilledButton(
            key: newButtonKey,
            onPressed: onNewPressed,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.add, size: 18),
                SizedBox(width: 6),
                Text('Yeni'),
                SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Sort dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE0E0E0)),
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
                  ? const Color(0xFF1976D2)
                  : const Color(0xFF666666),
            ),
            tooltip: 'Seçim modu',
          ),
        ],
      ),
    );
  }
}
