import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Width of the AI chat sidebar.
const kAISidebarWidth = 320.0;

/// Whether the AI sidebar is currently open.
final aiSidebarOpenProvider = StateProvider<bool>((ref) => false);
