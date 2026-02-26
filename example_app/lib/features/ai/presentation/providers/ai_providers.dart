import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:example_app/features/ai/data/datasources/ai_local_datasource.dart';
import 'package:example_app/features/ai/data/datasources/ai_remote_datasource.dart';
import 'package:example_app/features/ai/data/repositories/ai_repository_impl.dart';
import 'package:example_app/features/ai/data/services/canvas_capture_service.dart';
import 'package:example_app/features/ai/domain/repositories/ai_repository.dart';
import 'package:example_app/features/premium/domain/entities/subscription.dart';
import 'package:example_app/features/sync/presentation/providers/sync_provider.dart';

export 'ai_chat_provider.dart';
export 'ai_conversations_provider.dart';
export 'ai_usage_provider.dart';

// ─── Service Providers ──────────────────────────────────

final canvasCaptureServiceProvider = Provider<CanvasCaptureService>((ref) {
  return CanvasCaptureService();
});

final aiRemoteDataSourceProvider = Provider<AIRemoteDataSource>((ref) {
  final supabase = Supabase.instance.client;
  return AIRemoteDataSource(
    supabase,
    supabaseUrl: dotenv.env['SUPABASE_URL'] ?? '',
    supabaseKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );
});

final aiLocalDataSourceProvider = Provider<AILocalDataSource>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return AILocalDataSource(db);
});

final aiRepositoryProvider = Provider<AIRepository>((ref) {
  final remote = ref.watch(aiRemoteDataSourceProvider);
  final local = ref.watch(aiLocalDataSourceProvider);
  // TODO: Gerçek subscription tier'ı subscription provider'dan al
  // Şimdilik free tier — Step 6'da premium entegrasyonu yapılacak
  const tier = SubscriptionTier.free;
  return AIRepositoryImpl(
    remoteDataSource: remote,
    localDataSource: local,
    userTier: tier,
  );
});
