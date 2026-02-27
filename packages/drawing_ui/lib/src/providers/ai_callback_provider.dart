import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that the host app sets to override AI panel behavior.
///
/// When set, selection toolbar AI actions use this callback instead of
/// the built-in mock AI panel. The host app sets this to open its own
/// AI sidebar/chat.
final onAIPressedCallbackProvider = StateProvider<VoidCallback?>((_) => null);
