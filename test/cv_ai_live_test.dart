import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/services/ai_cv_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _LiveHttpOverrides extends HttpOverrides {}

// Opt-in only: uses the supplied local fixture and configured test credentials.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pdfPath = String.fromEnvironment('CV_LIVE_PDF');
  const imagePath = String.fromEnvironment('CV_LIVE_IMAGE');
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Live summary enhancement preserves Turkish under German UI', () async {
    await HttpOverrides.runWithHttpOverrides(() async {
      final result = await AiCvService.enhanceSummary(
          rawSummary:
              'Mobil uygulama geliştiriyorum. Swift ve Kotlin kullanıyorum. Üniversitede staj yaptım.',
          locale: 'de');
      expect(result, isNotEmpty);
      expect(result, contains('Swift'));
      expect(result, contains('Kotlin'));
      expect(result, isNot(contains('**')));
      expect(result, isNot(contains('Ich')));
    }, _LiveHttpOverrides());
  }, skip: pdfPath.isEmpty, timeout: const Timeout(Duration(minutes: 2)));

  for (final entry
      in {'application/pdf': pdfPath, 'image/png': imagePath}.entries) {
    test('Live ${entry.key} complete summary, candidate and references',
        () async {
      await HttpOverrides.runWithHttpOverrides(() async {
        final result = await AiCvService.parseCvDocument(
            bytes: await File(entry.value).readAsBytes(),
            mimeType: entry.key,
            locale: 'ru');
        expect(result.source, 'gemini_api');
        expect(result.summary, contains('boyunca'));
        expect(result.summary, contains('hedefliyorum'));
        expect(result.summary.length, greaterThan(650));
        expect(result.email, 'ozcannozdenn@gmail.com');
        expect(result.references, hasLength(1));
        expect(result.references.single.email, 'myasinpak@gmail.com');
        expect(result.educations, hasLength(2));
        expect(result.projects.length, greaterThanOrEqualTo(4));
        if (entry.key == 'application/pdf') {
          expect(result.experiences, hasLength(3));
          expect(result.personalTraits.length, greaterThanOrEqualTo(4));
        }
      }, _LiveHttpOverrides());
    }, skip: entry.value.isEmpty, timeout: const Timeout(Duration(minutes: 2)));
  }
}
