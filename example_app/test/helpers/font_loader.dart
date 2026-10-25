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
