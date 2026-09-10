import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pomodo/core/i18n/app_strings.dart';
import 'package:pomodo/providers/locale_provider.dart';
import 'package:pomodo/providers/pomodoro_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocaleProvider Tests', () {
    test('Default system locale falls back correctly', () async {
      final prov = LocaleProvider();
      await prov.initLocale();
      expect(prov.language, AppLanguage.system);
    });

    test('Switch language to zh and en', () async {
      final prov = LocaleProvider();
      await prov.setLanguage(AppLanguage.zh);
      expect(prov.language, AppLanguage.zh);
      expect(prov.currentLocale.languageCode, 'zh');
      expect(prov.isZh, true);

      await prov.setLanguage(AppLanguage.en);
      expect(prov.language, AppLanguage.en);
      expect(prov.currentLocale.languageCode, 'en');
      expect(prov.isZh, false);
    });
  });

  group('PomodoroProvider Preset Tests', () {
    test('Preset focus minutes and break minutes', () {
      final pomo = PomodoroProvider();
      expect(pomo.presetMinutes, contains(25));
      expect(pomo.presetMinutes, contains(60));
      expect(pomo.presetBreakMinutes, contains(5));
      expect(pomo.presetBreakMinutes, contains(10));
      expect(pomo.presetBreakMinutes, contains(15));
      expect(pomo.targetMinutes, 25);
      expect(pomo.breakMinutes, 5);

      pomo.setTargetMinutes(35);
      expect(pomo.targetMinutes, 35);

      pomo.setBreakMinutes(10);
      expect(pomo.breakMinutes, 10);

      expect(pomo.soundPresets, contains('🌧️ 窗台夜雨'));
      expect(pomo.soundPresets, contains('🌊 深海潮汐'));
      expect(pomo.soundPresets, contains('🌲 夜色篝火'));
      expect(pomo.soundPresets, contains('🔇 静音模式'));
    });
  });
}
