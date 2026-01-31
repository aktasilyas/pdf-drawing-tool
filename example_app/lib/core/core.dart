/// Core module - shared infrastructure for the app.
/// 
/// This module contains:
/// - Error handling (Failures, Exceptions)
/// - Database setup (Drift)
/// - Dependency injection (GetIt + Injectable)
/// - Routing (GoRouter)
/// - Theme
/// - Utils and extensions
library;

// Errors
export 'errors/failures.dart';
export 'errors/exceptions.dart';

// Constants
export 'constants/app_constants.dart';
export 'constants/storage_keys.dart';

// Utils
export 'utils/extensions.dart';
export 'utils/validators.dart';
export 'utils/logger.dart';

// Theme
export 'theme/app_theme.dart';
export 'theme/app_colors.dart';

// Routing
export 'routing/app_router.dart';
export 'routing/route_names.dart';

// Network
export 'network/network_info.dart';

// DI - export only the locator, not config
export 'di/injection.dart' show getIt, configureDependencies;

// Database - export only public interfaces
// export 'database/app_database.dart';
