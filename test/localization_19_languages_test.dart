import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/services/localization_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const expectedLocales = [
    'en',
    'tr',
    'en_GB',
    'de',
    'fr',
    'es',
    'es_MX',
    'pt_BR',
    'pt_PT',
    'it',
    'nl',
    'pl',
    'ru',
    'ar',
    'hi',
    'zh',
    'ja',
    'ko',
    'id',
  ];

  test('Supported languages count is exactly 19', () {
    expect(LocalizationService.supportedLanguages.length, 19);
    final codes = LocalizationService.supportedLanguages.map((l) => l.code).toList();
    for (final expected in expectedLocales) {
      expect(codes.contains(expected), isTrue, reason: 'Missing locale: $expected');
    }
  });

  for (final locale in expectedLocales) {
    test('Locale $locale renders clean title, studio card, and hero header', () async {
      await LocalizationService.setLanguage(locale);
      expect(LocalizationService.currentLocale, locale);

      // Verify app_title is exactly 'CV AI' (so normal 'Studio' is removed, leaving only the colored card)
      final appTitle = LocalizationService.tr('app_title');
      expect(appTitle, 'CV AI',
          reason: 'For locale $locale, app_title should be "CV AI" but was "$appTitle"');

      // Verify bottom nav CV item label is exactly 'CV'
      final navCv = LocalizationService.tr('nav_cv');
      expect(navCv, 'CV',
          reason: 'For locale $locale, nav_cv should be "CV" but was "$navCv"');

      // Verify home_hero_title is clean (no AI marketing clutter like "3 minutes", "3 Minuten", "3분")
      final heroTitle = LocalizationService.tr('home_hero_title');
      expect(heroTitle.isNotEmpty, isTrue, reason: 'Hero title empty for $locale');
      expect(heroTitle.contains('3 Min'), isFalse,
          reason: 'Hero title contains "3 Min" in $locale: $heroTitle');
      expect(heroTitle.contains('3분'), isFalse,
          reason: 'Hero title contains "3분" in $locale: $heroTitle');
      expect(heroTitle.contains('3 menit'), isFalse,
          reason: 'Hero title contains "3 menit" in $locale: $heroTitle');
      expect(heroTitle.contains('3 минут'), isFalse,
          reason: 'Hero title contains "3 минут" in $locale: $heroTitle');

      // Verify essential Home Screen keys exist and have content
      final keysToCheck = [
        'app_subtitle',
        'home_hero_cta',
        'home_converter_title',
        'convert_word_to_pdf',
        'convert_pptx_to_pdf',
        'home_tools_title',
        'cam_title',
        'convert_img_to_pdf',
        'convert_ocr_to_txt',
        'home_saved_docs',
        'home_recent_title',
        'docs_empty_title',
        'docs_empty_desc',
      ];

      for (final key in keysToCheck) {
        final val = LocalizationService.tr(key);
        expect(val.isNotEmpty, isTrue, reason: 'Key $key translated to empty for locale $locale');
        expect(val, isNot(key), reason: 'Key $key was not translated (fallback raw key) for locale $locale');
      }
    });
  }
}
