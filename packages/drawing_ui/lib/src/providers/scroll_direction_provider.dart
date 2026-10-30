import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/providers/toolbar_config_provider.dart';

/// SharedPreferences key of the page scroll direction (`Axis.name`).
const _scrollDirectionKey = 'elyanotes_scroll_direction';

/// Controls the page scroll/transition direction.
///
/// [Axis.horizontal] = left/right page transitions (default).
/// [Axis.vertical] = up/down page transitions.
///
/// App-wide and persisted when prefs are available; a missing or unknown
/// stored value loads [Axis.horizontal].
final scrollDirectionProvider = StateProvider<Axis>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  if (prefs == null) return Axis.horizontal;
  ref.listenSelf((_, next) => prefs.setString(_scrollDirectionKey, next.name));
  final stored = prefs.getString(_scrollDirectionKey);
  return Axis.values.asNameMap()[stored] ?? Axis.horizontal;
});
