import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/core/core.dart';

/// A failed library mutation (trash, rename, folder create, ...) waiting to
/// be shown to the user by `LibraryErrorListener`.
///
/// Not `const` and not value-equal on purpose: two identical failures in a
/// row are two events and must both notify listeners.
class LibraryError {
  LibraryError(this.failure, this.fallbackMessage);

  final Failure failure;

  /// Turkish, action-specific text used when the failure message is technical.
  final String fallbackMessage;

  /// Text shown to the user: validation messages verbatim (they are written
  /// for users), the action-specific fallback for storage/unknown failures
  /// (their messages are English diagnostics, logged instead).
  String get message =>
      failure is ValidationFailure ? failure.message : fallbackMessage;
}

/// Latest failed library mutation; `null` until the first failure.
final libraryErrorProvider = StateProvider<LibraryError?>((ref) => null);

/// Logs [failure] and publishes it for the library error snackbar.
void reportLibraryFailure(Ref ref, Failure failure, String fallbackMessage) {
  logger.w('$fallbackMessage: ${failure.message}');
  ref.read(libraryErrorProvider.notifier).state =
      LibraryError(failure, fallbackMessage);
}
