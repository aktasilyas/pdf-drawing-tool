/// Domain entity representing a user's subscription status.
library;

enum SubscriptionTier { free, premium, premiumPlus }

/// Domain entity representing a user's subscription status.
class Subscription {
  final SubscriptionTier tier;
  final DateTime? expiresAt;
  final bool isActive;
  final String? productId;
  final bool willRenew;

  const Subscription({
    required this.tier,
    this.expiresAt,
    required this.isActive,
    this.productId,
    this.willRenew = false,
  });

  bool get isFree => tier == SubscriptionTier.free;
  bool get isPremium => tier != SubscriptionTier.free && isActive;
  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());

  static const Subscription freeUser = Subscription(
    tier: SubscriptionTier.free,
    isActive: false,
  );
}
