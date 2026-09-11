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

    // Test new interaction strings for todo overhaul
    expect(zhStrings.swipeToComplete.isNotEmpty, true);
    expect(zhStrings.swipeToDelete.isNotEmpty, true);
    expect(zhStrings.undo, '撤销');
    expect(zhStrings.bufferPoolTitle.isNotEmpty, true);
    expect(zhStrings.categoryAll, '全部');

    expect(enStrings.swipeToComplete.isNotEmpty, true);
    expect(enStrings.swipeToDelete.isNotEmpty, true);
    expect(enStrings.undo, 'Undo');
    expect(enStrings.bufferPoolTitle.isNotEmpty, true);
    expect(enStrings.categoryAll, 'All');
  });

  test('Five accent themes build correctly in AppTheme', () {
    expect(AppTheme.accentThemes.length, 5);
    for (final opt in AppTheme.accentThemes) {
      final theme = AppTheme.buildLightTheme(opt.color);
      expect(theme.primaryColor, opt.color);
      expect(opt.descZh.isNotEmpty, true);
      expect(opt.descEn.isNotEmpty, true);
    }
  });
}
