import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/services/localization_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Permission & Voice Localization for 19 Languages', () {
    final permissionKeys = [
      'perm_mic_title',
      'perm_mic_desc',
      'perm_camera_title',
      'perm_camera_desc',
      'perm_gallery_title',
      'perm_gallery_desc',
      'perm_open_settings',
      'perm_cancel',
    ];

    final voiceKeys = [
      'cv_ai_voice_btn',
      'cv_ai_voice_title',
      'cv_ai_voice_subtitle',
      'cv_ai_voice_listening',
      'cv_ai_voice_stop',
      'cv_ai_voice_apply',
      'cv_ai_prompt_placeholder',
      'cv_ai_badge_generated',
      'cv_ai_typing',
    ];

    test('All 19 supported languages have localized permission strings', () {
      expect(LocalizationService.supportedLanguages.length, 19);

      final turkishPermMicTitle = LocalizationService.trFor('tr', 'perm_mic_title');
      final turkishPermMicDesc = LocalizationService.trFor('tr', 'perm_mic_desc');
      final turkishSettings = LocalizationService.trFor('tr', 'perm_open_settings');
      final turkishCancel = LocalizationService.trFor('tr', 'perm_cancel');

      expect(turkishPermMicTitle, 'Mikrofon İzni Gerekli');
      expect(turkishSettings, 'Ayarları Aç');
      expect(turkishCancel, 'Vazgeç');

      for (final lang in LocalizationService.supportedLanguages) {
        final code = lang.code;

        for (final key in permissionKeys) {
          final translated = LocalizationService.trFor(code, key);

          // Must not be empty or untranslated key
          expect(translated, isNotEmpty);
          expect(translated, isNot(equals(key)));

          // For non-Turkish languages, Turkish texts must NOT leak!
          if (code != 'tr') {
            expect(
              translated,
              isNot(equals(turkishPermMicTitle)),
              reason: '$key in $code leaked Turkish title!',
            );
            expect(
              translated,
              isNot(equals(turkishPermMicDesc)),
              reason: '$key in $code leaked Turkish description!',
            );
            expect(
              translated,
              isNot(equals(turkishSettings)),
              reason: '$key in $code leaked Turkish settings button!',
            );
            expect(
              translated,
              isNot(equals(turkishCancel)),
              reason: '$key in $code leaked Turkish cancel button!',
            );
          }
        }
      }
    });

    test('All 19 languages have localized voice assistant strings', () {
      final turkishVoiceBtn = LocalizationService.trFor('tr', 'cv_ai_voice_btn');
      final turkishVoiceTitle = LocalizationService.trFor('tr', 'cv_ai_voice_title');

      for (final lang in LocalizationService.supportedLanguages) {
        final code = lang.code;
        for (final key in voiceKeys) {
          final translated = LocalizationService.trFor(code, key);
          expect(translated, isNotEmpty, reason: '$key was empty in $code');
          expect(translated, isNot(equals(key)), reason: '$key untranslated in $code');

          if (code != 'tr') {
            expect(
              translated,
              isNot(equals(turkishVoiceBtn)),
              reason: '$key leaked Turkish in $code',
            );
            expect(
              translated,
              isNot(equals(turkishVoiceTitle)),
              reason: '$key leaked Turkish in $code',
            );
          }
        }
      }
    });
  });
}
