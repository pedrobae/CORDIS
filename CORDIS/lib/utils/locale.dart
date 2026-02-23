import 'package:cordis/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class LocaleUtils {
  LocaleUtils._();
  static String getLanguageName(Locale locale, BuildContext context) {
    switch (locale.languageCode) {
      case 'en':
        return AppLocalizations.of(context)!.english;
      case 'pt':
        return AppLocalizations.of(context)!.portuguese;
      default:
        return locale.languageCode;
    }
  }

  static Locale getLocaleFromLanguageName(
    String languageName,
    BuildContext context,
  ) {
    if (languageName == AppLocalizations.of(context)!.english) {
      return const Locale('en');
    }

    if (languageName == AppLocalizations.of(context)!.portuguese) {
      return const Locale('pt');
    }

    return const Locale('en'); // Default to English if unknown
  }
}
