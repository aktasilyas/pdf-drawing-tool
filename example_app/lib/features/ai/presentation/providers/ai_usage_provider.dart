import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/features/ai/domain/entities/ai_entities.dart';
import 'package:example_app/features/ai/presentation/providers/ai_providers.dart';

/// Provider for AI usage statistics (daily message count, quota).
final aiUsageProvider = FutureProvider.autoDispose<AIUsage>((ref) async {
  final repository = ref.watch(aiRepositoryProvider);
  return repository.getUsage();
});

/// Quick check: can the user send another AI message?
final canSendAIMessageProvider = Provider.autoDispose<bool>((ref) {
  final usage = ref.watch(aiUsageProvider);
  return usage.when(
    data: (data) => !data.isOverDailyLimit,
    loading: () => true, // Optimistic — allow while loading
    error: (_, __) => false,
  );
});

/// Remaining daily messages (for UI display).
final remainingAIMessagesProvider = Provider.autoDispose<int>((ref) {
  final usage = ref.watch(aiUsageProvider);
  return usage.when(
    data: (data) => data.remainingDaily,
    loading: () => -1,
    error: (_, __) => 0,
  );
});
