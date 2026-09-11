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

  // 主题强调色库 (方案 A)
  static const List<AccentThemeOption> accentOptions = [
    AccentThemeOption(
      key: 'marsGreen',
      nameZh: '正统马尔斯绿',
      nameEn: 'Marrs Green (Classic)',
      color: Color(0xFF008779),
      darkColor: Color(0xFF00A896),
      icon: Icons.spa_rounded,
    ),
    AccentThemeOption(
      key: 'oceanBlue',
      nameZh: '晴空蓝',
      nameEn: 'Ocean Blue',
      color: Color(0xFF0284C7),
      darkColor: Color(0xFF38BDF8),
      icon: Icons.water_drop_rounded,
    ),
    AccentThemeOption(
      key: 'lavender',
      nameZh: '丁香紫',
      nameEn: 'Lavender Purple',
      color: Color(0xFF7C3AED),
      darkColor: Color(0xFFA78BFA),
      icon: Icons.auto_awesome_rounded,
    ),
    AccentThemeOption(
      key: 'amberOrange',
      nameZh: '琥珀橙',
      nameEn: 'Amber Orange',
      color: Color(0xFFEA580C),
      darkColor: Color(0xFFFB923C),
      icon: Icons.local_fire_department_rounded,
    ),
    AccentThemeOption(
      key: 'obsidianBlack',
      nameZh: '黑曜石',
      nameEn: 'Obsidian Slate',
      color: Color(0xFF334155),
      darkColor: Color(0xFF64748B),
      icon: Icons.shield_moon_rounded,
    ),
  ];

  static const List<AccentThemeOption> accentThemes = accentOptions;
  static const Color darkBgCard = darkBgSurface;

  static AccentThemeOption getAccentOption(String key) {
    return accentOptions.firstWhere(
      (opt) => opt.key == key,
      orElse: () => accentOptions.first,
    );
  }

  // 动态根据主题主色构建 ThemeData
  static ThemeData buildLightTheme([Color? primaryColor]) {
    final seed = primaryColor ?? primary;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: seed,
      scaffoldBackgroundColor: bgPage,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
        primary: seed,
        surface: bgSurface,
      ),
      fontFamily: null,
      appBarTheme: const AppBarTheme(
        backgroundColor: bgSurface,
        foregroundColor: textMain,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }

  static ThemeData buildDarkTheme([Color? primaryColor]) {
    final seed = primaryColor ?? primary;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: seed,
      scaffoldBackgroundColor: darkBgPage,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
        primary: seed,
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

  static ThemeData get lightTheme => buildLightTheme(primary);
  static ThemeData get darkTheme => buildDarkTheme(primary);

  // 自适应色彩快速辅助函数
  static Color cardBg(bool isDark) => isDark ? darkBgSurface : bgSurface;
  static Color pageBg(bool isDark) => isDark ? darkBgPage : bgPage;
  static Color borderColor(bool isDark) => isDark ? darkBorder : borderLight;
  static Color textMainColor(bool isDark) => isDark ? darkTextMain : textMain;
  static Color textSecondaryColor(bool isDark) => isDark ? darkTextSecondary : textSecondary;
  static Color textMutedColor(bool isDark) => isDark ? darkTextMuted : textMuted;
}

class AccentThemeOption {
  final String key;
  final String nameZh;
  final String nameEn;
  final Color color;
  final Color darkColor;
  final IconData icon;

  const AccentThemeOption({
    required this.key,
    required this.nameZh,
    required this.nameEn,
    required this.color,
    required this.darkColor,
    required this.icon,
  });

  String get descZh {
    switch (key) {
      case 'marsGreen':
        return '正统官方，静谧与专注';
      case 'oceanBlue':
        return '深邃理性，逻辑与清澈';
      case 'lavender':
        return '温润雅致，松弛与灵感';
      case 'amberOrange':
        return '活力充沛，高能与动力';
      case 'obsidianBlack':
        return '纯黑白瓷，极简博朗风';
      default:
        return '极简设计风格';
    }
  }

  String get descEn {
    switch (key) {
      case 'marsGreen':
        return 'Timeless focus & serenity';
      case 'oceanBlue':
        return 'Clarity & rational thoughts';
      case 'lavender':
        return 'Gentle warmth & creative flow';
      case 'amberOrange':
        return 'Energy & high-momentum';
      case 'obsidianBlack':
        return 'Monochrome pure aesthetic';
      default:
        return 'Minimalist aesthetic';
    }
  }
}
