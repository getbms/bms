import 'package:bms/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

export 'app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
