import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/cv_model.dart';
import 'package:mobile_app/services/pdf_generator_service.dart';
import 'package:mobile_app/services/localization_service.dart';

class _Network extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final template in CvTemplate.values) {
    test('PDF regular ${template.name} all languages', () async {
      await HttpOverrides.runWithHttpOverrides(() async {
        for (final locale in LocalizationService.supportedLanguages) {
          final cv = CvModel.createSample(locale.code)..template = template;
          final bytes = await PdfGeneratorService.generateCvPdf(cv, locale: locale.code);
          expect(bytes.length, greaterThan(1000));
          await File('/tmp/cv-regular-${template.name}-${locale.code}.pdf').writeAsBytes(bytes);
        }
      }, _Network());
    }, timeout: const Timeout(Duration(minutes: 5)));
    test('PDF long content ${template.name}', () async {
      await HttpOverrides.runWithHttpOverrides(() async {
        final cv = CvModel.createSample('en')..template = template;
        cv.fullName = 'Alexandra Very Long Candidate Family Name';
        cv.email = '${List.filled(8, 'longaddress').join()}@example.com';
        cv.summary = List.filled(100, 'Experience in engineering and design.').join(' ');
        cv.experiences.first.description = List.filled(100,
            'Developed reliable software and delivered complex projects.').join('\n');
        final bytes = await PdfGeneratorService.generateCvPdf(cv, locale: 'en');
        expect(bytes.length, greaterThan(1000));
        await File('/tmp/cv-stress-${template.name}.pdf').writeAsBytes(bytes);
      }, _Network());
    }, timeout: const Timeout(Duration(minutes: 3)));
  }
}
