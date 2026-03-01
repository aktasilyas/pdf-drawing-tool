/// Barrel exports for the auth feature.
library;

// Data
export 'data/datasources/auth_remote_datasource.dart';
export 'data/models/user_model.dart';
export 'data/repositories/auth_repository_impl.dart';

// Presentation
export 'presentation/constants/auth_strings.dart';
export 'presentation/providers/auth_provider.dart';
export 'presentation/screens/login_screen.dart';
export 'presentation/screens/register_screen.dart';
export 'presentation/screens/splash_screen.dart';
// Domain
export 'domain/entities/user.dart';
export 'domain/repositories/auth_repository.dart';
export 'domain/usecases/get_current_user_usecase.dart';
export 'domain/usecases/login_usecase.dart';
export 'domain/usecases/logout_usecase.dart';
export 'domain/usecases/register_usecase.dart';
