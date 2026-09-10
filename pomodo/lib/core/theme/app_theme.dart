import 'package:flutter/material.dart';

/// PomoDo 官方设计系统：正统官方马尔斯绿与 Things 3 纯白通透空气感
class AppTheme {
  // 核心主题色：正统马尔斯绿 (#008779)
  static const Color primary = Color(0xFF008779);
  static const Color primaryDark = Color(0xFF006D62);
  static const Color primaryDarker = Color(0xFF004D40);
  static const Color primaryLight = Color(0xFFE0F2F1);
  static const Color primarySubtle = Color(0xFFE8F5F4);
  static const Color marsGreen = primary;

  // 界面基底：纯白透亮与微灰底衬
  static const Color bgPage = Color(0xFFF4F6F9);
  static const Color bgSurface = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE9ECEF);
  static const Color borderSubtle = Color(0xFFF1F3F5);
  static const Color background = bgPage;

  // 文字排版色彩
  static const Color textMain = Color(0xFF2C3E50);
  static const Color textRegular = Color(0xFF4A5568);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textTertiary = Color(0xFFA0AEC0);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = textMain;
  static const Color textMuted = textTertiary;

  // 艾利时间管理法（Ivy Lee）顺位色
  static const Color ivyRed = Color(0xFFE74C3C);    // 顺位 1 / P1
  static const Color ivyOrange = Color(0xFFE67E22); // 顺位 2 / P2
  static const Color ivyCyan = Color(0xFF16A085);   // 顺位 3 / P3
  static const Color ivyBlue = Color(0xFF2980B9);   // 顺位 4
  static const Color priorityP1 = ivyRed;
  static const Color priorityP2 = ivyOrange;
  static const Color priorityP3 = ivyCyan;
  static const Color priorityP4 = textSecondary;
  static const Color success = Color(0xFF27AE60);

  static Color priorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'P1':
        return priorityP1;
      case 'P2':
        return priorityP2;
      case 'P3':
        return priorityP3;
      case 'P4':
      default:
        return priorityP4;
    }
  }

  // 暗黑黑曜风格 (#0F171A, #182328, #273840)
  static const Color darkBgPage = Color(0xFF0F171A);
  static const Color darkBgSurface = Color(0xFF182328);
  static const Color darkBorder = Color(0xFF273840);
  static const Color darkTextMain = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgPage,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        surface: bgSurface,
      ),
      fontFamily: null, // 系统自适应字体 (Roboto / PingFang / HarmonyOS)
      appBarTheme: const AppBarTheme(
        backgroundColor: bgSurface,
        foregroundColor: textMain,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBgPage,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primary,
        surface: darkBgSurface,
      ),
      fontFamily: null,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBgSurface,
        foregroundColor: darkTextMain,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
