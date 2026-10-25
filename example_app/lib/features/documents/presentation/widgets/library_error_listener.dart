import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/presentation/providers/library_error.dart';

/// Shows an error snackbar for every failed library mutation reported through
/// [reportLibraryFailure] (trash, rename, favourite, folder create, ...).
///
/// Mounted once above the router so failures surface on whatever screen is
/// visible, including the editor and Manage Folders.
class LibraryErrorListener extends ConsumerWidget {
  const LibraryErrorListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<LibraryError?>(libraryErrorProvider, (previous, next) {
      if (next == null) return;
      AppToast.error(context, next.message);
    });
    return child;
  }
}
