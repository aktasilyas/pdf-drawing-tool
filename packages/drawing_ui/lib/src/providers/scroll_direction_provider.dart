import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls the page scroll/transition direction.
///
/// [Axis.horizontal] = left/right page transitions (default).
/// [Axis.vertical] = up/down page transitions.
final scrollDirectionProvider = StateProvider<Axis>((ref) => Axis.horizontal);
