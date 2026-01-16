import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  late Map<String, String> _localizedStrings;

  AppLocalizations(this.locale);

  // تحميل ملف JSON المناسب للغة
  Future<bool> load() async {
    final String jsonString =
    await rootBundle.loadString('lib/l10n/app_${locale.languageCode}.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings =
        jsonMap.map((key, value) => MapEntry(key, value.toString()));

    return true;
  }

  // استدعاء النصوص
  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // Helper للـ of(context) - تعديل هذه الدالة لتجنب Null check error
  static AppLocalizations of(BuildContext context) {
    final AppLocalizations? localizations =
    Localizations.of<AppLocalizations>(context, AppLocalizations);

    // بدلاً من استخدام ! يمكننا التحقق أولاً
    assert(localizations != null, 'AppLocalizations not found in context');
    return localizations!;
  }

  // Delegates
  static const LocalizationsDelegate<AppLocalizations> delegate =
  _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}