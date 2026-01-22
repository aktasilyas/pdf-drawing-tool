class Entitlements {
  static const String cloudSync = 'cloud_sync';
  static const String unlimitedDocuments = 'unlimited_documents';
  static const String premiumTemplates = 'premium_templates';
  static const String aiFeatures = 'ai_features';
  static const String advancedExport = 'advanced_export';
  static const String noAds = 'no_ads';

  static const List<String> all = [
    cloudSync,
    unlimitedDocuments,
    premiumTemplates,
    aiFeatures,
    advancedExport,
    noAds,
  ];
}

class Entitlement {
  final String id;
  final bool isActive;
  final DateTime? expiresAt;

  const Entitlement({
    required this.id,
    required this.isActive,
    this.expiresAt,
  });
}
