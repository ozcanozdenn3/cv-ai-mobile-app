import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/cv_model.dart';
import 'package:mobile_app/services/localization_service.dart';
import 'package:mobile_app/services/pdf_generator_service.dart';

void main() {
  for (final locale in LocalizationService.supportedLanguages) {
    test('sidebar modern PDF renders ${locale.code}', () async {
      final cv = CvModel.createSample(locale.code)
        ..template = CvTemplate.sidebarModern
        ..targetLanguage = locale.code;

      final bytes = await PdfGeneratorService.generateCvPdf(cv);
      expect(bytes, hasLength(greaterThan(1000)));
    });
  }
}
