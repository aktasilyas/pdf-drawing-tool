import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds captured PNG bytes from a selection screenshot.
///
/// Set by the selection toolbar's AI action before opening the sidebar.
/// Read by the AI chat to attach the image when sending a message.
final pendingSelectionImageProvider = StateProvider<Uint8List?>((ref) => null);
