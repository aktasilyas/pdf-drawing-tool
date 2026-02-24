import 'package:drawing_core/drawing_core.dart' show Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cross-page clipboard for copy/paste. Null means nothing copied.
final copiedPageProvider = StateProvider<Page?>((ref) => null);
