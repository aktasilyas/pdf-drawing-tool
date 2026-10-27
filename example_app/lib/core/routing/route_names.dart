/// Route names for navigation.
library;

abstract class RouteNames {
  // Auth
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Main
  static const String documents = '/documents';

  // Editor
  static const String editor = '/editor/:documentId';
  static const String newDocument = '/new-document';
  static const String templateSelection = '/template-selection';

  // Settings
  static const String settings = '/settings';
  static const String profile = '/profile';

  // Premium
  static const String paywall = '/paywall';
  static const String subscription = '/subscription';

  // Helper methods for parameterized routes
  /// True for routes behind splash / auth, where a document may be opened.
  static bool isLibraryRoute(String path) =>
      path.startsWith(documents) || path.startsWith('/editor/');

  static String editorPath(String documentId) => '/editor/$documentId';
}
