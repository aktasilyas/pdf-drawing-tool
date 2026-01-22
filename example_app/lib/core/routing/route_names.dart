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
  static const String folder = '/folder/:folderId';
  static const String favorites = '/favorites';
  static const String recent = '/recent';
  static const String trash = '/trash';

  // Editor
  static const String editor = '/editor/:documentId';
  static const String newDocument = '/new-document';

  // Settings
  static const String settings = '/settings';
  static const String profile = '/profile';

  // Premium
  static const String paywall = '/paywall';
  static const String subscription = '/subscription';

  // Helper methods for parameterized routes
  static String folderPath(String folderId) => '/folder/$folderId';
  static String editorPath(String documentId) => '/editor/$documentId';
}
