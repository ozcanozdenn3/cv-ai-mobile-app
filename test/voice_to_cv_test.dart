import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/services/ai_cv_service.dart';
import 'package:mobile_app/widgets/voice_to_cv_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Voice to CV Parsing Tests', () {
    test('Arbitrary spoken input parses into structured CV with zero mock data', () async {
      const userSpokenPrompt =
          'Adım Özcan Özden. 3 yıl mobil yazılım uzmanı olarak çalıştım. Yıldız Teknik Üniversitesi mezunuyum. Flutter, Dart ve Firebase biliyorum.';

      final result = await AiCvService.parseCvPrompt(
        prompt: userSpokenPrompt,
        locale: 'tr',
      );

      expect(result.isSuccess, isTrue);
      expect(result.fullName, equals('Özcan Özden'));
      expect(result.jobTitle.toLowerCase(), contains('mobil'));
      expect(result.skills.any((s) => s.name == 'Flutter'), isTrue);
      expect(result.skills.any((s) => s.name == 'Dart'), isTrue);
      expect(result.skills.any((s) => s.name == 'Firebase'), isTrue);
      expect(result.educations.isNotEmpty, isTrue);
      expect(result.educations.first.school, contains('Yıldız'));
      expect(result.experiences.isNotEmpty, isTrue);
      expect(result.summary.isNotEmpty, isTrue);
    });

    test('English voice dictation input extracts candidate accurately', () async {
      const userSpokenPrompt =
          'My name is Sarah Jenkins. I have 4 years experience as Senior Mobile Developer. Graduated from Oxford University. Skilled in Swift, Flutter, and AWS.';

      final result = await AiCvService.parseCvPrompt(
        prompt: userSpokenPrompt,
        locale: 'en',
      );

      expect(result.isSuccess, isTrue);
      expect(result.fullName, equals('Sarah Jenkins'));
      expect(result.jobTitle, equals('Senior Mobile Developer'));
      expect(result.skills.any((s) => s.name == 'Flutter'), isTrue);
      expect(result.skills.any((s) => s.name == 'AWS'), isTrue);
      expect(result.educations.isNotEmpty, isTrue);
      expect(result.educations.first.school, contains('Oxford'));
      expect(result.experiences.isNotEmpty, isTrue);
    });

    testWidgets('VoiceToCvSheet starts with completely empty text field and no mock data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceToCvSheet(
              onApplyPrompt: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.controller?.text, isEmpty);
      expect(find.textContaining('Canberk'), findsNothing);
      expect(find.textContaining('Trendyol'), findsNothing);
    });
  });
}
