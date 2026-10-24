// RevenueCat configuration constants.
import 'package:example_app/core/config/app_env.dart';

/// RevenueCat entitlement IDs and API key helpers.
abstract class RevenueCatConstants {
  /// Entitlement IDs matching RevenueCat Dashboard configuration.
  static const entitlementPremium = 'premium';
  static const entitlementPro = 'pro';

  /// Returns the platform-appropriate RevenueCat public API key.
  static String get apiKey => const AppEnv().revenueCatApiKey;
}
