import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/i18n/app_strings.dart';

class LocaleProvider with ChangeNotifier {
  AppLanguage _language = AppLanguage.system;

  AppLanguage get language => _language;

  Locale get currentLocale {
    switch (_language) {
      case AppLanguage.zh:
        return const Locale('zh', 'CN');
      case AppLanguage.en:
        return const Locale('en', 'US');
      case AppLanguage.system:
        final sysLang = PlatformDispatcher.instance.locale.languageCode.toLowerCase();
        if (sysLang == 'zh') {
          return const Locale('zh', 'CN');
        } else {
          // 非中文系统，默认 fallback 到英文
          return const Locale('en', 'US');
        }
    }
  }

  bool get isZh => currentLocale.languageCode.toLowerCase() == 'zh';

  Future<void> initLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('app_language');
    if (saved == 'zh') {
      _language = AppLanguage.zh;
    } else if (saved == 'en') {
      _language = AppLanguage.en;
    } else {
      _language = AppLanguage.system;
    }
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    if (lang == AppLanguage.zh) {
      await prefs.setString('app_language', 'zh');
    } else if (lang == AppLanguage.en) {
      await prefs.setString('app_language', 'en');
    } else {
      await prefs.setString('app_language', 'system');
    }
    notifyListeners();
  }
}
