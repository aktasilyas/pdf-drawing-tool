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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:example_app/features/documents/documents.dart';
import 'package:example_app/features/documents/data/datasources/folder_local_datasource.dart';
import 'package:example_app/features/documents/data/repositories/folder_repository_impl.dart';
import 'package:example_app/features/documents/domain/repositories/folder_repository.dart';
import 'package:example_app/features/editor/editor.dart';

/// Global service locator instance
final getIt = GetIt.instance;

/// Configure all dependencies
/// 
/// Call this in main() before runApp()
Future<void> configureDependencies() async {
  // Core services
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  
  // Manual registrations
  _registerRepositories();
  _registerUseCases();
}

// ignore: unused_element
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
  // Datasources
  getIt.registerLazySingleton<DocumentLocalDatasource>(
    () => DocumentLocalDatasourceImpl(getIt()),
  );
  
  getIt.registerLazySingleton<FolderLocalDatasource>(
    () => FolderLocalDatasourceImpl(getIt()),
  );
  
  // Documents
  getIt.registerLazySingleton<DocumentRepository>(
    () => DocumentRepositoryImpl(
      getIt<DocumentLocalDatasource>(),
      getIt<FolderLocalDatasource>(),
    ),
  );
  
  // Folders
  getIt.registerLazySingleton<FolderRepository>(
    () => FolderRepositoryImpl(
      getIt<FolderLocalDatasource>(),
      getIt<DocumentLocalDatasource>(),
    ),
  );
}

void _registerUseCases() {
  // Editor use cases
  getIt.registerFactory(() => LoadDocumentUseCase(getIt()));
  getIt.registerFactory(() => SaveDocumentUseCase(getIt()));
}

/// Reset all registrations (useful for testing)
Future<void> resetDependencies() async {
  await getIt.reset();
}
