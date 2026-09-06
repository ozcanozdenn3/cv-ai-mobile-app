import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/cv_model.dart';
import 'package:mobile_app/screens/cv_builder_screen.dart';
import 'package:mobile_app/services/ai_cv_service.dart';
import 'package:mobile_app/services/localization_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('AI CV Multi-Section & Card Extraction Regression Tests', () {
    test('Language level normalization handles Turkish, English, and CEFR levels', () {
      final levels = LocalizationService.getLanguageLevels();

      // Native
      expect(LocalizationService.normalizeLanguageLevel('Ana Dil'), levels[0]);
      expect(LocalizationService.normalizeLanguageLevel('Native'), levels[0]);
      expect(LocalizationService.normalizeLanguageLevel('Muttersprache'), levels[0]);

      // C2 / Fluent / Master
      expect(LocalizationService.normalizeLanguageLevel('C2'), levels[1]);
      expect(LocalizationService.normalizeLanguageLevel('Akıcı'), levels[1]);
      expect(LocalizationService.normalizeLanguageLevel('Fluent'), levels[1]);

      // C1 / Advanced / İleri
      expect(LocalizationService.normalizeLanguageLevel('C1'), levels[2]);
      expect(LocalizationService.normalizeLanguageLevel('İleri Seviye'), levels[2]);
      expect(LocalizationService.normalizeLanguageLevel('Advanced'), levels[2]);

      // B2 / Upper Intermediate
      expect(LocalizationService.normalizeLanguageLevel('B2'), levels[3]);
      expect(LocalizationService.normalizeLanguageLevel('Üst Orta'), levels[3]);

      // B1 / Intermediate / Orta
      expect(LocalizationService.normalizeLanguageLevel('B1'), levels[4]);
      expect(LocalizationService.normalizeLanguageLevel('Orta Düzey'), levels[4]);
      expect(LocalizationService.normalizeLanguageLevel('Intermediate'), levels[4]);

      // A2 / Elementary
      expect(LocalizationService.normalizeLanguageLevel('A2'), levels[5]);
      expect(LocalizationService.normalizeLanguageLevel('Temel'), levels[5]);

      // A1 / Beginner
      expect(LocalizationService.normalizeLanguageLevel('A1'), levels[6]);
      expect(LocalizationService.normalizeLanguageLevel('Başlangıç'), levels[6]);
      expect(LocalizationService.normalizeLanguageLevel('Beginner'), levels[6]);
    });

    test('Parses full JSON with 3 experiences, 2 educations, languages, references, traits, and social links', () {
      final sampleJson = jsonEncode({
        "detectedLanguage": "tr",
        "fullName": "Özcan Özden",
        "jobTitle": "Kıdemli Mobil Geliştirici",
        "email": "ozcan@example.com",
        "phone": "+90 555 123 4567",
        "location": "İstanbul, Türkiye",
        "summary": "10 yılı aşkın süredir Flutter, iOS ve Android ekosisteminde yüksek performanslı mobil uygulamalar geliştiren kıdemli yazılım mühendisi.",
        "linkedin": "https://linkedin.com/in/ozcanozden",
        "github": "https://github.com/ozcanozden",
        "portfolioUrl": "https://ozcanozden.dev",
        "educations": [
          {
            "school": "İstanbul Teknik Üniversitesi",
            "degree": "Yüksek Lisans",
            "field": "Bilgisayar Mühendisliği",
            "startDate": "2020",
            "endDate": "2022",
            "gpa": "3.85/4.00"
          },
          {
            "school": "Yıldız Teknik Üniversitesi",
            "degree": "Lisans",
            "field": "Yazılım Mühendisliği",
            "startDate": "2015",
            "endDate": "2019",
            "gpa": "3.60/4.00"
          }
        ],
        "experiences": [
          {
            "company": "Tech Corp A",
            "position": "Lead Mobile Architect",
            "startDate": "2022",
            "endDate": "Present",
            "isCurrent": true,
            "description": "• 5 milyondan fazla kullanıcıya sahip mobil bankacılık uygulamasının mimarisini yönetti.\n• Uygulama başlatma süresini %40 optimize etti.\n• 8 kişilik mobil mühendislik ekibine liderlik etti."
          },
          {
            "company": "Software Studio B",
            "position": "Senior Flutter Developer",
            "startDate": "2019",
            "endDate": "2022",
            "isCurrent": false,
            "description": "• E-ticaret ve teslimat alanında 4 farklı Flutter projesi geliştirdi ve App Store / Google Play'de yayınladı.\n• BLoC state management ve CI/CD pipeline süreçlerini kurdu."
          },
          {
            "company": "Startup C",
            "position": "Mobile Developer",
            "startDate": "2018",
            "endDate": "2019",
            "isCurrent": false,
            "description": "• Sosyal medya platformu için iOS ve Android uygulamaları geliştirdi."
          }
        ],
        "skills": [
          {"name": "Flutter & Dart", "level": 95, "levelLabel": "Expert"},
          {"name": "Swift & iOS", "level": 85, "levelLabel": "Advanced"},
          {"name": "Kotlin & Android", "level": 85, "levelLabel": "Advanced"},
          {"name": "CI/CD & Fastlane", "level": 80, "levelLabel": "Advanced"}
        ],
        "certificates": [
          {
            "name": "Google Certified Professional Mobile Engineer",
            "issuer": "Google",
            "date": "2021",
            "credentialUrl": "https://google.com/cert/123"
          }
        ],
        "languages": [
          {"language": "Türkçe", "level": "Ana Dil"},
          {"language": "İngilizce", "level": "C1 - İleri Düzey"},
          {"language": "Almanca", "level": "B1"}
        ],
        "personalTraits": [
          "Problem Çözme",
          "Takım Liderliği",
          "Analitik Düşünme",
          "Hızlı Adaptasyon"
        ],
        "references": [
          {
            "name": "Ahmet Yılmaz",
            "position": "VP of Engineering",
            "company": "Tech Corp A",
            "phone": "+90 532 000 1122",
            "email": "ahmet@techcorpa.com"
          },
          {
            "name": "Mehmet Kaya",
            "position": "CTO",
            "company": "Software Studio B",
            "phone": "+90 533 999 8877",
            "email": "mehmet@softwareb.com"
          }
        ]
      });

      final result = AiCvService.parseJsonToResultForTesting(
        sampleJson,
        source: 'gemini_api',
        fallbackLocale: 'tr',
      );

      expect(result.isSuccess, isTrue);
      expect(result.fullName, 'Özcan Özden');
      expect(result.linkedin, 'https://linkedin.com/in/ozcanozden');
      expect(result.github, 'https://github.com/ozcanozden');
      expect(result.portfolioUrl, 'https://ozcanozden.dev');

      // 2 Universities
      expect(result.educations, hasLength(2));
      expect(result.educations[0].school, 'İstanbul Teknik Üniversitesi');
      expect(result.educations[0].degree, 'Yüksek Lisans');
      expect(result.educations[1].school, 'Yıldız Teknik Üniversitesi');
      expect(result.educations[1].degree, 'Lisans');

      // 3 Experiences with full unabridged descriptions
      expect(result.experiences, hasLength(3));
      expect(result.experiences[0].company, 'Tech Corp A');
      expect(result.experiences[0].position, 'Lead Mobile Architect');
      expect(result.experiences[0].isCurrent, isTrue);
      expect(result.experiences[0].description, contains('5 milyondan fazla kullanıcı'));
      expect(result.experiences[0].description, contains('başlatma süresini %40'));
      expect(result.experiences[1].company, 'Software Studio B');
      expect(result.experiences[1].description, contains('BLoC state management'));
      expect(result.experiences[2].company, 'Startup C');

      // Languages
      expect(result.languages, hasLength(3));
      expect(result.languages[0].language, 'Türkçe');
      expect(result.languages[1].language, 'İngilizce');
      expect(result.languages[2].language, 'Almanca');

      // Skills
      expect(result.skills, hasLength(4));
      expect(result.skills[0].name, 'Flutter & Dart');

      // Personal Traits
      expect(result.personalTraits, hasLength(4));
      expect(result.personalTraits, contains('Problem Çözme'));
      expect(result.personalTraits, contains('Takım Liderliği'));

      // References
      expect(result.references, hasLength(2));
      expect(result.references[0].name, 'Ahmet Yılmaz');
      expect(result.references[0].company, 'Tech Corp A');
      expect(result.references[1].name, 'Mehmet Kaya');
    });

    test('Handles alternative LLM array shapes: string lists for skills, traits, and languages', () {
      final alternativeJson = jsonEncode({
        "detectedLanguage": "tr",
        "fullName": "Test Aday",
        "jobTitle": "Yazılım Uzmanı",
        "email": "test@aday.com",
        "phone": "+90 500 000 0000",
        "location": "Ankara",
        "summary": "Deneyimli yazılımcı",
        "linkedin": "linkedin.com/in/testaday",
        "github": "github.com/testaday",
        "portfolioUrl": "",
        "educations": [
          {
            "school": "Hacettepe Üniversitesi",
            "degree": "Lisans",
            "field": "Bilişim"
          }
        ],
        "experiences": [
          {
            "company": "Şirket X",
            "position": "Geliştirici",
            "description": "Tüm backend ve frontend sistemlerini yönetti."
          }
        ],
        // LLM returned string lists instead of objects
        "skills": ["Flutter", "Dart", "Docker", "Python"],
        "languages": ["Türkçe (Ana Dil)", "İngilizce (C1)"],
        "personalTraits": ["Çözüm Odaklı", "Hızlı Öğrenen"],
        "references": [
          {
            "name": "Prof. Danışman",
            "company": "Hacettepe",
            "email": "danisman@hacettepe.edu.tr"
          }
        ]
      });

      final result = AiCvService.parseJsonToResultForTesting(
        alternativeJson,
        source: 'gemini_api',
        fallbackLocale: 'tr',
      );

      expect(result.isSuccess, isTrue);
      expect(result.skills, hasLength(4));
      expect(result.skills.map((s) => s.name), containsAll(['Flutter', 'Dart', 'Docker', 'Python']));

      expect(result.languages, hasLength(2));
      expect(result.languages[0].language, 'Türkçe');
      expect(result.languages[1].language, 'İngilizce');

      expect(result.personalTraits, hasLength(2));
      expect(result.personalTraits, contains('Çözüm Odaklı'));
      expect(result.personalTraits, contains('Hızlı Öğrenen'));

      expect(result.references, hasLength(1));
      expect(result.references.single.name, 'Prof. Danışman');
    });

    testWidgets('CvBuilderScreen imports multi-item CV result into cards without dropping', (tester) async {
      final cv = CvModel.createEmpty();
      await tester.pumpWidget(MaterialApp(
        home: CvBuilderScreen(initialCv: cv),
      ));
      await tester.pumpAndSettle();

      final sampleResult = AiCvParseResult(
        isSuccess: true,
        source: 'gemini_api',
        fullName: 'Mehmet Demir',
        jobTitle: 'Senior Flutter Lead',
        email: 'mehmet@demir.dev',
        phone: '+90 532 111 2233',
        location: 'İzmir, Türkiye',
        summary: '10 yıllık kıdemli yazılımcı ve takım lideri.',
        linkedin: 'https://linkedin.com/in/mehmetdemir',
        github: 'https://github.com/mehmetdemir',
        portfolioUrl: 'https://mehmetdemir.dev',
        educations: [
          Education(
            school: 'Ege Üniversitesi',
            degree: 'Yüksek Lisans',
            field: 'Bilgisayar Mühendisliği',
            startDate: '2020',
            endDate: '2022',
          ),
          Education(
            school: 'Dokuz Eylül Üniversitesi',
            degree: 'Lisans',
            field: 'Yazılım Mühendisliği',
            startDate: '2015',
            endDate: '2019',
          ),
        ],
        experiences: [
          WorkExperience(
            company: 'Tech Corp A',
            position: 'Mobile Architect',
            startDate: '2022',
            endDate: 'Present',
            isCurrent: true,
            description: 'Uygulama mimarisini yönetti ve ekibe liderlik etti.',
          ),
          WorkExperience(
            company: 'Agency B',
            position: 'Senior Flutter Dev',
            startDate: '2020',
            endDate: '2022',
            description: '8 farklı kurumsal mobil proje teslim etti.',
          ),
          WorkExperience(
            company: 'Startup C',
            position: 'Junior Developer',
            startDate: '2019',
            endDate: '2020',
            description: 'Android uygulamaları geliştirdi.',
          ),
        ],
        languages: [
          LanguageItem(language: 'Türkçe', level: 'Ana Dil'),
          LanguageItem(language: 'İngilizce', level: 'C1'),
          LanguageItem(language: 'Almanca', level: 'B1'),
        ],
        skills: [
          SkillItem(name: 'Flutter', level: 90, levelLabel: 'Expert'),
          SkillItem(name: 'Dart', level: 90, levelLabel: 'Expert'),
          SkillItem(name: 'Kotlin', level: 85, levelLabel: 'Advanced'),
        ],
        personalTraits: ['Liderlik', 'Analitik Düşünme'],
        references: [
          ReferenceItem(
            name: 'Ali Veli',
            position: 'Müdür',
            company: 'Tech Corp A',
            phone: '05551234567',
            email: 'ali@tech.com',
          ),
          ReferenceItem(
            name: 'Ayşe Yılmaz',
            position: 'Direktör',
            company: 'Agency B',
            phone: '05559876543',
            email: 'ayse@agency.com',
          ),
        ],
      );

      final state = tester.state(find.byType(CvBuilderScreen)) as dynamic;
      state.applyAiParseResultForTesting(sampleResult);
      await tester.pump(const Duration(milliseconds: 500));

      final importedCv = state.cvForTesting as CvModel;

      expect(importedCv.fullName, 'Mehmet Demir');
      expect(importedCv.linkedin, 'https://linkedin.com/in/mehmetdemir');
      expect(importedCv.github, 'https://github.com/mehmetdemir');
      expect(importedCv.portfolioUrl, 'https://mehmetdemir.dev');

      // 3 experiences all present
      expect(importedCv.experiences, hasLength(3));
      expect(importedCv.experiences[0].company, 'Tech Corp A');
      expect(importedCv.experiences[0].description, contains('Uygulama mimarisini'));
      expect(importedCv.experiences[1].company, 'Agency B');
      expect(importedCv.experiences[2].company, 'Startup C');

      // 2 educations all present
      expect(importedCv.educations, hasLength(2));
      expect(importedCv.educations[0].school, 'Ege Üniversitesi');
      expect(importedCv.educations[1].school, 'Dokuz Eylül Üniversitesi');

      // 3 languages with normalized levels
      expect(importedCv.languages, hasLength(3));
      expect(importedCv.languages[0].language, 'Türkçe');
      expect(importedCv.languages[1].language, 'İngilizce');
      expect(importedCv.languages[2].language, 'Almanca');

      // Skills & traits
      expect(importedCv.skills, hasLength(3));
      expect(importedCv.personalTraits, hasLength(2));

      // 2 references
      expect(importedCv.references, hasLength(2));
      expect(importedCv.references[0].name, 'Ali Veli');
      expect(importedCv.references[1].name, 'Ayşe Yılmaz');

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
