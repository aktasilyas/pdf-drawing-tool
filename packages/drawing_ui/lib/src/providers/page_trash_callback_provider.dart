import 'package:drawing_core/drawing_core.dart' show Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Callback type for soft-deleting a page.
/// Called with the page index and the Page object.
/// The host app implements this to store the page in its trash system.
/// Returns the id of the created trash entry, or null when it could not be
/// stored.
typedef PageTrashCallback = Future<String?> Function(int pageIndex, Page page);

/// Callback type for removing a trash entry again (e.g. when a page delete is
/// undone). Called with the id returned by [PageTrashCallback].
typedef PageTrashDiscardCallback = Future<void> Function(String trashId);

/// Provider that the host app sets to enable page soft-delete.
/// When null, page deletion falls back to hard-delete (backward compat).
final pageTrashCallbackProvider =
    StateProvider<PageTrashCallback?>((_) => null);

/// Provider that the host app sets so an undone page delete can drop its trash
/// entry. When null, nothing is discarded.
final pageTrashDiscardCallbackProvider =
    StateProvider<PageTrashDiscardCallback?>((_) => null);
