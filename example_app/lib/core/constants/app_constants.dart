/// Application-wide constants.
library;

abstract class AppConstants {
  // App Info
  static const String appName = 'ElyaNotes';
  static const String appVersion = '1.0.0';
  
  // Limits - Free Tier
  static const int freeMaxDocuments = 5;
  static const int freeMaxFolders = 3;
  static const int freeMaxPagesPerDocument = 10;
  
  // Limits - Premium
  static const int premiumMaxDocuments = -1; // Unlimited
  static const int premiumMaxFolders = -1;
  static const int premiumMaxPagesPerDocument = -1;
  
  // Cache
  static const int maxRecentDocuments = 10;
  static const int maxThumbnailCache = 50;
  static const int thumbnailWidth = 150;
  static const int thumbnailHeight = 200;
  
  // Sync
  static const Duration syncDebounce = Duration(seconds: 5);
  static const Duration syncTimeout = Duration(seconds: 30);
  static const int maxSyncRetries = 3;
  
  // UI
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 3);
  
  // Pagination
  static const int pageSize = 20;
}

/// RevenueCat product IDs
abstract class ProductIds {
  static const String premiumMonthly = 'starnote_premium_monthly';
  static const String premiumYearly = 'starnote_premium_yearly';
  static const String premiumLifetime = 'starnote_premium_lifetime';
}

/// RevenueCat entitlement IDs
abstract class EntitlementIds {
  static const String premium = 'premium';
  static const String cloudSync = 'cloud_sync';
  static const String unlimitedDocuments = 'unlimited_documents';
  static const String premiumTemplates = 'premium_templates';
  static const String aiFeatures = 'ai_features';
  static const String advancedExport = 'advanced_export';
}
