import 'package:drawing_ui/drawing_ui.dart'
    show EditorMemoryPressureObserver, clearLibraryPreviewsProvider;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Releases the library's PDF tile previews when the platform reports low
/// memory (Android `onTrimMemory`). Mounted tiles render theirs again.
class LibraryMemoryPressureScope extends ConsumerStatefulWidget {
  const LibraryMemoryPressureScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LibraryMemoryPressureScope> createState() =>
      _LibraryMemoryPressureScopeState();
}

class _LibraryMemoryPressureScopeState
    extends ConsumerState<LibraryMemoryPressureScope> {
  late final EditorMemoryPressureObserver _observer;

  @override
  void initState() {
    super.initState();
    _observer = EditorMemoryPressureObserver(
      () => ref.read(clearLibraryPreviewsProvider)(),
    );
  }

  @override
  void dispose() {
    _observer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
