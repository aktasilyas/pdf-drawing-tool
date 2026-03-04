import 'package:example_app/features/premium/domain/entities/feature_gate.dart';
import 'package:example_app/features/premium/domain/entities/subscription.dart';

/// Central feature gating service.
/// All premium restrictions are managed through this service.
class FeatureGateService {
  final SubscriptionTier _tier;

  FeatureGateService(this._tier);

  /// Free tier limits.
  static const _freeLimits = {
    GatedFeature.createNotebook: 3,
    GatedFeature.importPdf: 3,
    GatedFeature.audioRecording: 5, // minutes
    GatedFeature.aiChat: 15, // messages/day
  };

  /// Premium tier limits.
  static const _premiumLimits = {
    GatedFeature.createNotebook: 999, // practically unlimited
    GatedFeature.importPdf: 999,
    GatedFeature.audioRecording: 999,
    GatedFeature.aiChat: 150,
  };

  /// PremiumPlus (Pro) tier limits.
  static const _proLimits = {
    GatedFeature.createNotebook: 999,
    GatedFeature.importPdf: 999,
    GatedFeature.audioRecording: 999,
    GatedFeature.aiChat: 1000,
  };

  /// Check access for a given feature.
  FeatureAccess checkAccess(
    GatedFeature feature, {
    int currentUsage = 0,
  }) {
    // PremiumPlus (Pro) users — only AI chat has a high limit.
    if (_tier == SubscriptionTier.premiumPlus) {
      final limit = _proLimits[feature];
      if (limit == null) return FeatureAccess.allowed();
      if (currentUsage >= limit) {
        return FeatureAccess.blocked(
          currentUsage: currentUsage,
          maxUsage: limit,
          message: _upgradeMessage(feature),
        );
      }
      return FeatureAccess(
        isAllowed: true,
        currentUsage: currentUsage,
        maxUsage: limit,
      );
    }

    // Premium users — only AI chat has a meaningful limit.
    if (_tier == SubscriptionTier.premium) {
      final limit = _premiumLimits[feature];
      if (limit == null) return FeatureAccess.allowed();
      if (currentUsage >= limit) {
        return FeatureAccess.blocked(
          currentUsage: currentUsage,
          maxUsage: limit,
          message: _upgradeMessage(feature),
        );
      }
      return FeatureAccess(
        isAllowed: true,
        currentUsage: currentUsage,
        maxUsage: limit,
      );
    }

    // Free users
    final limit = _freeLimits[feature];

    // Features that are always blocked for free users (no numeric limit).
    if (limit == null) {
      const alwaysBlocked = [
        GatedFeature.exportWithoutWatermark,
        GatedFeature.cloudSync,
        GatedFeature.advancedPdfAnnotation,
        GatedFeature.aiTranscription,
      ];
      if (alwaysBlocked.contains(feature)) {
        return FeatureAccess.blocked(message: _upgradeMessage(feature));
      }
      return FeatureAccess.allowed();
    }

    // Numeric-limited features.
    if (currentUsage >= limit) {
      return FeatureAccess.blocked(
        currentUsage: currentUsage,
        maxUsage: limit,
        message: _upgradeMessage(feature),
      );
    }

    return FeatureAccess(
      isAllowed: true,
      currentUsage: currentUsage,
      maxUsage: limit,
    );
  }

  /// Turkish upgrade message for a given feature.
  String _upgradeMessage(GatedFeature feature) {
    return switch (feature) {
      GatedFeature.createNotebook =>
        "Ücretsiz planda en fazla 3 defter oluşturabilirsiniz. "
            "Premium'a geçerek sınırsız defter oluşturun.",
      GatedFeature.importPdf =>
        'Ücretsiz planda en fazla 3 PDF içe aktarabilirsiniz. '
            'Premium ile sınırsız PDF kullanın.',
      GatedFeature.audioRecording =>
        'Ücretsiz planda ses kaydı 5 dakika ile sınırlıdır. '
            'Premium ile sınırsız kayıt yapın.',
      GatedFeature.aiChat =>
        "Günlük AI mesaj limitinize ulaştınız. "
            "Premium'a geçerek daha fazla soru sorun.",
      GatedFeature.exportWithoutWatermark =>
        'Filigransız dışa aktarım Premium özelliğidir.',
      GatedFeature.cloudSync =>
        'Bulut senkronizasyonu Premium özelliğidir. '
            'Notlarınız tüm cihazlarınızda olsun.',
      GatedFeature.advancedPdfAnnotation =>
        'Gelişmiş PDF araçları Premium özelliğidir.',
      GatedFeature.aiTranscription =>
        'Ses kaydını metne dönüştürme Premium özelliğidir.',
    };
  }

  /// Current subscription tier.
  SubscriptionTier get currentTier => _tier;

  /// Whether the user has any premium subscription.
  bool get isPremium =>
      _tier == SubscriptionTier.premium ||
      _tier == SubscriptionTier.premiumPlus;
}
