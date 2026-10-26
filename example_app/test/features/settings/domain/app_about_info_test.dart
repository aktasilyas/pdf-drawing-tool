import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/features/settings/domain/entities/app_about_info.dart';

void main() {
  group('formatVersion', () {
    test('name and number', () {
      expect(AppAboutInfo.formatVersion('1.0.0', '7'), '1.0.0 (7)');
    });

    test('name only', () {
      expect(AppAboutInfo.formatVersion('1.0.0', null), '1.0.0');
      expect(AppAboutInfo.formatVersion('1.0.0', ''), '1.0.0');
    });

    test('no name means no version', () {
      expect(AppAboutInfo.formatVersion(null, '7'), isNull);
      expect(AppAboutInfo.formatVersion('', null), isNull);
    });
  });

  test('bundled privacy policy matches the Turkish section of the docs copy',
      () {
    final bundled = File(AppAboutInfo.privacyPolicyAsset).readAsStringSync();
    final docs = File('../docs/store/privacy-policy.md').readAsStringSync();

    // The app bar carries the title, so the asset starts at the date.
    expect(bundled, startsWith('**Yürürlük tarihi:**'));
    final body = bundled.trim();
    final turkish = docs.substring(docs.indexOf('## Türkçe')).trim();
    expect(turkish, endsWith(body));
    expect(body, contains(AppAboutInfo.contactEmail));
  });
}
