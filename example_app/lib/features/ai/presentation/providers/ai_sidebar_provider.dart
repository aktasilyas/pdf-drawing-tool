import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Width of the AI chat sidebar.
const kAISidebarWidth = 320.0;

/// Default dimensions for the floating AI chat window.
const kAIFloatingDefaultWidth = 320.0;
const kAIFloatingDefaultHeight = 450.0;
const kAIFloatingMinWidth = 280.0;
const kAIFloatingMinHeight = 300.0;

/// View mode for the AI chat panel.
enum AIChatViewMode { sidebar, floating }

/// Whether the AI sidebar is currently open.
final aiSidebarOpenProvider = StateProvider<bool>((ref) => false);

/// Current view mode for the AI chat (sidebar or floating).
final aiChatViewModeProvider =
    StateProvider<AIChatViewMode>((ref) => AIChatViewMode.sidebar);
