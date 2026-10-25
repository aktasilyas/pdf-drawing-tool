import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

/// Loads font files from `assets/fonts/` into the test engine.
Future<void> loadTestFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    final bytes = File('assets/fonts/$f').readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

/// Loads the bundled SourceSerif4 and Inter families.
Future<void> loadAppTestFonts() async {
  await loadTestFont('SourceSerif4', [
    'SourceSerif4-Regular.otf',
    'SourceSerif4-Semibold.otf',
    'SourceSerif4-Bold.otf',
  ]);
  await loadTestFont('Inter', [
    'Inter-Regular.ttf',
    'Inter-Medium.ttf',
    'Inter-SemiBold.ttf',
  ]);
}

/// Loads every font family declared in the app's `FontManifest.json`
/// (Phosphor and Material icon glyphs, ComicRelief, package fonts) so that
/// golden tests render real glyphs instead of boxes.
///
/// Families in [skip] are left alone because [loadAppTestFonts] already loads
/// them from disk.
Future<void> loadManifestFonts({
  Set<String> skip = const {'SourceSerif4', 'Inter'},
}) async {
  final raw = await rootBundle.loadString('FontManifest.json');
  final families = json.decode(raw) as List<dynamic>;
  for (final entry in families) {
    final family = (entry as Map<String, dynamic>)['family'] as String;
    if (skip.contains(family)) continue;
    final loader = FontLoader(family);
    for (final font in entry['fonts'] as List<dynamic>) {
      final asset = (font as Map<String, dynamic>)['asset'] as String;
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }
}
