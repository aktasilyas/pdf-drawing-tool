import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compile-time feature flags, set with `--dart-define=FF_...=true`.
///
/// All flags default to off so a plain release build ships the v1.0 scope only.
class FeatureFlags {
  const FeatureFlags({
    this.aiChat = false,
    this.cloudSync = false,
    this.premium = false,
    this.audioRecording = false,
  });

  static const allOff = FeatureFlags();
  static const allOn = FeatureFlags(
    aiChat: true,
    cloudSync: true,
    premium: true,
    audioRecording: true,
  );

  /// Reads the flags from `--dart-define` values.
  factory FeatureFlags.fromEnvironment() => const FeatureFlags(
        aiChat: bool.fromEnvironment('FF_AI_CHAT'),
        cloudSync: bool.fromEnvironment('FF_CLOUD_SYNC'),
        premium: bool.fromEnvironment('FF_PREMIUM'),
        audioRecording: bool.fromEnvironment('FF_AUDIO_RECORDING'),
      );

  final bool aiChat;
  final bool cloudSync;
  final bool premium;
  final bool audioRecording;

  /// Supabase is only initialized when a flag that depends on it is on.
  bool get needsSupabase => aiChat || cloudSync;

  @override
  bool operator ==(Object other) =>
      other is FeatureFlags &&
      aiChat == other.aiChat &&
      cloudSync == other.cloudSync &&
      premium == other.premium &&
      audioRecording == other.audioRecording;

  @override
  int get hashCode => Object.hash(aiChat, cloudSync, premium, audioRecording);

  @override
  String toString() => 'FeatureFlags(aiChat: $aiChat, cloudSync: $cloudSync, '
      'premium: $premium, audioRecording: $audioRecording)';
}

/// Current feature flags. Tests override this provider.
final featureFlagsProvider =
    Provider<FeatureFlags>((ref) => FeatureFlags.fromEnvironment());
