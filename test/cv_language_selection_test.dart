import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/cv_model.dart';
import 'package:mobile_app/services/cv_storage_service.dart';
import 'package:mobile_app/services/localization_service.dart';
import 'package:mobile_app/services/pdf_generator_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await LocalizationService.init();
  });

  group('CV Language Selection & Card Localization Tests', () {
    test('trFor returns distinct translations for card titles and field labels without changing currentLocale', () {
      final initialLocale = LocalizationService.currentLocale;

      // Turkish
      final trSchool = LocalizationService.trFor('tr', 'cv_edu_school');
      final trDegree = LocalizationService.trFor('tr', 'cv_edu_degree');
      final trSchoolHint = LocalizationService.trFor('tr', 'hint_school');
      final trPosition = LocalizationService.trFor('tr', 'cv_exp_position');
      final trPositionHint = LocalizationService.trFor('tr', 'hint_position');

      expect(trSchool, equals('Üniversite / Okul Adı'));
      expect(trDegree, equals('Derece'));
      expect(trSchoolHint.isNotEmpty, isTrue);
      expect(trPositionHint.isNotEmpty, isTrue);
      expect(trPosition, equals('Pozisyon / Görev Ünvanı'));

      // English
      final enSchool = LocalizationService.trFor('en', 'cv_edu_school');
      final enDegree = LocalizationService.trFor('en', 'cv_edu_degree');
      final enPosition = LocalizationService.trFor('en', 'cv_exp_position');

      expect(enSchool, equals('University / School Name'));
      expect(enDegree, equals('Degree'));
      expect(enPosition, equals('Job Title / Position'));

      // German
      final deSchool = LocalizationService.trFor('de', 'cv_edu_school');
      final deDegree = LocalizationService.trFor('de', 'cv_edu_degree');
      final dePosition = LocalizationService.trFor('de', 'cv_exp_position');

      expect(deSchool, equals('Universität / Hochschule'));
      expect(deDegree, equals('Abschluss'));
      expect(dePosition, equals('Position / Rolle'));

      // Spanish
      final esSchool = LocalizationService.trFor('es', 'cv_edu_school');
      final esDegree = LocalizationService.trFor('es', 'cv_edu_degree');
      expect(esSchool, equals('Universidad / centro educativo'));
      expect(esDegree, equals('Título'));

      // currentLocale must NOT have changed
      expect(LocalizationService.currentLocale, equals(initialLocale));
    });

    test('getLanguageLevels and normalizeLanguageLevel respect explicit locale', () {
      final trLevels = LocalizationService.getLanguageLevels('tr');
      final enLevels = LocalizationService.getLanguageLevels('en');
      final deLevels = LocalizationService.getLanguageLevels('de');

      expect(trLevels[0], contains('Ana Dil'));
      expect(enLevels[0], contains('Native'));
      expect(deLevels[0], contains('Muttersprache'));

      expect(LocalizationService.normalizeLanguageLevel('ana dil', 'tr'), equals(trLevels[0]));
      expect(LocalizationService.normalizeLanguageLevel('native', 'en'), equals(enLevels[0]));
      expect(LocalizationService.normalizeLanguageLevel('muttersprache', 'de'), equals(deLevels[0]));
    });

    test('getQuickTraits and getQuickCustomTitles respect explicit locale', () {
      final trTraits = LocalizationService.getQuickTraits('tr');
      final enTraits = LocalizationService.getQuickTraits('en');
      final deTraits = LocalizationService.getQuickTraits('de');

      expect(trTraits.first, equals('Problem Çözme'));
      expect(enTraits.first, equals('Problem Solving'));
      expect(deTraits.first, equals('Problemlösung'));

      final trTitles = LocalizationService.getQuickCustomTitles('tr');
      final enTitles = LocalizationService.getQuickCustomTitles('en');
      expect(trTitles.first, contains('Ödüller'));
      expect(enTitles.first, anyOf([contains('Awards'), contains('Achievements'), contains('🏆')]));
    });

    test('CvModel preserves targetLanguage in empty creation and serialization', () {
      final cv = CvModel.createEmpty('de');
      expect(cv.targetLanguage, equals('de'));

      // Serialization roundtrip
      final map = CvStorageService.cvToMapForTesting(cv);
      expect(map['targetLanguage'], equals('de'));

      final restored = CvStorageService.cvFromMapForTesting(map);
      expect(restored.targetLanguage, equals('de'));
    });

    test('All 19 locales have valid LanguageOptions with flags and names', () {
      for (final option in LocalizationService.supportedLanguages) {
        expect(option.code.isNotEmpty, isTrue);
        expect(option.name.isNotEmpty, isTrue);
        expect(option.flag.isNotEmpty, isTrue);
        final found = LocalizationService.getLanguageOption(option.code);
        expect(found.code, equals(option.code));
      }
    });

    test('PdfCvLocaleHelper and PdfGeneratorService support ALL 19 languages regardless of app locale', () async {
      // Set the app/profile locale to Turkish
      LocalizationService.localeNotifier.value = 'tr';
      expect(LocalizationService.currentLocale, equals('tr'));

      final expectedEducationTitles = {
        'tr': 'EĞİTİM',
        'en': 'EDUCATION',
        'en_GB': 'EDUCATION',
        'de': 'AUSBILDUNG',
        'fr': 'FORMATION',
        'es': 'EDUCACIÓN',
        'es_MX': 'EDUCACIÓN',
        'pt_BR': 'EDUCAÇÃO',
        'pt_PT': 'EDUCAÇÃO',
        'it': 'ISTRUZIONE',
        'nl': 'OPLEIDING',
        'pl': 'EDUKACJA',
        'ru': 'ОБРАЗОВАНИЕ',
        'ar': 'التعليم',
        'hi': 'शिक्षा',
        'zh': '教育背景',
        'ja': '学歴',
        'ko': '학력 사항',
        'id': 'PENDIDIKAN',
      };

      final expectedExperienceTitles = {
        'tr': 'İŞ DENEYİMLERİ',
        'en': 'WORK EXPERIENCE',
        'en_GB': 'WORK EXPERIENCE',
        'de': 'BERUFSERFAHRUNG',
        'fr': 'EXPÉRIENCE PROFESSIONNELLE',
        'es': 'EXPERIENCIA LABORAL',
        'es_MX': 'EXPERIENCIA LABORAL',
        'pt_BR': 'EXPERIÊNCIA PROFISSIONAL',
        'pt_PT': 'EXPERIÊNCIA PROFISSIONAL',
        'it': 'ESPERIENZA LAVORATIVA',
        'nl': 'WERKERVARING',
        'pl': 'DOŚWIADCZENIE ZAWODOWE',
        'ru': 'ОПЫТ РАБОТЫ',
        'ar': 'الخبرات المهنية',
        'hi': 'कार्य अनुभव',
        'zh': '工作经历',
        'ja': '職務経歴',
        'ko': '경력 사항',
        'id': 'PENGALAMAN KERJA',
      };

      final expectedPresentText = {
        'tr': 'Günümüz',
        'en': 'Present',
        'en_GB': 'Present',
        'de': 'Heute',
        'fr': 'Présent',
        'es': 'Presente',
        'es_MX': 'Presente',
        'pt_BR': 'Presente',
        'pt_PT': 'Presente',
        'it': 'Presente',
        'nl': 'Heden',
        'pl': 'Obecnie',
        'ru': 'По наст. время',
        'ar': 'الحاضر',
        'hi': 'वर्तमान',
        'zh': '至今',
        'ja': '現在',
        'ko': '현재',
        'id': 'Sekarang',
      };

      for (final option in LocalizationService.supportedLanguages) {
        final code = option.code;
        final cv = CvModel.createSample(code)..targetLanguage = code;
        expect(cv.targetLanguage, equals(code));

        // 1. Check Section Titles
        final eduTitle = PdfCvLocaleHelper.getSectionTitle(CvSectionType.educations, code);
        final expTitle = PdfCvLocaleHelper.getSectionTitle(CvSectionType.experiences, code);
        final summaryTitle = PdfCvLocaleHelper.getSectionTitle(CvSectionType.summary, code);
        final skillsTitle = PdfCvLocaleHelper.getSectionTitle(CvSectionType.skills, code);
        final traitsTitle = PdfCvLocaleHelper.getSectionTitle(CvSectionType.personalTraits, code);
        final langsTitle = PdfCvLocaleHelper.getSectionTitle(CvSectionType.languages, code);
        final projTitle = PdfCvLocaleHelper.getSectionTitle(CvSectionType.projects, code);
        final certTitle = PdfCvLocaleHelper.getSectionTitle(CvSectionType.certificates, code);
        final refTitle = PdfCvLocaleHelper.getSectionTitle(CvSectionType.references, code);
        final customTitle = PdfCvLocaleHelper.getSectionTitle(CvSectionType.customSections, code);

        expect(eduTitle, equals(expectedEducationTitles[code]),
            reason: 'Education title failed for $code');
        expect(expTitle, equals(expectedExperienceTitles[code]),
            reason: 'Experience title failed for $code');
        expect(summaryTitle.isNotEmpty, isTrue);
        expect(skillsTitle.isNotEmpty, isTrue);
        expect(traitsTitle.isNotEmpty, isTrue);
        expect(langsTitle.isNotEmpty, isTrue);
        expect(projTitle.isNotEmpty, isTrue);
        expect(certTitle.isNotEmpty, isTrue);
        expect(refTitle.isNotEmpty, isTrue);
        expect(customTitle.isNotEmpty, isTrue);

        // 2. Check Sidebar & Contact Labels
        final contactTitle = PdfCvLocaleHelper.getSidebarTitle('contact', code);
        final skillsSidebar = PdfCvLocaleHelper.getSidebarTitle('skills', code);
        final langsSidebar = PdfCvLocaleHelper.getSidebarTitle('languages', code);
        final linksSidebar = PdfCvLocaleHelper.getSidebarTitle('links', code);
        expect(contactTitle.isNotEmpty, isTrue);
        expect(skillsSidebar.isNotEmpty, isTrue);
        expect(langsSidebar.isNotEmpty, isTrue);
        expect(linksSidebar.isNotEmpty, isTrue);

        final emailLabel = PdfCvLocaleHelper.getSidebarContactLabel('email', code);
        final phoneLabel = PdfCvLocaleHelper.getSidebarContactLabel('phone', code);
        final locationLabel = PdfCvLocaleHelper.getSidebarContactLabel('location', code);
        expect(emailLabel.isNotEmpty, isTrue);
        expect(phoneLabel.isNotEmpty, isTrue);
        expect(locationLabel.isNotEmpty, isTrue);

        // 3. Check Present & GPA & Tech Text
        final presentText = PdfCvLocaleHelper.getPresentText(code);
        expect(presentText, equals(expectedPresentText[code]),
            reason: 'Present text failed for $code');
        expect(PdfCvLocaleHelper.getGpaLabel(code).isNotEmpty, isTrue);
        expect(PdfCvLocaleHelper.getTechLabel(code).isNotEmpty, isTrue);

        // 4. Check Normalized Language Level
        final normalizedLevel = LocalizationService.normalizeLanguageLevel('C1', code);
        expect(normalizedLevel.isNotEmpty, isTrue);
      }

      // 5. Generate PDF for a different non-Turkish language (e.g. Spanish) with currentLocale=tr
      final esCv = CvModel.createSample('es')..targetLanguage = 'es';
      final esBytes = await PdfGeneratorService.generateCvPdf(esCv);
      expect(esBytes.length, greaterThan(1000));
    });
  });
}
