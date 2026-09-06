import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_app/constants/ai_constants.dart';
import 'package:mobile_app/services/ai_cv_service.dart';
import 'package:mobile_app/services/localization_service.dart';
import 'package:mobile_app/models/cv_model.dart';
import 'package:mobile_app/screens/cv_builder_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Full summary survives wrapped lines and stops at plural heading',
      () async {
    final result = await AiCvService.parseCvPrompt(prompt: '''
Ada Example
Profil
Birinci satır.
İkinci satır.
Üçüncü satır.
Akademik yolculuğum boyunca
mobil uygulama geliştirdim.
Profesyonel katkılar sunmayı hedefliyorum.
Eğitimler
Bilgisayar Programcılığı Eyl 2020 - Haz 2022
Example University
Ortalama 3.48/4.00
''', locale: 'ru', isStrictExtraction: true);
    expect(
        result.summary, endsWith('Profesyonel katkılar sunmayı hedefliyorum.'));
    expect(result.summary, isNot(contains('Eğitimler')));
    expect(result.summary.split('\n'), hasLength(6));
    expect(result.educations, hasLength(1));
    expect(result.educations.single.field, 'Bilgisayar Programcılığı');
    expect(result.educations.single.startDate, 'Eyl 2020');
    expect(result.educations.single.endDate, 'Haz 2022');
    expect(result.educations.single.gpa, '3.48/4.00');
  });

  test('Reference appearing first cannot become candidate contact', () async {
    final result = await AiCvService.parseCvPrompt(prompt: '''
Referanslar
Dr. Reference Person
+90 5551112233
reference@example.com
Kişisel bilgiler
Ada Example
candidate@example.com
05350000000
İş deneyimi
Mobil Uygulama Geliştirme Kas 2022 - Oca 2023
Example Company
Mobil uygulamalar geliştirdim.
''', locale: 'tr', isStrictExtraction: true);
    expect(result.email, 'candidate@example.com');
    expect(result.phone, '05350000000');
    expect(result.references, hasLength(1));
    expect(result.references.single.email, 'reference@example.com');
    expect(result.experiences.single.company, 'Example Company');
    expect(result.experiences.single.position, 'Mobil Uygulama Geliştirme');
  });

  test('Every supported locale resolves all new messages', () {
    expect(LocalizationService.supportedLanguages, hasLength(19));
    for (final locale in LocalizationService.supportedLanguages) {
      for (final key in [
        'cv_ai_not_configured',
        'cv_ai_configuration_error',
        'cv_ai_request_failed',
        'cv_ai_busy',
        'cv_ai_file_invalid',
        'cv_ai_summary_updated',
        'cv_ai_local_extraction'
      ]) {
        final text = LocalizationService.trFor(locale.code, key);
        expect(text, isNotEmpty);
        expect(text, isNot(key), reason: '${locale.code}: $key');
        if (!locale.code.startsWith('en')) {
          expect(text, isNot(LocalizationService.trFor('en', key)),
              reason: '${locale.code}: untranslated $key');
        }
      }
    }
  });

  test('Missing AI configuration is explicit', () async {
    await expectLater(
        AiCvService.enhanceSummary(rawSummary: 'Test summary'),
        throwsA(isA<AiCvException>()
            .having((e) => e.messageKey, 'key', 'cv_ai_not_configured')));
  });

  test('Summary uses source language and combines all non-thought parts',
      () async {
    http.Request? captured;
    await http.runWithClient(() async {
      final result = await AiCvService.enhanceSummary(
          rawSummary: 'Mobil uygulama geliştiriyorum.',
          locale: 'de',
          customApiKey: 'test-key');
      expect(result, 'Mobil uygulama geliştirme konusunda deneyimliyim.');
    },
        () => MockClient((request) async {
              captured = request;
              return http.Response(
                  jsonEncode({
                    'candidates': [
                      {
                        'finishReason': 'STOP',
                        'content': {
                          'parts': [
                            {'thought': true, 'text': 'internal'},
                            {'text': 'Mobil uygulama geliştirme '},
                            {'text': 'konusunda deneyimliyim.'}
                          ]
                        }
                      }
                    ]
                  }),
                  200,
                  headers: {'content-type': 'application/json; charset=utf-8'});
            }));
    expect(captured!.url.queryParameters.containsKey('key'), isFalse);
    expect(captured!.headers['x-goog-api-key'], 'test-key');
    final payload = jsonDecode(captured!.body);
    expect(
        payload['contents'][0]['parts'][0]['text'], contains('SAME language'));
  });

  test('PDF bytes and reference schema reach the model; contacts stay separate',
      () async {
    await http.runWithClient(() async {
      final result = await AiCvService.parseCvDocument(
          bytes: Uint8List.fromList([37, 80, 68, 70]),
          mimeType: 'application/pdf',
          customApiKey: 'test-key');
      expect(result.email, isEmpty);
      expect(result.references.single.email, 'reference@example.com');
    },
        () => MockClient((request) async {
              final payload = jsonDecode(request.body);
              expect(
                  payload['contents'][0]['parts'][0]['inlineData']['mimeType'],
                  'application/pdf');
              expect(
                  payload['generationConfig']['response_schema']['properties'],
                  contains('references'));
              return http.Response(
                  jsonEncode({
                    'candidates': [
                      {
                        'finishReason': 'STOP',
                        'content': {
                          'parts': [
                            {
                              'text': jsonEncode({
                                'fullName': 'Ada Example',
                                'email': 'reference@example.com',
                                'references': [
                                  {
                                    'name': 'Reference Person',
                                    'email': 'reference@example.com'
                                  }
                                ]
                              })
                            }
                          ]
                        }
                      }
                    ]
                  }),
                  200);
            }));
  });

  test('Quota and truncated replies do not silently fall back to local parsing',
      () async {
    for (final status in [429, 200]) {
      await http.runWithClient(() async {
        await expectLater(
            AiCvService.parseCvPrompt(
                prompt: 'Ada Example', customApiKey: 'test-key'),
            throwsA(isA<AiCvException>()));
      },
          () => MockClient((_) async => http.Response(
              jsonEncode({
                'candidates': [
                  {
                    'finishReason': 'MAX_TOKENS',
                    'content': {
                      'parts': [
                        {'text': '{}'}
                      ]
                    }
                  }
                ]
              }),
              status)));
    }
  });

  test('Default model no longer targets the retired 1.5 endpoint', () {
    expect(AiConstants.defaultModel, isNot('gemini-1.5-flash'));
  });

  testWidgets('Generate updates the visible summary and saved model',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {'cv_ai_custom_gemini_api_key': 'test-key'});
    LocalizationService.localeNotifier.value = 'en';
    final cv = CvModel.createEmpty()..summary = 'I build mobile apps.';
    await http.runWithClient(() async {
      await tester
          .pumpWidget(MaterialApp(home: CvBuilderScreen(initialCv: cv)));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Tab).at(1));
      await tester.pumpAndSettle();
      final button = find.text(LocalizationService.tr('cv_ai_generate_btn'));
      await tester.scrollUntilVisible(button, 350,
          scrollable: find
              .descendant(
                  of: find.byType(ListView).first,
                  matching: find.byType(Scrollable))
              .first);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(cv.summary, 'Mobile application developer.');
      expect(find.text('Mobile application developer.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
        () => MockClient((_) async => http.Response(
            jsonEncode({
              'candidates': [
                {
                  'finishReason': 'STOP',
                  'content': {
                    'parts': [
                      {'text': 'Mobile application developer.'}
                    ]
                  }
                }
              ]
            }),
            200)));
  });

  testWidgets('New notices fit a narrow phone in all 19 locales',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final lang in LocalizationService.supportedLanguages) {
      final messenger = GlobalKey<ScaffoldMessengerState>();
      await tester.pumpWidget(MaterialApp(
          scaffoldMessengerKey: messenger,
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!),
          home: const Scaffold(body: SizedBox.expand())));
      messenger.currentState!.showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
              LocalizationService.trFor(lang.code, 'cv_ai_request_failed'))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: lang.code);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
