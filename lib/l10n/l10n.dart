import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

abstract final class L10n {
  static const Locale fallbackLocale = Locale('en');
}
