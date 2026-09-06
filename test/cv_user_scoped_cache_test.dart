import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/models/cv_model.dart';
import 'package:mobile_app/services/cv_storage_service.dart';
import 'package:mobile_app/services/localization_service.dart';

import 'package:mobile_app/services/pdf_generator_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalizationService.init();
  });

  tearDown(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  group('User-Scoped Active CV Cache Tests', () {
    test('User B does not see User A CV and gets a clean empty CV', () async {
      // 1. Initial load for guest / new user
      final initialCv = await CvStorageService.loadActiveCv();
      expect(initialCv.fullName, isEmpty);
      expect(initialCv.experiences.every((e) => e.company.isEmpty), isTrue);

      // 2. Save a CV with data
      final cvA = CvModel.createEmpty('tr');
      cvA.fullName = 'Özcan Özden';
      cvA.jobTitle = 'Senior Mobile Architect';
      cvA.experiences.first.company = 'Tech Corp';
      cvA.experiences.first.position = 'Lead Flutter Developer';
      cvA.experiences.first.description = 'Developed high-scale mobile applications.';

      await CvStorageService.saveActiveCv(cvA);

      // 3. Verify it is saved and can be loaded
      final loadedA = await CvStorageService.loadActiveCv();
      expect(loadedA.fullName, equals('Özcan Özden'));
      expect(loadedA.jobTitle, equals('Senior Mobile Architect'));
      expect(loadedA.experiences.first.company, equals('Tech Corp'));

      // 4. Logout / clearActiveCvCache
      await CvStorageService.clearActiveCvCache();

      // 5. After clearing, loading active CV returns empty model
      final afterClear = await CvStorageService.loadActiveCv();
      expect(afterClear.fullName, isEmpty);
      expect(afterClear.experiences.every((e) => e.company.isEmpty), isTrue);
    });

    test('generateCvPdf renders education section with full data without errors', () async {
      final cv = CvModel.createEmpty('tr');
      cv.fullName = 'Özcan Özden';
      cv.jobTitle = 'Yazılım Mühendisi';
      cv.educations = [
        Education(
          school: 'İstanbul Teknik Üniversitesi',
          degree: 'Lisans',
          field: 'Bilgisayar Mühendisliği',
          startDate: '2016',
          endDate: '2020',
          gpa: '3.85 / 4.0',
        ),
        Education(
          school: 'Boğaziçi Üniversitesi',
          degree: 'Yüksek Lisans',
          field: 'Yapay Zeka',
          startDate: '2020',
          endDate: '2022',
          gpa: '3.92',
        ),
      ];

      for (final template in CvTemplate.values) {
        cv.template = template;
        final bytes = await PdfGeneratorService.generateCvPdf(cv, locale: 'tr');
        expect(bytes, isNotNull);
        expect(bytes.isNotEmpty, isTrue);
      }
    });
  });
}
