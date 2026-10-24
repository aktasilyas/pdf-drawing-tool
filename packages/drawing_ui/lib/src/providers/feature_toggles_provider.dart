import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether AI assistant entry points (toolbar button, selection 'ai' action)
/// are shown. The host app overrides this from its feature flags.
final aiAssistantEnabledProvider = Provider<bool>((_) => true);

/// Whether audio recording entry points (mic buttons, recording bar,
/// recordings sidebar filter) are shown. The host app overrides this from
/// its feature flags.
final audioRecordingEnabledProvider = Provider<bool>((_) => true);
