import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomodo/core/theme/app_theme.dart';
import 'package:pomodo/core/i18n/app_strings.dart';

void main() {
  test('AppTheme light and dark theme instantiation', () {
    final light = AppTheme.lightTheme;
    final dark = AppTheme.darkTheme;
    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
  });

  test('AppStrings localization strings', () {
    final zhStrings = AppStrings(const Locale('zh', 'CN'));
    expect(zhStrings.tabToday, '今日');
    expect(zhStrings.tabFocus, '专注');

    final enStrings = AppStrings(const Locale('en', 'US'));
    expect(enStrings.tabToday, 'Today');
    expect(enStrings.tabFocus, 'Focus');
  });
}
