import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reader mode state -- when active, toolbar is hidden and drawing is disabled.
/// Resets to false on each app launch (not persisted).
final readerModeProvider = StateProvider<bool>((ref) => false);
