import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:example_app/core/config/app_env.dart';
import 'package:example_app/features/ai/data/datasources/ai_local_datasource.dart';
import 'package:example_app/features/ai/data/datasources/ai_remote_datasource.dart';
import 'package:example_app/features/ai/data/repositories/ai_repository_impl.dart';
import 'package:example_app/features/ai/data/services/canvas_capture_service.dart';
import 'package:example_app/features/ai/domain/repositories/ai_repository.dart';
import 'package:example_app/features/premium/domain/entities/subscription.dart';
import 'package:example_app/features/premium/presentation/providers/feature_gate_provider.dart';
import 'package:example_app/features/sync/presentation/providers/sync_provider.dart';

export 'ai_chat_provider.dart';
export 'ai_conversations_provider.dart';
export 'ai_sidebar_provider.dart';
export 'ai_usage_provider.dart';

// ─── Service Providers ──────────────────────────────────

final canvasCaptureServiceProvider = Provider<CanvasCaptureService>((ref) {
  return CanvasCaptureService();
});

final aiRemoteDataSourceProvider = Provider<AIRemoteDataSource>((ref) {
  final supabase = Supabase.instance.client;
  const env = AppEnv();
  return AIRemoteDataSource(
    supabase,
    supabaseUrl: env.supabaseUrl,
    supabaseKey: env.supabaseAnonKey,
  );
});

final aiLocalDataSourceProvider = Provider<AILocalDataSource>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return AILocalDataSource(db);
});

// ─── Repository ─────────────────────────────────────────

final aiRepositoryProvider = Provider<AIRepository>((ref) {
  final remote = ref.watch(aiRemoteDataSourceProvider);
  final local = ref.watch(aiLocalDataSourceProvider);
  final tier = ref.watch(aiTierProvider);
  return AIRepositoryImpl(
    remoteDataSource: remote,
    localDataSource: local,
    userTier: tier,
  );
});

// ─── Subscription-Aware Providers ───────────────────────

/// Active user's AI tier (derived from subscription).
final aiTierProvider = Provider<SubscriptionTier>((ref) {
  // Follows the flag-aware tier: premiumPlus (no RevenueCat) when premium off.
  return ref.watch(currentTierProvider);
});

/// Active model name for UI badge display.
final aiModelNameProvider = Provider<String>((ref) {
  final tier = ref.watch(aiTierProvider);
  return switch (tier) {
    SubscriptionTier.free => 'GPT-4o mini',
    SubscriptionTier.premium => 'GPT-4o mini',
    SubscriptionTier.premiumPlus => 'GPT-4o',
  };
});

/// Daily message limit based on tier.
final aiDailyLimitProvider = Provider<int>((ref) {
  final tier = ref.watch(aiTierProvider);
  return switch (tier) {
    SubscriptionTier.free => 15,
    SubscriptionTier.premium => 150,
    SubscriptionTier.premiumPlus => 1000,
  };
});
