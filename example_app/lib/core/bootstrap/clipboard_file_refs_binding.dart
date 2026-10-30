import 'package:drawing_ui/drawing_ui.dart' show clipboardFileRefsProvider;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/clipboard/clipboard_file_refs.dart';

/// Feeds the editor clipboards' file references into [refs] while it is in
/// the tree, so managed-file cleanup keeps files a paste may still need.
class ClipboardFileRefsBinding extends ConsumerStatefulWidget {
  const ClipboardFileRefsBinding({
    super.key,
    required this.refs,
    required this.child,
  });

  final ClipboardFileRefs refs;
  final Widget child;

  @override
  ConsumerState<ClipboardFileRefsBinding> createState() =>
      _ClipboardFileRefsBindingState();
}

class _ClipboardFileRefsBindingState
    extends ConsumerState<ClipboardFileRefsBinding> {
  @override
  void initState() {
    super.initState();
    widget.refs.paths = () => ref.read(clipboardFileRefsProvider);
  }

  @override
  void dispose() {
    widget.refs.paths = () => const {};
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
