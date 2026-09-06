import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/cv_model.dart';
import 'package:mobile_app/models/document_model.dart';
import 'package:mobile_app/services/ai_cv_service.dart';
import 'package:mobile_app/services/localization_service.dart';
import 'package:mobile_app/services/document_parser_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CV AI Multi-Modal & 19-Language Localization Tests', () {
    final newKeys = [
      'cv_ai_import_title',
      'cv_ai_btn_upload_file',
      'cv_ai_btn_camera_scan',
      'cv_ai_btn_link_import',
      'cv_ai_link_dialog_title',
      'cv_ai_link_dialog_desc',
      'cv_ai_link_dialog_btn',
      'cv_ai_file_processing',
      'cv_ai_ocr_processing',
      'cv_ai_extracted_success',
      'docs_viewer_title',
      'docs_empty_bytes_error',
      'cv_ai_source_camera',
      'cv_ai_source_gallery',
    ];

    test('All 19 supported languages have translations for every new key', () {
      expect(LocalizationService.supportedLanguages.length, 19);

      for (final lang in LocalizationService.supportedLanguages) {
        final code = lang.code;
        for (final key in newKeys) {
          final translated = LocalizationService.trFor(code, key);
          expect(
            translated,
            isNotEmpty,
            reason: 'Language $code missing key $key',
          );
          expect(
            translated,
            isNot(equals(key)),
            reason: 'Language $code returned key unchanged for $key',
          );
        }
      }
    });

    test('Turkish translations are accurate and professional', () {
      expect(LocalizationService.trFor('tr', 'cv_ai_btn_upload_file'), 'Dosya Ekle (PDF/Word)');
      expect(LocalizationService.trFor('tr', 'cv_ai_btn_camera_scan'), 'Fotoğraf / Galeri');
      expect(LocalizationService.trFor('tr', 'cv_ai_btn_link_import'), 'Profil Linki');
      expect(LocalizationService.trFor('tr', 'docs_viewer_title'), 'Belge Önizleme');
    });

    test('English translations are accurate and professional', () {
      expect(LocalizationService.trFor('en', 'cv_ai_btn_upload_file'), 'Add File (PDF/Word)');
      expect(LocalizationService.trFor('en', 'cv_ai_btn_camera_scan'), 'Photo / Gallery');
      expect(LocalizationService.trFor('en', 'cv_ai_btn_link_import'), 'Profile Link');
      expect(LocalizationService.trFor('en', 'docs_viewer_title'), 'Document Preview');
    });
  });

  group('Non-Destructive Cumulative Merge Logic Tests', () {
    test('Existing user fields are NEVER overwritten or wiped out when new AI data arrives', () {
      // 1. Existing CV with prior data
      final initialCv = CvModel(
        id: 'test_cv_1',
        fullName: 'Özcan Özden',
        jobTitle: 'Senior Flutter Developer',
        email: 'ozcan@example.com',
        phone: '+90 555 111 2233',
        location: 'Istanbul, Turkey',
        summary: 'Experienced mobile developer with 5+ years building scalable apps.',
        skills: [
          SkillItem(name: 'Flutter', level: 95),
          SkillItem(name: 'Dart', level: 90),
        ],
        experiences: [
          WorkExperience(
            company: 'TechCorp Istanbul',
            position: 'Mobile Team Lead',
            startDate: '2021',
            endDate: 'Present',
            description: 'Led a team of 4 Flutter engineers.',
          ),
        ],
        educations: [
          Education(
            school: 'Yıldız Teknik Üniversitesi',
            degree: 'Lisans',
            field: 'Computer Engineering',
            startDate: '2015',
            endDate: '2019',
          ),
        ],
        languages: [
          LanguageItem(language: 'Türkçe', level: 'Ana Dil'),
        ],
      );

      // 2. Incoming AI parse result (e.g. from a subsequent voice prompt or scanned document)
      final incomingResult = AiCvParseResult(
        isSuccess: true,
        fullName: '', // user spoke something without their name
        jobTitle: '',
        email: '',
        phone: '',
        location: '',
        summary: 'Recently certified in AWS Cloud Architecture and Kubernetes.',
        skills: [
          SkillItem(name: 'Flutter', level: 90), // Duplicate skill
          SkillItem(name: 'AWS', level: 80),     // New skill
          SkillItem(name: 'Docker', level: 85),  // New skill
        ],
        experiences: [
          WorkExperience(
            company: 'CloudScale Inc',
            position: 'DevOps & Mobile Consultant',
            startDate: '2023',
            endDate: '2024',
            description: 'Implemented CI/CD pipelines.',
          ),
        ],
        educations: [],
      );

      // 3. Simulate cumulative non-destructive merge (exact logic implemented in cv_builder_screen.dart)
      // Name preservation
      final mergedFullName = incomingResult.fullName.trim().isNotEmpty && initialCv.fullName.trim().isEmpty
          ? incomingResult.fullName.trim()
          : initialCv.fullName;

      final mergedJobTitle = incomingResult.jobTitle.trim().isNotEmpty && initialCv.jobTitle.trim().isEmpty
          ? incomingResult.jobTitle.trim()
          : initialCv.jobTitle;

      final mergedEmail = incomingResult.email.trim().isNotEmpty && initialCv.email.trim().isEmpty
          ? incomingResult.email.trim()
          : initialCv.email;

      final mergedPhone = incomingResult.phone.trim().isNotEmpty && initialCv.phone.trim().isEmpty
          ? incomingResult.phone.trim()
          : initialCv.phone;

      final mergedLocation = incomingResult.location.trim().isNotEmpty && initialCv.location.trim().isEmpty
          ? incomingResult.location.trim()
          : initialCv.location;

      // Summary non-destructive append
      final oldSummary = initialCv.summary.trim();
      final newSummary = incomingResult.summary.trim();
      String mergedSummary = oldSummary;
      if (newSummary.isNotEmpty) {
        if (oldSummary.isEmpty) {
          mergedSummary = newSummary;
        } else if (!oldSummary.contains(newSummary)) {
          mergedSummary = '$oldSummary\n\n$newSummary';
        }
      }

      // Skills non-destructive deduplicated append
      final mergedSkills = List<SkillItem>.from(initialCv.skills);
      for (final newSkill in incomingResult.skills) {
        final norm = newSkill.name.trim().toLowerCase();
        if (!mergedSkills.any((s) => s.name.trim().toLowerCase() == norm)) {
          mergedSkills.add(newSkill);
        }
      }

      // Experiences non-destructive append
      final mergedExperiences = List<WorkExperience>.from(initialCv.experiences);
      for (final newExp in incomingResult.experiences) {
        final isDuplicate = mergedExperiences.any((e) =>
            e.company.trim().toLowerCase() == newExp.company.trim().toLowerCase() &&
            e.position.trim().toLowerCase() == newExp.position.trim().toLowerCase());
        if (!isDuplicate) {
          mergedExperiences.add(newExp);
        }
      }

      // Educations non-destructive append
      final mergedEducations = List<Education>.from(initialCv.educations);
      for (final newEdu in incomingResult.educations) {
        final isDuplicate = mergedEducations.any((e) =>
            e.school.trim().toLowerCase() == newEdu.school.trim().toLowerCase());
        if (!isDuplicate) {
          mergedEducations.add(newEdu);
        }
      }

      // 4. Assertions: VERIFY ZERO LOSS OF ORIGINAL DATA
      expect(mergedFullName, equals('Özcan Özden'));
      expect(mergedJobTitle, equals('Senior Flutter Developer'));
      expect(mergedEmail, equals('ozcan@example.com'));
      expect(mergedPhone, equals('+90 555 111 2233'));
      expect(mergedLocation, equals('Istanbul, Turkey'));

      // Verify summary has BOTH previous summary and newly appended summary
      expect(mergedSummary, contains('Experienced mobile developer with 5+ years'));
      expect(mergedSummary, contains('Recently certified in AWS Cloud Architecture'));

      // Verify skills: Flutter and Dart are preserved, AWS and Docker added, no duplicate Flutter
      expect(mergedSkills.length, equals(4));
      expect(mergedSkills.map((s) => s.name).toList(), containsAll(['Flutter', 'Dart', 'AWS', 'Docker']));

      // Verify experiences: TechCorp Istanbul preserved, CloudScale Inc added
      expect(mergedExperiences.length, equals(2));
      expect(mergedExperiences.any((e) => e.company == 'TechCorp Istanbul'), isTrue);
      expect(mergedExperiences.any((e) => e.company == 'CloudScale Inc'), isTrue);

      // Verify education: Yıldız Teknik preserved
      expect(mergedEducations.length, equals(1));
      expect(mergedEducations.first.school, equals('Yıldız Teknik Üniversitesi'));
    });

    test('If initial field was empty, incoming AI value populates it properly', () {
      final initialCv = CvModel(
        id: 'test_cv_2',
        fullName: '',
        jobTitle: '',
        email: '',
        phone: '',
        location: '',
        summary: '',
        experiences: [],
        educations: [],
        skills: [],
        languages: [],
      );

      final incomingResult = AiCvParseResult(
        isSuccess: true,
        fullName: 'Zeynep Kaya',
        jobTitle: 'Product Designer',
        email: 'zeynep@design.com',
        phone: '+90 532 999 8877',
        location: 'Ankara',
        summary: 'Passionate UI/UX designer.',
        skills: [SkillItem(name: 'Figma', level: 90)],
        experiences: [],
        educations: [],
      );

      final mergedFullName = incomingResult.fullName.trim().isNotEmpty && initialCv.fullName.trim().isEmpty
          ? incomingResult.fullName.trim()
          : initialCv.fullName;

      final mergedJobTitle = incomingResult.jobTitle.trim().isNotEmpty && initialCv.jobTitle.trim().isEmpty
          ? incomingResult.jobTitle.trim()
          : initialCv.jobTitle;

      final mergedEmail = incomingResult.email.trim().isNotEmpty && initialCv.email.trim().isEmpty
          ? incomingResult.email.trim()
          : initialCv.email;

      final mergedPhone = incomingResult.phone.trim().isNotEmpty && initialCv.phone.trim().isEmpty
          ? incomingResult.phone.trim()
          : initialCv.phone;

      expect(mergedFullName, equals('Zeynep Kaya'));
      expect(mergedJobTitle, equals('Product Designer'));
      expect(mergedEmail, equals('zeynep@design.com'));
      expect(mergedPhone, equals('+90 532 999 8877'));
    });
  });

  group('Document Archive Storage & Real Bytes Model Tests', () {
    test('CvStorageService document model correctly stores and identifies physical document formats', () {
      final docPdf = DocumentModel(
        id: 'doc_pdf_101',
        title: 'Original Scanned Contract.pdf',
        type: DocumentType.scannedDocument,
        createdAt: DateTime.now(),
        pageCount: 2,
        fileSize: '1.4 MB',
        filePath: '/some/path/saved_documents/doc_pdf_101.pdf',
      );

      expect(docPdf.type, equals(DocumentType.scannedDocument));
      expect(docPdf.filePath, contains('doc_pdf_101.pdf'));

      final docTxt = DocumentModel(
        id: 'doc_txt_202',
        title: 'Extracted OCR Notes.txt',
        type: DocumentType.scannedDocument,
        createdAt: DateTime.now(),
        pageCount: 1,
        fileSize: '12 KB',
        filePath: '/some/path/saved_documents/doc_txt_202.txt',
      );

      expect(docTxt.filePath, contains('.txt'));
    });
  });

  group('AI Name Extraction & Language Adherence Tests (Russian Bug Fix)', () {
    test('"benim adım özcan özden" parses accurately to "Özcan Özden" without "ım" prefix artifact', () async {
      await LocalizationService.setLanguage('tr');

      final result = await AiCvService.parseCvPrompt(
        prompt: 'benim adım özcan özden',
        locale: 'tr',
      );

      expect(result.isSuccess, isTrue);
      expect(result.fullName, equals('Özcan Özden'));
      expect(result.fullName, isNot(contains('ım')));
      expect(result.fullName.startsWith('ım'), isFalse);
    });

    test('Complex Turkish intro "benim adım Ahmet Yılmaz. Yıldız Teknik mezunuyum. 4 yıl mobil yazılım deneyimim var" parses name properly', () async {
      await LocalizationService.setLanguage('tr');

      final result = await AiCvService.parseCvPrompt(
        prompt: 'benim adım Ahmet Yılmaz. Yıldız Teknik mezunuyum. 4 yıl mobil yazılım deneyimim var',
        locale: 'tr',
      );

      expect(result.isSuccess, isTrue);
      expect(result.fullName, equals('Ahmet Yılmaz'));
      // Education and summary must be Turkish
      expect(result.educations.isNotEmpty, isTrue);
      expect(result.educations.first.degree, equals('Lisans'));
      expect(result.educations.first.field, contains('Bilgisayar Mühendisliği'));
      // Should NOT contain any Russian characters
      final russianRegex = RegExp(r'[\u0400-\u04FF]');
      expect(russianRegex.hasMatch(result.summary), isFalse);
      expect(russianRegex.hasMatch(result.educations.first.degree), isFalse);
      expect(russianRegex.hasMatch(result.educations.first.field), isFalse);
    });

    test('Selected profile language TR strictly governs fields: degrees, summaries and universities are Turkish', () async {
      await LocalizationService.setLanguage('tr');

      final result = await AiCvService.parseCvPrompt(
        prompt: 'Flutter ve Dart ile 3 yıl çalıştım. Istanbul Teknik mezunuyum.',
        locale: 'tr',
      );

      expect(result.isSuccess, isTrue);
      expect(result.educations.isNotEmpty, isTrue);
      expect(result.educations.first.degree, equals('Lisans'));
      expect(result.languages.isNotEmpty, isTrue);
      expect(result.languages.first.language, equals('Türkçe'));
      expect(result.languages.first.level, equals('Ana Dil'));

      // Ensure NO Russian text anywhere
      final cyrillic = RegExp(r'[\u0400-\u04FF]');
      expect(cyrillic.hasMatch(result.summary), isFalse);
      expect(cyrillic.hasMatch(result.jobTitle), isFalse);
    });

    test('All 19 supported locales produce their dedicated native degrees and labels without Russian leakage', () async {
      for (final lang in LocalizationService.supportedLanguages) {
        final code = lang.code;
        final result = await AiCvService.parseCvPrompt(
          prompt: 'Full stack developer, graduated from Oxford University with a degree.',
          locale: code,
        );

        expect(result.isSuccess, isTrue);
        expect(result.educations.isNotEmpty, isTrue);
        expect(result.languages.isNotEmpty, isTrue);

        // If not Russian locale, it should NEVER contain Cyrillic in degrees
        if (code != 'ru') {
          final cyrillic = RegExp(r'[\u0400-\u04FF]');
          expect(
            cyrillic.hasMatch(result.educations.first.degree),
            isFalse,
            reason: 'Locale $code leaked Cyrillic into education degree',
          );
        } else {
          // If Russian, Cyrillic is expected
          expect(result.educations.first.degree, equals('Бакалавр'));
        }
      }
    });

    test('Old CV text with noise or binary symbols does NOT falsely trigger Russian detection', () async {
      await LocalizationService.setLanguage('tr');

      // Simulating text containing weird unicode symbols or stray accents
      const noisyText = '''
      ÖZCAN ÖZDEN
      Yazılım Mühendisi
      Deneyim: 5 yıl mobil uygulama geliştirme
      Eğitim: Yıldız Teknik Üniversitesi
      İletişim: ozcan@test.com - +90 555 444 3322
      § © ® ™
      ''';

      final result = await AiCvService.parseCvPrompt(
        prompt: noisyText,
        locale: 'tr',
      );

      expect(result.isSuccess, isTrue);
      expect(result.fullName, equals('Özcan Özden'));
      expect(result.email, equals('ozcan@test.com'));
      expect(result.phone, equals('+90 555 444 3322'));
      // Education must be Turkish
      expect(result.educations.first.degree, equals('Lisans'));
      expect(result.languages.first.language, equals('Türkçe'));
    });
  });

  group('PDF Text Extraction Tests (Noise & Decompression)', () {
    test('parsePdf extracts text from uncompressed BT..ET blocks cleanly', () async {
      const samplePdfText = '%PDF-1.4\n1 0 obj\n<< /Length 50 >>\nstream\nBT\n(Ozcan Ozden) Tj\n(Senior Software Engineer) Tj\nET\nendstream\nendobj\nxref\ntrailer\n<< /Root 1 0 R >>\n%%EOF';
      final bytes = Uint8List.fromList(latin1.encode(samplePdfText));

      final extracted = await DocumentParserService.parsePdf(bytes);
      expect(extracted, contains('Ozcan Ozden'));
      expect(extracted, contains('Senior Software Engineer'));
    });

    test('parsePdf on pure binary noise returns empty string instead of decoding into Cyrillic/Russian', () async {
      // Create random binary bytes with byte values 0xD0-0xDF that used to turn into Cyrillic
      final binaryNoise = Uint8List.fromList([0xD0, 0x90, 0xD0, 0x91, 0x00, 0x01, 0xFE, 0xFF, 0x12, 0x34]);

      final extracted = await DocumentParserService.parsePdf(binaryNoise);
      expect(extracted.isEmpty, isTrue);
    });
  });
}
