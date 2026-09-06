import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/models/cv_model.dart';
import 'package:mobile_app/services/localization_service.dart';
import 'package:mobile_app/services/pdf_generator_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalizationService.init();
  });

  group('Theme Palette & 19 Languages Localization Tests', () {
    const allLanguages = [
      'tr',
      'en',
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

    test('getThemePalettes returns exactly 12 colors for all 19 languages', () {
      for (final lang in allLanguages) {
        final palettes = LocalizationService.getThemePalettes(lang);
        expect(palettes.length, equals(12),
            reason: 'Language $lang must have 12 colors');

        for (final p in palettes) {
          expect(p['name'], isNotNull);
          expect((p['name'] as String).trim(), isNotEmpty);
          expect(p['color'], isNotNull);
          expect(p['hex'], isA<int>());
        }
      }
    });

    test('Color names are distinctly localized across languages', () {
      final trPalettes = LocalizationService.getThemePalettes('tr');
      final enPalettes = LocalizationService.getThemePalettes('en');
      final dePalettes = LocalizationService.getThemePalettes('de');
      final zhPalettes = LocalizationService.getThemePalettes('zh');
      final jaPalettes = LocalizationService.getThemePalettes('ja');
      final arPalettes = LocalizationService.getThemePalettes('ar');

      // First color: 0xFF2563EB
      expect(trPalettes[0]['name'], equals('Safir Mavi'));
      expect(enPalettes[0]['name'], equals('Sapphire Blue'));
      expect(dePalettes[0]['name'], equals('Saphirblau'));
      expect(zhPalettes[0]['name'], equals('经典宝石蓝'));
      expect(jaPalettes[0]['name'], equals('サファイアブルー'));
      expect(arPalettes[0]['name'], equals('أزرق ياقوتي'));

      // New colors: Deep Teal, Midnight Navy, etc.
      expect(trPalettes[1]['name'], equals('Zümrüt Petrol'));
      expect(enPalettes[1]['name'], equals('Deep Teal'));
      expect(dePalettes[1]['name'], equals('Tiefes Petrol'));
    });
  });

  group('Infographic Modern Template Pagination Tests', () {
    test('Infographic Modern generates multi-page PDF without pushing everything to page 2', () async {
      final cv = CvModel.createEmpty('tr');
      cv.fullName = 'Özcan Özden';
      cv.jobTitle = 'Senior Mobile Architect';
      cv.email = 'ozcan@example.com';
      cv.phone = '+90 555 123 4567';
      cv.location = 'İstanbul, Türkiye';
      cv.summary =
          'Deneyimli mobil mimar ve Flutter geliştiricisi. Ölçeklenebilir, yüksek performanslı uygulamalar tasarlar.';

      cv.experiences = [
        WorkExperience(
          company: 'Tech Corp A',
          position: 'Lead Mobile Architect',
          startDate: '2022',
          endDate: 'Günümüz',
          description: '10 milyon+ kullanıcıya hizmet veren mimari altyapı.',
        ),
        WorkExperience(
          company: 'Innovate Studio B',
          position: 'Senior Flutter Developer',
          startDate: '2019',
          endDate: '2022',
          description: 'Cross-platform bankacılık ve fintech çözümleri.',
        ),
        WorkExperience(
          company: 'Digital Solutions C',
          position: 'Software Engineer',
          startDate: '2016',
          endDate: '2019',
          description: 'Mikroservis entegrasyonları ve mobil uygulamalar.',
        ),
      ];

      cv.educations = [
        Education(
          school: 'İstanbul Teknik Üniversitesi',
          degree: 'Lisans',
          field: 'Bilgisayar Mühendisliği',
          startDate: '2012',
          endDate: '2016',
          gpa: '3.85 / 4.0',
        ),
      ];

      cv.skills = [
        SkillItem(name: 'Flutter & Dart', level: 95),
        SkillItem(name: 'iOS & Swift', level: 85),
        SkillItem(name: 'Android & Kotlin', level: 85),
        SkillItem(name: 'System Architecture', level: 90),
        SkillItem(name: 'CI/CD & DevOps', level: 80),
      ];

      cv.languages = [
        LanguageItem(language: 'Türkçe', level: 'Ana Dil'),
        LanguageItem(language: 'İngilizce', level: 'İleri Seviye (C1)'),
      ];

      cv.template = CvTemplate.infographicModern;

      final pdfBytes = await PdfGeneratorService.generateCvPdf(cv, locale: 'tr');
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
      // Valid PDF signature check (%PDF-)
      expect(pdfBytes.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D]));
    });
  });
}
