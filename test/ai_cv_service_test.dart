import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/cv_model.dart';
import 'package:mobile_app/services/ai_cv_service.dart';
import 'package:mobile_app/services/localization_service.dart';
import 'package:mobile_app/widgets/ai_aurora_glow.dart';

void main() {
  group('AiCvService Multilingual & Smart Auto-Fill Tests', () {
    test(
        'Russian prompt extracts all CV sections and synthesizes Russian executive summary',
        () async {
      const prompt =
          'Меня зовут Алексей Смирнов. 5 лет работаю ведущим разработчиком в Яндекс. Окончил МГУ им. М.В. Ломоносова по специальности Компьютерные Науки. Владею Python, Docker, PostgreSQL, английский язык C1.';

      final result =
          await AiCvService.parseCvPrompt(prompt: prompt, locale: 'ru');

      expect(result.isSuccess, isTrue);
      expect(result.detectedLanguage, equals('ru'));
      expect(result.fullName, equals('Алексей Смирнов'));
      expect(result.jobTitle.toLowerCase(), contains('разработчик'));

      // Persuasive Executive Summary in Russian
      expect(result.summary, isNotEmpty);
      expect(result.summary.toLowerCase(), contains('разработчик'));
      expect(result.summary, contains('Яндекс'));

      // Education
      expect(result.educations.isNotEmpty, isTrue);
      expect(result.educations.first.school, contains('МГУ'));
      expect(result.educations.first.degree, equals('Бакалавр'));

      // Experience
      expect(result.experiences.isNotEmpty, isTrue);
      expect(result.experiences.first.company, equals('Яндекс'));
      expect(result.experiences.first.isCurrent, isTrue);

      // Skills
      final skillNames = result.skills.map((s) => s.name).toList();
      expect(skillNames, contains('Python'));
      expect(skillNames, contains('Docker'));
      expect(skillNames, contains('PostgreSQL'));

      // Languages
      expect(result.languages.any((l) => l.language.contains('Английский')),
          isTrue);

      // Personal Traits
      expect(result.personalTraits.isNotEmpty, isTrue);
      expect(result.personalTraits, contains('Аналитическое мышление'));
    });

    test(
        'Turkish prompt extracts all CV sections and synthesizes Turkish executive summary',
        () async {
      const prompt =
          'Adım Canberk Yılmaz, İTÜ Bilgisayar mezunuyum. 4 yıl Trendyol\'da Kıdemli Mobil Geliştirici olarak çalıştım. AWS Certified Solutions Architect sertifikam var, Flutter, Kotlin, Dart ve CI/CD biliyorum.';

      final result =
          await AiCvService.parseCvPrompt(prompt: prompt, locale: 'tr');

      expect(result.isSuccess, isTrue);
      expect(result.detectedLanguage, equals('tr'));
      expect(result.fullName, equals('Canberk Yılmaz'));
      expect(result.jobTitle.toLowerCase(), contains('geliştirici'));

      // Persuasive Executive Summary in Turkish
      expect(result.summary, isNotEmpty);
      expect(result.summary, contains('Trendyol'));
      expect(result.summary, contains('Geliştirici'));

      // Education
      expect(result.educations.isNotEmpty, isTrue);
      expect(result.educations.first.school, contains('Teknik Üniversitesi'));

      // Experience
      expect(result.experiences.isNotEmpty, isTrue);
      expect(result.experiences.first.company, equals('Trendyol'));

      // Skills
      final skillNames = result.skills.map((s) => s.name).toList();
      expect(skillNames, contains('Flutter'));
      expect(skillNames, contains('Dart'));
      expect(skillNames, contains('Kotlin'));

      // Certificate
      expect(result.certificates.isNotEmpty, isTrue);
      expect(result.certificates.first.name,
          contains('AWS Certified Solutions Architect'));

      // Personal Traits
      expect(result.personalTraits.isNotEmpty, isTrue);
      expect(result.personalTraits, contains('Problem Çözme'));
    });

    test(
        'English prompt extracts all sections and synthesizes English executive summary',
        () async {
      const prompt =
          'My name is Alex Morgan. 5 years as Senior Software Engineer at Google. Stanford University BS in Computer Science. Skilled in Flutter, Dart, Cloud Architecture, AWS Certified Solutions Architect.';

      final result =
          await AiCvService.parseCvPrompt(prompt: prompt, locale: 'en');

      expect(result.isSuccess, isTrue);
      expect(result.detectedLanguage, equals('en'));
      expect(result.fullName, equals('Alex Morgan'));
      expect(result.jobTitle.toLowerCase(), contains('software engineer'));

      // Persuasive Executive Summary in English
      expect(result.summary, isNotEmpty);
      expect(result.summary, contains('Google'));
      expect(result.summary, contains('Software Engineer'));

      // Education
      expect(result.educations.isNotEmpty, isTrue);
      expect(result.educations.first.school, contains('Stanford'));

      // Experience
      expect(result.experiences.isNotEmpty, isTrue);
      expect(result.experiences.first.company, equals('Google'));

      // Skills
      final skillNames = result.skills.map((s) => s.name).toList();
      expect(skillNames, contains('Flutter'));
      expect(skillNames, contains('Dart'));

      // Certificate
      expect(result.certificates.isNotEmpty, isTrue);
      expect(result.certificates.first.name,
          contains('AWS Certified Solutions Architect'));
    });

    test('Smart merging into CvModel does not create duplicates', () {
      final cv = CvModel.createSample('tr');
      expect(cv.certificates, isEmpty);

      final parseResult = AiCvParseResult(
        fullName: 'Yeni İsim',
        jobTitle: 'Yeni Ünvan',
        summary: 'Yeni İkna Edici Özet Metni',
        educations: [
          Education(
              school: 'Boğaziçi',
              degree: 'Lisans',
              field: 'Bilgisayar',
              startDate: '2020',
              endDate: '2024'),
        ],
        experiences: [
          WorkExperience(
              company: 'Getir',
              position: 'Yazılım Uzmanı',
              startDate: '2022',
              endDate: '',
              isCurrent: true,
              description: 'Test'),
        ],
        skills: [
          SkillItem(name: 'Python', level: 90, levelLabel: 'Uzman'),
        ],
        certificates: [
          CertificateItem(
              name: 'AWS Practitioner', issuer: 'Amazon', date: '2024'),
        ],
      );

      // Simulate the smart merge performed by CvBuilderScreen
      cv.fullName = parseResult.fullName;
      cv.jobTitle = parseResult.jobTitle;
      cv.summary = parseResult.summary;

      for (final edu in parseResult.educations) {
        if (!cv.educations
            .any((e) => e.school.toLowerCase() == edu.school.toLowerCase())) {
          cv.educations.add(edu);
        }
      }

      for (final exp in parseResult.experiences) {
        if (!cv.experiences
            .any((e) => e.company.toLowerCase() == exp.company.toLowerCase())) {
          cv.experiences.add(exp);
        }
      }

      for (final sk in parseResult.skills) {
        if (!cv.skills
            .any((s) => s.name.toLowerCase() == sk.name.toLowerCase())) {
          cv.skills.add(sk);
        }
      }

      for (final cert in parseResult.certificates) {
        if (!cv.certificates
            .any((c) => c.name.toLowerCase() == cert.name.toLowerCase())) {
          cv.certificates.add(cert);
        }
      }

      expect(cv.fullName, equals('Yeni İsim'));
      expect(cv.jobTitle, equals('Yeni Ünvan'));
      expect(cv.summary, equals('Yeni İkna Edici Özet Metni'));
      expect(cv.educations.any((e) => e.school == 'Boğaziçi'), isTrue);
      expect(cv.experiences.any((e) => e.company == 'Getir'), isTrue);
      expect(cv.skills.any((s) => s.name == 'Python'), isTrue);
      expect(cv.certificates.length, equals(1));
      expect(cv.certificates.first.name, equals('AWS Practitioner'));
    });

    test(
        'CvModel.createEmpty creates completely empty CV with 1 blank card per dynamic section',
        () {
      final emptyCv = CvModel.createEmpty('tr');

      expect(CvModel.isUuid(emptyCv.id), isTrue);
      emptyCv.id = '1788720478133';
      emptyCv.ensureUuid();
      expect(CvModel.isUuid(emptyCv.id), isTrue);

      expect(emptyCv.fullName, isEmpty);
      expect(emptyCv.jobTitle, isEmpty);
      expect(emptyCv.email, isEmpty);
      expect(emptyCv.phone, isEmpty);
      expect(emptyCv.location, isEmpty);
      expect(emptyCv.summary, isEmpty);
      expect(emptyCv.linkedin, isEmpty);
      expect(emptyCv.github, isEmpty);
      expect(emptyCv.portfolioUrl, isEmpty);
      expect(emptyCv.isSample, isFalse);

      // 1 Empty Card per dynamic section
      expect(emptyCv.experiences.length, equals(1));
      expect(emptyCv.experiences.first.company, isEmpty);
      expect(emptyCv.experiences.first.position, isEmpty);

      expect(emptyCv.educations.length, equals(1));
      expect(emptyCv.educations.first.school, isEmpty);
      expect(emptyCv.educations.first.field, isEmpty);

      expect(emptyCv.certificates.length, equals(1));
      expect(emptyCv.certificates.first.name, isEmpty);

      expect(emptyCv.projects.length, equals(1));
      expect(emptyCv.projects.first.name, isEmpty);

      expect(emptyCv.languages.length, equals(1));
      expect(emptyCv.languages.first.language, isEmpty);

      expect(emptyCv.references.length, equals(1));
      expect(emptyCv.references.first.name, isEmpty);

      expect(emptyCv.skills, isEmpty);
      expect(emptyCv.personalTraits, isEmpty);
    });

    test('isSample correctly flags mock templates and passes clean user CVs',
        () {
      final sampleTr = CvModel.createSample('tr');
      final sampleEn = CvModel.createSample('en');
      final emptyCv = CvModel.createEmpty();
      final userCv = CvModel.createEmpty()..fullName = 'Zeynep Kaya';

      expect(sampleTr.isSample, isTrue);
      expect(sampleEn.isSample, isTrue);
      expect(emptyCv.isSample, isFalse);
      expect(userCv.isSample, isFalse);
    });

    test(
        'Bulletproof Full Name extraction across linguistic variations and direct prompt start',
        () async {
      // 1. Direct name at start of prompt (no prefix)
      final r1 = await AiCvService.parseCvPrompt(
        prompt:
            'Ahmet Yılmaz, 3 yıllık Flutter geliştiriciyim. Trendyol\'da çalıştım.',
        locale: 'tr',
      );
      expect(r1.fullName, equals('Ahmet Yılmaz'));

      // 2. Direct name in Russian
      final r2 = await AiCvService.parseCvPrompt(
        prompt: 'Иван Иванов, ведущий разработчик Яндекс. Окончил МГУ.',
        locale: 'ru',
      );
      expect(r2.fullName, equals('Иван Иванов'));

      // 3. Direct name in English
      final r3 = await AiCvService.parseCvPrompt(
        prompt:
            'Sarah Jenkins, Senior Software Engineer at Google. Stanford BS CS.',
        locale: 'en',
      );
      expect(r3.fullName, equals('Sarah Jenkins'));

      // 4. Turkish prefix with colon
      final r4 = await AiCvService.parseCvPrompt(
        prompt: 'İsim: Burak Kaya. Flutter geliştiriciyim.',
        locale: 'tr',
      );
      expect(r4.fullName, equals('Burak Kaya'));

      // 5. Lowercase Turkish prefix
      final r5 = await AiCvService.parseCvPrompt(
        prompt: 'adım mehmet ali demir, yazılımcıyım.',
        locale: 'tr',
      );
      expect(r5.fullName, equals('Mehmet Ali Demir'));

      // 6. Single word name in Russian
      final r6 = await AiCvService.parseCvPrompt(
        prompt: 'Меня зовут Дмитрий. Разработчик в Сбер.',
        locale: 'ru',
      );
      expect(r6.fullName, equals('Дмитрий'));
    });

    test('Location extraction captures cities and prefixes across languages',
        () async {
      final r1 = await AiCvService.parseCvPrompt(
        prompt: 'Adım Emre Koç, İstanbul\'da yaşıyorum. Flutter geliştirici.',
        locale: 'tr',
      );
      expect(r1.location, equals('İstanbul'));

      final r2 = await AiCvService.parseCvPrompt(
        prompt: 'Имя: Анна Смирнова. Город: Москва. Ведущий разработчик.',
        locale: 'ru',
      );
      expect(r2.location, equals('Москва'));

      final r3 = await AiCvService.parseCvPrompt(
        prompt: 'My name is John Doe. Location: London. Software Engineer.',
        locale: 'en',
      );
      expect(r3.location, equals('London'));
    });

    test(
        'Smart replacement seamlessly replaces empty placeholder cards with generated items at index 0',
        () {
      final cv = CvModel.createEmpty('tr');
      expect(cv.experiences.length, equals(1));
      expect(cv.experiences.first.company, isEmpty);

      final genResult = AiCvParseResult(
        experiences: [
          WorkExperience(
              company: 'Trendyol',
              position: 'Lead Dev',
              startDate: '2022',
              endDate: '',
              isCurrent: true,
              description: 'Desc 1'),
          WorkExperience(
              company: 'Getir',
              position: 'Mobile Dev',
              startDate: '2020',
              endDate: '2022',
              isCurrent: false,
              description: 'Desc 2'),
        ],
        educations: [
          Education(
              school: 'İTÜ',
              degree: 'Lisans',
              field: 'Bilgisayar',
              startDate: '2018',
              endDate: '2022',
              gpa: '3.8'),
        ],
      );

      // Simulate the smart replacement in CvBuilderScreen
      if (genResult.experiences.isNotEmpty) {
        cv.experiences.removeWhere((e) =>
            e.company.trim().isEmpty &&
            e.position.trim().isEmpty &&
            e.description.trim().isEmpty);
        for (final exp in genResult.experiences.reversed) {
          if (!cv.experiences.any(
              (e) => e.company.toLowerCase() == exp.company.toLowerCase())) {
            cv.experiences.insert(0, exp);
          }
        }
      }

      if (genResult.educations.isNotEmpty) {
        cv.educations.removeWhere((e) =>
            e.school.trim().isEmpty &&
            e.field.trim().isEmpty &&
            e.degree.trim().isEmpty);
        for (final edu in genResult.educations.reversed) {
          if (!cv.educations
              .any((e) => e.school.toLowerCase() == edu.school.toLowerCase())) {
            cv.educations.insert(0, edu);
          }
        }
      }

      // Assert that the empty placeholder card is GONE
      expect(cv.experiences.any((e) => e.company.isEmpty), isFalse);
      expect(cv.educations.any((e) => e.school.isEmpty), isFalse);

      // Assert that Trendyol is Card #1 at index 0
      expect(cv.experiences.length, equals(2));
      expect(cv.experiences[0].company, equals('Trendyol'));
      expect(cv.experiences[1].company, equals('Getir'));

      // Assert education is populated at index 0
      expect(cv.educations.length, equals(1));
      expect(cv.educations[0].school, equals('İTÜ'));
    });

    test(
        'calculateAtsScore returns 0 on empty CV and scales realistically with content',
        () {
      final emptyCv = CvModel.createEmpty();

      // A completely empty/blank CV must score exactly 0
      expect(emptyCv.calculateAtsScore(), equals(0));

      // Adding contact info increases score
      emptyCv.fullName = 'Ahmet Yılmaz';
      emptyCv.jobTitle = 'Software Architect';
      emptyCv.email = 'ahmet@example.com';
      emptyCv.phone = '+90 555 123 4567';
      emptyCv.location = 'Istanbul, Turkey';
      final contactScore = emptyCv.calculateAtsScore();
      expect(contactScore, greaterThan(0));

      // Adding professional summary increases score
      emptyCv.summary =
          'Experienced and dedicated software engineer with 8+ years building enterprise Flutter applications.';
      final summaryScore = emptyCv.calculateAtsScore();
      expect(summaryScore, greaterThan(contactScore));

      // Adding filled experience increases score
      emptyCv.experiences = [
        WorkExperience(
          company: 'Acme Corp',
          position: 'Senior Engineer',
          startDate: '2020',
          endDate: '2023',
          description:
              'Developed scalable microservices and mobile applications.',
        ),
        WorkExperience(
          company: 'Beta Soft',
          position: 'Software Developer',
          startDate: '2018',
          endDate: '2020',
          description:
              'Built cross platform mobile apps using Flutter and Dart.',
        ),
      ];
      final expScore = emptyCv.calculateAtsScore();
      expect(expScore, greaterThan(summaryScore));

      // Adding educations and skills
      emptyCv.educations = [
        Education(
            school: 'Boğaziçi University',
            degree: 'BSc',
            field: 'Computer Science',
            startDate: '2016',
            endDate: '2020'),
      ];
      emptyCv.skills = [
        SkillItem(name: 'Dart'),
        SkillItem(name: 'Flutter'),
        SkillItem(name: 'Firebase'),
        SkillItem(name: 'Clean Architecture'),
        SkillItem(name: 'CI/CD'),
      ];
      final skillScore = emptyCv.calculateAtsScore();
      expect(skillScore, greaterThan(expScore));

      // Adding languages & certificates pushes score towards 100
      emptyCv.languages = [
        LanguageItem(language: 'Turkish', level: 'Native'),
        LanguageItem(language: 'English', level: 'Fluent'),
      ];
      emptyCv.certificates = [
        CertificateItem(
            name: 'Google Certified Professional',
            issuer: 'Google',
            date: '2022'),
      ];
      final fullScore = emptyCv.calculateAtsScore();
      expect(fullScore, equals(100));
    });

    test(
        'All 19 supported languages have complete, localized strings for Voice, Aurora, and Typewriter keys',
        () {
      final keys = [
        'cv_ai_voice_btn',
        'cv_ai_voice_title',
        'cv_ai_voice_subtitle',
        'cv_ai_voice_listening',
        'cv_ai_voice_stop',
        'cv_ai_voice_apply',
        'cv_ai_badge_generated',
        'cv_ai_typing',
        'perm_mic_title',
        'perm_mic_desc',
      ];

      for (final lang in LocalizationService.supportedLanguages) {
        for (final key in keys) {
          final translated = LocalizationService.trFor(lang.code, key);
          expect(translated, isNotEmpty,
              reason: 'Key $key must be localized for ${lang.code}');
          // Ensure it did not return the raw key
          expect(translated, isNot(equals(key)),
              reason: 'Key $key must not return raw key for ${lang.code}');
        }
      }
    });

    test(
        'TypewriterHelper streams text word by word into TextEditingController',
        () async {
      final controller = TextEditingController();
      const text =
          'Innovative Flutter developer with 5 years experience creating scalable apps.';

      await TypewriterHelper.streamToController(
        controller,
        text,
        wordDelay: const Duration(milliseconds: 5),
      );

      expect(controller.text, equals(text));
    });
  });
}
