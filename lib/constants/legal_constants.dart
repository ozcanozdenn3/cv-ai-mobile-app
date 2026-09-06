import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalConstants {
  /// Flycricket GDPR Privacy Policy URL (Hem iOS hem Android için resmi canlı link)
  static const String privacyPolicyUrl =
      'https://doc-hosting.flycricket.io/cv-ai-studio-privacy-policy/f82246a0-edad-4ca0-b1f7-7070b7c6f0a6/privacy';

  /// Apple Standard EULA (Terms of Use) - Apple App Store Guideline 3.1.2 resmi gereksinimi
  static const String appleStandardEulaUrl =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

  /// Flycricket Terms of Use (Android ve genel platformlar için resmi link)
  static const String termsOfUseUrl =
      'https://doc-hosting.flycricket.io/cv-ai-studio-terms-of-use/ffd6d9bc-a87c-4eb3-ba7c-064a2abeabad/terms';

  /// Platforma göre doğru Kullanım Şartları linki (iOS ise Apple EULA, Android ise Flycricket Terms)
  static String get platformTermsUrl {
    if (!kIsWeb && Platform.isIOS) {
      return appleStandardEulaUrl;
    }
    return termsOfUseUrl;
  }

  /// Gizlilik Politikasını harici tarayıcıda açar
  static Future<bool> openPrivacyPolicy() async {
    try {
      final uri = Uri.parse(privacyPolicyUrl);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching privacy policy: $e');
      return false;
    }
  }

  /// Platforma uygun Kullanım Şartlarını harici tarayıcıda açar
  static Future<bool> openTermsOfUse() async {
    try {
      final uri = Uri.parse(platformTermsUrl);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching terms: $e');
      return false;
    }
  }

  /// Apple Standart EULA linkini doğrudan açar
  static Future<bool> openAppleEula() async {
    try {
      final uri = Uri.parse(appleStandardEulaUrl);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching Apple EULA: $e');
      return false;
    }
  }
}
