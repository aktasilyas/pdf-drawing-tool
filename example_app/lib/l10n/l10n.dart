import 'package:flutter/widgets.dart';

import 'package:example_app/l10n/app_localizations.dart';

export 'package:example_app/l10n/app_localizations.dart';

/// `context.l10n.settingsTitle` shorthand for [AppLocalizations.of].
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
