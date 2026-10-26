// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonClose => 'Close';

  @override
  String get commonBack => 'Back';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionAppearance => 'APPEARANCE';

  @override
  String get settingsSectionAccount => 'ACCOUNT';

  @override
  String get settingsSectionPrivacy => 'PRIVACY';

  @override
  String get settingsSectionAbout => 'ABOUT';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeDialogTitle => 'Choose theme';

  @override
  String get settingsCanvasTheme => 'Canvas theme';

  @override
  String get settingsPinFavorites => 'Pin favorites to top';

  @override
  String get settingsChangePassword => 'Change password';

  @override
  String get settingsChangePasswordSoon =>
      'Changing the password is coming soon';

  @override
  String get settingsAccountInfo => 'Account info';

  @override
  String get settingsAccountInfoTitle => 'Account Info';

  @override
  String settingsAccountEmail(String email) {
    return 'Email: $email';
  }

  @override
  String settingsAccountId(String id) {
    return 'ID: $id';
  }

  @override
  String get settingsUserFallbackName => 'User';

  @override
  String get settingsEditName => 'Edit Name';

  @override
  String get settingsEditNameHint => 'Edit name';

  @override
  String get settingsNameLabel => 'Your name';

  @override
  String get settingsLogout => 'Log Out';

  @override
  String get settingsLogoutConfirm =>
      'Are you sure you want to log out of your account?';

  @override
  String get settingsCrashReports => 'Send crash reports';

  @override
  String get settingsCrashReportsSubtitle =>
      'Anonymous error reports; note content is never sent';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get settingsPrivacyPolicyLoadError =>
      'Could not open the privacy policy';

  @override
  String get settingsLicenses => 'Open source licenses';

  @override
  String get settingsFeedback => 'Send feedback';

  @override
  String get settingsCopy => 'Copy';

  @override
  String get settingsEmailCopied => 'Email address copied';
}
