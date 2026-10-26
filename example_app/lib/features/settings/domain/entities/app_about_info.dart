/// Static facts shown in Settings → Hakkında.
abstract final class AppAboutInfo {
  /// Public name used on the licence page.
  static const String appName = 'Elyanotes';

  /// Support address; the same one the privacy policy names
  /// (`docs/store/privacy-policy.md`).
  static const String contactEmail = 'elyanotes2108@gmail.com';

  /// Bundled Turkish privacy policy (kept in sync with the docs copy).
  static const String privacyPolicyAsset = 'assets/legal/privacy_policy_tr.md';

  /// Formats the build name/number that `flutter build` passes as
  /// `FLUTTER_BUILD_NAME` / `FLUTTER_BUILD_NUMBER` (see `appBuildName`).
  /// Returns `null` when the build carries no version (e.g. tests).
  static String? formatVersion(String? name, String? number) {
    if (name == null || name.isEmpty) return null;
    if (number == null || number.isEmpty) return name;
    return '$name ($number)';
  }
}
