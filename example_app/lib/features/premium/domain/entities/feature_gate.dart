/// Definitions for gated (premium-restricted) features in the app.
library;

/// Enumeration of features that can be restricted by subscription tier.
enum GatedFeature {
  createNotebook,
  importPdf,
  audioRecording,
  aiChat,
  exportWithoutWatermark,
  cloudSync,
  advancedPdfAnnotation,
  aiTranscription,
}

/// Represents the current access status for a gated feature.
class FeatureAccess {
  final bool isAllowed;
  final int? currentUsage;
  final int? maxUsage;
  final String? upgradeMessage;

  const FeatureAccess({
    required this.isAllowed,
    this.currentUsage,
    this.maxUsage,
    this.upgradeMessage,
  });

  /// Usage ratio as a percentage (for progress bars).
  double get usageRatio {
    if (currentUsage == null || maxUsage == null || maxUsage == 0) return 0;
    return (currentUsage! / maxUsage!).clamp(0.0, 1.0);
  }

  /// Whether the user is near the limit (>= 80%).
  bool get isNearLimit => usageRatio >= 0.8;

  /// Factory for an allowed feature with no limits.
  factory FeatureAccess.allowed() => const FeatureAccess(isAllowed: true);

  /// Factory for a blocked feature.
  factory FeatureAccess.blocked({
    int? currentUsage,
    int? maxUsage,
    String? message,
  }) =>
      FeatureAccess(
        isAllowed: false,
        currentUsage: currentUsage,
        maxUsage: maxUsage,
        upgradeMessage: message,
      );
}
