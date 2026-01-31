import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/features/documents/domain/entities/sort_option.dart';
import 'package:example_app/features/documents/domain/entities/view_mode.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';

class DocumentsHeader extends ConsumerStatefulWidget {
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
  ConsumerState<DocumentsHeader> createState() => _DocumentsHeaderState();
}

class _DocumentsHeaderState extends ConsumerState<DocumentsHeader> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final sortDirection = ref.watch(sortDirectionProvider);
    final viewMode = ref.watch(viewModeProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    
    // Update controller only if text differs (avoid cursor reset)
    if (_searchController.text != searchQuery) {
      _searchController.text = searchQuery;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchController.text.length),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 32,
        isMobile ? 16 : 24,
        isMobile ? 16 : 24, // Settings butonu ile tam hizalı (16+8 IconButton padding)
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First row: Title + Buttons
          Row(
            children: [
              // Title - Stays on the left
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: isMobile ? 24 : 32,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),

              const Spacer(),

              // Buttons container - aligned to the right with equal spacing
              if (!isMobile)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // New button
                    FilledButton(
                      key: widget.newButtonKey,
                      onPressed: widget.onNewPressed,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

                    const SizedBox(width: 4),

                    // Sort dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<SortOption>(
                          value: widget.sortOption,
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
                            if (value != null) widget.onSortChanged(value);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 4),

                    // View mode toggle (Grid/List)
                    IconButton(
                      onPressed: () {
                        final newMode = viewMode == ViewMode.grid
                            ? ViewMode.list
                            : ViewMode.grid;
                        ref.read(viewModeProvider.notifier).set(newMode);
                      },
                      icon: Icon(
                        viewMode == ViewMode.grid
                            ? Icons.view_list
                            : Icons.grid_view,
                        size: 20,
                      ),
                      tooltip: viewMode == ViewMode.grid
                          ? 'Liste görünümü'
                          : 'Grid görünümü',
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),

                    const SizedBox(width: 4),

                    // Sort direction toggle
                    IconButton(
                      onPressed: () {
                        final newDirection = sortDirection == SortDirection.descending
                            ? SortDirection.ascending
                            : SortDirection.descending;
                        ref.read(sortDirectionProvider.notifier).set(newDirection);
                      },
                      icon: Icon(
                        sortDirection == SortDirection.descending
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        size: 18,
                      ),
                      tooltip: sortDirection.getDescription(widget.sortOption),
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),

                    const SizedBox(width: 4),

                    // Selection mode toggle - Last button, no trailing space
                    IconButton(
                      onPressed: widget.onSelectionToggle,
                      icon: Icon(
                        widget.isSelectionMode ? Icons.check_circle : Icons.check_circle_outline,
                        color: widget.isSelectionMode
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      tooltip: 'Seçim modu',
                    ),
                  ],
                )
              else
                // Mobile buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // New button - Compact on mobile
                    FilledButton(
                      key: widget.newButtonKey,
                      onPressed: widget.onNewPressed,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Icon(Icons.add, size: 20),
                    ),

                    const SizedBox(width: 8),

                    // Sort dropdown - Icon button on mobile
                    PopupMenuButton<SortOption>(
                      initialValue: widget.sortOption,
                      icon: const Icon(Icons.sort, size: 20),
                      tooltip: 'Sıralama',
                      onSelected: widget.onSortChanged,
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
                    ),
                  ],
                ),
            ],
          ),

          // Second row: Search bar
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (value) {
              ref.read(searchQueryProvider.notifier).state = value;
            },
            decoration: InputDecoration(
              hintText: 'Belgelerde ara...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                      },
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}
