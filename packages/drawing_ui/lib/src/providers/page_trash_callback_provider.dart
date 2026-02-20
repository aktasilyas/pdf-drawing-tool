import 'package:drawing_core/drawing_core.dart' show Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Callback type for soft-deleting a page.
/// Called with the page index and the Page object.
/// The host app implements this to store the page in its trash system.
typedef PageTrashCallback = Future<void> Function(int pageIndex, Page page);

/// Provider that the host app sets to enable page soft-delete.
/// When null, page deletion falls back to hard-delete (backward compat).
final pageTrashCallbackProvider = StateProvider<PageTrashCallback?>((_) => null);
