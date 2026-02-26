/// Domain entity for AI usage tracking and quota management.
class AIUsage {
  final int dailyMessagesUsed;
  final int dailyMessagesLimit;
  final int monthlyTokensUsed;
  final int monthlyTokensLimit;

  const AIUsage({
    required this.dailyMessagesUsed,
    required this.dailyMessagesLimit,
    required this.monthlyTokensUsed,
    required this.monthlyTokensLimit,
  });

  double get dailyUsagePercent =>
      dailyMessagesLimit > 0 ? dailyMessagesUsed / dailyMessagesLimit : 0;

  bool get isOverDailyLimit => dailyMessagesUsed >= dailyMessagesLimit;
  bool get isOverMonthlyLimit => monthlyTokensUsed >= monthlyTokensLimit;
  int get remainingDaily =>
      (dailyMessagesLimit - dailyMessagesUsed).clamp(0, dailyMessagesLimit);

  /// Free tier defaults.
  static const AIUsage freeDefault = AIUsage(
    dailyMessagesUsed: 0,
    dailyMessagesLimit: 15,
    monthlyTokensUsed: 0,
    monthlyTokensLimit: 50000,
  );
}
