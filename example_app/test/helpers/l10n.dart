import 'package:flutter/material.dart';

import 'package:example_app/l10n/l10n.dart';

/// Locale pinned in widget and golden tests so Turkish copy assertions hold
/// regardless of the machine running them.
const testLocale = Locale('tr');

/// A [MaterialApp] with the app's localization delegates and [locale].
Widget localizedApp({
  required Widget home,
  ThemeData? theme,
  Locale locale = testLocale,
  bool debugShowCheckedModeBanner = true,
  TransitionBuilder? builder,
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return MaterialApp(
    navigatorKey: navigatorKey,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: theme,
    debugShowCheckedModeBanner: debugShowCheckedModeBanner,
    builder: builder,
    home: home,
  );
}
