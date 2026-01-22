/// Dependency Injection setup using GetIt + Injectable.
/// 
/// Usage:
/// ```dart
/// // In main.dart
/// await configureDependencies();
/// 
/// // Get instance
/// final repo = getIt<AuthRepository>();
/// ```
library;

import 'package:get_it/get_it.dart';
// import 'package:injectable/injectable.dart';
// import 'injection.config.dart';

/// Global service locator instance
final getIt = GetIt.instance;

/// Configure all dependencies
/// 
/// Call this in main() before runApp()
Future<void> configureDependencies() async {
  // TODO: Uncomment when injectable is set up
  // await getIt.init();
  
  // Manual registrations (until injectable generates config)
  _registerCoreServices();
  _registerRepositories();
  _registerUseCases();
}

void _registerCoreServices() {
  // Network info
  // getIt.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  
  // Database
  // getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());
  
  // Supabase client
  // getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  
  // SharedPreferences - already registered in provider
}

void _registerRepositories() {
  // Auth
  // getIt.registerLazySingleton<AuthRepository>(
  //   () => AuthRepositoryImpl(getIt(), getIt()),
  // );
  
  // Documents
  // getIt.registerLazySingleton<DocumentRepository>(
  //   () => DocumentRepositoryImpl(getIt()),
  // );
  
  // Folders
  // getIt.registerLazySingleton<FolderRepository>(
  //   () => FolderRepositoryImpl(getIt()),
  // );
  
  // Sync
  // getIt.registerLazySingleton<SyncRepository>(
  //   () => SyncRepositoryImpl(getIt(), getIt(), getIt()),
  // );
  
  // Premium
  // getIt.registerLazySingleton<SubscriptionRepository>(
  //   () => SubscriptionRepositoryImpl(),
  // );
}

void _registerUseCases() {
  // Auth use cases
  // getIt.registerFactory(() => LoginUseCase(getIt()));
  // getIt.registerFactory(() => RegisterUseCase(getIt()));
  // getIt.registerFactory(() => LogoutUseCase(getIt()));
  
  // Document use cases
  // getIt.registerFactory(() => GetDocumentsUseCase(getIt()));
  // getIt.registerFactory(() => CreateDocumentUseCase(getIt(), getIt()));
  // getIt.registerFactory(() => DeleteDocumentUseCase(getIt()));
  
  // Premium use cases
  // getIt.registerFactory(() => CheckSubscriptionUseCase(getIt()));
  // getIt.registerFactory(() => PurchaseUseCase(getIt()));
}

/// Reset all registrations (useful for testing)
Future<void> resetDependencies() async {
  await getIt.reset();
}
