/// Storage keys for SharedPreferences and local storage.
library;

abstract class StorageKeys {
  // Auth
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';

  // Settings
  static const String themeMode = 'theme_mode';
  static const String locale = 'locale';
  static const String toolbarConfig = 'toolbar_config';
  static const String autoSaveEnabled = 'auto_save_enabled';
  static const String autoSyncEnabled = 'auto_sync_enabled';

  // Sync
  static const String lastSyncTime = 'last_sync_time';
  static const String syncQueueSize = 'sync_queue_size';

  // Premium
  static const String subscriptionTier = 'subscription_tier';
  static const String subscriptionExpiry = 'subscription_expiry';
  static const String cachedEntitlements = 'cached_entitlements';

  // Onboarding
  static const String onboardingCompleted = 'onboarding_completed';
  static const String firstLaunchDate = 'first_launch_date';

  // Recent
  static const String recentDocumentIds = 'recent_document_ids';
  static const String lastOpenedFolderId = 'last_opened_folder_id';

  // Documents - View Preferences
  static const String viewMode = 'view_mode';
  static const String sortOption = 'sort_option';
  static const String sortDirection = 'sort_direction';
  static const String pinFavoritesToTop = 'pin_favorites_to_top';
}
