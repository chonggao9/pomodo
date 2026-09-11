import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';
import '../core/i18n/app_strings.dart';
import 'today/today_page.dart';
import 'pomodoro/pomodoro_page.dart';
import 'stats/stats_page.dart';
import 'profile/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      TodayPage(onNavigateTab: _onTabTapped),
      PomodoroPage(onNavigateTab: _onTabTapped),
      const StatsPage(),
      const ProfilePage(),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final strings = AppStrings.of(context);

    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: isDark ? AppTheme.darkBgSurface : Colors.white,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkBgSurface : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? AppTheme.darkBorder : AppTheme.borderLight,
                width: 1.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: isDark ? AppTheme.darkBgSurface : Colors.white,
            selectedItemColor: primaryColor,
            unselectedItemColor: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
            selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.check_circle_outline_rounded),
                activeIcon: const Icon(Icons.check_circle_rounded),
                label: strings.tabToday,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.timelapse_outlined),
                activeIcon: const Icon(Icons.timelapse_rounded),
                label: strings.tabFocus,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.bar_chart_outlined),
                activeIcon: const Icon(Icons.bar_chart_rounded),
                label: strings.tabStats,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline_rounded),
                activeIcon: const Icon(Icons.person_rounded),
                label: strings.tabMine,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
