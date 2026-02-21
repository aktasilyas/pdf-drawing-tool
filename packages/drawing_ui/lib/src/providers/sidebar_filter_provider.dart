import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Filter options for the page sidebar.
enum SidebarFilter { allPages, bookmarked, recordings }

/// Current sidebar filter state.
final sidebarFilterProvider =
    StateProvider<SidebarFilter>((ref) => SidebarFilter.allPages);

/// Whether the sidebar is currently open.
final sidebarOpenProvider = StateProvider<bool>((ref) => false);
