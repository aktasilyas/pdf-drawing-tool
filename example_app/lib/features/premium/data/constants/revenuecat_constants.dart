// RevenueCat configuration constants.
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// RevenueCat entitlement IDs and API key helpers.
abstract class RevenueCatConstants {
  /// Entitlement IDs matching RevenueCat Dashboard configuration.
  static const entitlementPremium = 'premium';
  static const entitlementPro = 'pro';

  /// Returns the platform-appropriate RevenueCat public API key.
  static String get apiKey {
    if (Platform.isIOS || Platform.isMacOS) {
      return dotenv.env['REVENUECAT_APPLE_KEY'] ?? '';
    }
    return dotenv.env['REVENUECAT_GOOGLE_KEY'] ?? '';
  }
}
