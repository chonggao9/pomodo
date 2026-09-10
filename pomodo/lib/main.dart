import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/white_noise_service.dart';
import 'providers/task_provider.dart';
import 'providers/pomodoro_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/locale_provider.dart';
import 'views/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 强制锁定纯竖屏，防止任何横屏拉伸
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // 2. 沉浸式透明状态栏
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // 3. 异步预热并合成离线白噪音音频文件
  WhiteNoiseService.instance.init();

  runApp(const PomoDoApp());
}

class PomoDoApp extends StatelessWidget {
  const PomoDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TaskProvider()..loadTasks(),
        ),
        ChangeNotifierProvider(
          create: (_) => PomodoroProvider()..initPreferences(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider()..initProfile(),
        ),
        ChangeNotifierProvider(
          create: (_) => LocaleProvider()..initLocale(),
        ),
      ],
      child: Consumer2<ProfileProvider, LocaleProvider>(
        builder: (context, profileProv, localeProv, _) {
          return MaterialApp(
            title: 'PomoDo',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: profileProv.themeMode,
            locale: localeProv.currentLocale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('zh', 'CN'),
              Locale('en', 'US'),
            ],
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
