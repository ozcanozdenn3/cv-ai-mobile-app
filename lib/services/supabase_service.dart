import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';
import '../models/cv_model.dart';
import '../models/document_model.dart';
import 'localization_service.dart';

/// OAuth Giriş / Kayıt Sonucu (Apple & Google)
class OAuthSignInResult {
  final bool isSuccess;
  final bool isCancelled;
  final String? errorMessage;
  final AuthResponse? authResponse;
  final String? userId;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  OAuthSignInResult.success({
    this.authResponse,
    this.userId,
    this.email,
    this.displayName,
    this.photoUrl,
  })  : isSuccess = true,
        isCancelled = false,
        errorMessage = null;

  OAuthSignInResult.cancelled()
      : isSuccess = false,
        isCancelled = true,
        authResponse = null,
        errorMessage = null,
        userId = null,
        email = null,
        displayName = null,
        photoUrl = null;

  OAuthSignInResult.failure(this.errorMessage)
      : isSuccess = false,
        isCancelled = false,
        authResponse = null,
        userId = null,
        email = null,
        displayName = null,
        photoUrl = null;
}

/// E-posta ile Kayıt Sonucu
class EmailSignUpResult {
  final bool isSuccess;
  final bool requiresEmailConfirmation;
  final String? errorMessage;
  final User? user;
  final Session? session;

  EmailSignUpResult.success({
    required this.user,
    required this.session,
    required this.requiresEmailConfirmation,
  })  : isSuccess = true,
        errorMessage = null;

  EmailSignUpResult.failure(this.errorMessage)
      : isSuccess = false,
        requiresEmailConfirmation = false,
        user = null,
        session = null;
}

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static SupabaseClient? get client {
    if (_isInitialized) {
      try {
        return Supabase.instance.client;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static User? get currentAuthUser => client?.auth.currentUser;
  static String? get currentUserId => client?.auth.currentUser?.id;
  static bool get isAuthenticated => client?.auth.currentUser != null;

  /// Supabase Client Başlatma (Güvenli ve Hata Korumalı)
  static Future<void> init() async {
    if (!SupabaseConfig.isConfigured) {
      debugPrint('ℹ️ SupabaseConfig henüz yapılandırılmamış. Yerel SharedPreferences modu aktif.');
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: SupabaseConfig.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      _isInitialized = true;
      debugPrint('✅ Supabase başarıyla başlatıldı ve bağlandı.');
    } catch (e) {
      debugPrint('⚠️ Supabase başlatma hatası: $e. Çevrimdışı mod kullanılacak.');
      _isInitialized = false;
    }
  }

  // ===========================================================================
  // 🔐 1. AUTHENTICATION (KİMLİK DOĞRULAMA - EMAIL, GOOGLE, APPLE)
  // ===========================================================================

  /// E-posta & Şifre ile Kayıt Ol (Doğrulama E-postası ve Deep Link Yönlendirmeli)
  static Future<EmailSignUpResult> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    if (!_isInitialized || client == null) {
      return EmailSignUpResult.failure('Supabase bağlantısı henüz hazır değil.');
    }
    try {
      final response = await client!.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
        emailRedirectTo: SupabaseConfig.authCallbackUrl,
      );

      final user = response.user;
      if (user == null) {
        return EmailSignUpResult.failure('Kayıt oluşturulamadı.');
      }

      // Supabase'de e-posta doğrulaması aktifken session null döner
      final bool requiresConfirmation = response.session == null;

      if (!requiresConfirmation) {
        await upsertProfile({
          'id': user.id,
          'email': email,
          'full_name': fullName,
          'is_vip': false,
          'vip_tier': 'free',
        });
      }

      return EmailSignUpResult.success(
        user: user,
        session: response.session,
        requiresEmailConfirmation: requiresConfirmation,
      );
    } catch (e) {
      debugPrint('Supabase signUp error: $e');
      final rawMsg = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
      String userMsg = rawMsg;
      if (rawMsg.contains('over_email_send_rate_limit') || rawMsg.contains('rate limit')) {
        userMsg = LocalizationService.tr('auth_err_rate_limit');
      } else if (rawMsg.contains('User already registered') || rawMsg.contains('already registered')) {
        userMsg = LocalizationService.tr('auth_err_already_registered');
      } else {
        userMsg = LocalizationService.tr('auth_err_generic');
      }
      return EmailSignUpResult.failure(userMsg);
    }
  }

  /// E-posta Doğrulama Linkini Tekrar Gönder (Hata mesajı varsa döner, başarılıysa null döner)
  static Future<String?> resendVerificationEmail(String email) async {
    if (!_isInitialized || client == null) return LocalizationService.tr('auth_err_generic');
    try {
      await client!.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: SupabaseConfig.authCallbackUrl,
      );
      debugPrint('✅ Doğrulama e-postası tekrar gönderildi: $email');
      return null;
    } catch (e) {
      debugPrint('⚠️ Supabase resendVerificationEmail hatası: $e');
      final raw = e.toString();
      if (raw.contains('over_email_send_rate_limit') || raw.contains('rate limit')) {
        return LocalizationService.tr('auth_err_rate_limit');
      }
      return LocalizationService.tr('auth_err_generic');
    }
  }

  /// E-posta & Şifre ile Giriş Yap
  static Future<AuthResponse?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (!_isInitialized || client == null) return null;
    try {
      final response = await client!.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      debugPrint('Supabase signIn error: $e');
      rethrow;
    }
  }

  /// Google ile Giriş / Kayıt Yap (Native ID Token)
  static Future<OAuthSignInResult> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? SupabaseConfig.googleIosClientId
            : null,
        serverClientId: SupabaseConfig.googleWebClientId.isNotEmpty
            ? SupabaseConfig.googleWebClientId
            : null,
        scopes: ['email', 'profile'],
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // Kullanıcı Google oturum açma penceresini kapattı / iptal etti
        debugPrint('Google Sign-In kullanıcı tarafından iptal edildi.');
        return OAuthSignInResult.cancelled();
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      AuthResponse? response;
      if (_isInitialized && client != null && idToken != null) {
        try {
          response = await client!.auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
            accessToken: accessToken,
          );
          if (response.user != null) {
            await upsertProfile({
              'id': response.user!.id,
              'email': response.user!.email ?? googleUser.email,
              'full_name': googleUser.displayName ?? 'Google Kullanıcısı',
              'avatar_url': googleUser.photoUrl,
              'is_vip': false,
              'vip_tier': 'free',
            });
          }
        } catch (supaErr) {
          debugPrint('Supabase Google signInWithIdToken uyarısı: $supaErr (Yerel oturumla devam edilecek)');
        }
      }

      return OAuthSignInResult.success(
        authResponse: response,
        userId: response?.user?.id ?? 'goog_${googleUser.id}',
        email: googleUser.email,
        displayName: googleUser.displayName ?? 'Google Kullanıcısı',
        photoUrl: googleUser.photoUrl,
      );
    } catch (e) {
      debugPrint('Google Sign-In hatası: $e');
      final errStr = e.toString();
      if (errStr.contains('sign_in_canceled') ||
          errStr.contains('canceled') ||
          errStr.contains('cancelled') ||
          errStr.contains('12501')) {
        return OAuthSignInResult.cancelled();
      }
      return OAuthSignInResult.failure(errStr);
    }
  }

  /// Apple ile Giriş / Kayıt Yap (Native ID Token + Nonce)
  static Future<OAuthSignInResult> signInWithApple() async {
    try {
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        return OAuthSignInResult.failure('Apple ile Giriş bu cihazda desteklenmiyor.');
      }

      // Supabase & Apple Güvenlik Standardı: Kriptografik Nonce Üretimi
      String? rawNonce;
      String? hashedNonce;
      if (_isInitialized && client != null) {
        try {
          rawNonce = client!.auth.generateRawNonce();
          hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
        } catch (nonceErr) {
          debugPrint('Apple nonce üretme uyarısı: $nonceErr');
        }
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final appleUserId = credential.userIdentifier ?? 'apple_${DateTime.now().millisecondsSinceEpoch}';
      final nameParts = [credential.givenName, credential.familyName]
          .where((s) => s != null && s.isNotEmpty)
          .join(' ');
      final displayName = nameParts.isNotEmpty ? nameParts : 'Apple Kullanıcısı';
      final email = credential.email ?? '${appleUserId.substring(0, min(8, appleUserId.length))}@privaterelay.appleid.com';

      AuthResponse? response;
      if (_isInitialized && client != null && credential.identityToken != null) {
        try {
          response = await client!.auth.signInWithIdToken(
            provider: OAuthProvider.apple,
            idToken: credential.identityToken!,
            nonce: rawNonce,
          );
          if (response.user != null) {
            await upsertProfile({
              'id': response.user!.id,
              'email': response.user!.email ?? email,
              if (nameParts.isNotEmpty) 'full_name': nameParts,
              'is_vip': false,
              'vip_tier': 'free',
            });
          }
        } catch (supaErr) {
          debugPrint('Supabase Apple signInWithIdToken uyarısı: $supaErr (Yerel oturumla devam edilecek)');
        }
      }

      return OAuthSignInResult.success(
        authResponse: response,
        userId: response?.user?.id ?? appleUserId,
        email: email,
        displayName: displayName,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        debugPrint('Apple Sign-In kullanıcı tarafından iptal edildi.');
        return OAuthSignInResult.cancelled();
      }
      debugPrint('Apple Sign-In authorization hatası: ${e.message} (${e.code})');
      return OAuthSignInResult.failure(e.message);
    } catch (e) {
      debugPrint('Apple Sign-In hatası: $e');
      final errStr = e.toString();
      if (errStr.contains('canceled') || errStr.contains('cancelled')) {
        return OAuthSignInResult.cancelled();
      }
      return OAuthSignInResult.failure(errStr);
    }
  }

  /// Misafir (Anonim) Girişi
  static Future<AuthResponse?> signInAnonymously() async {
    if (!_isInitialized || client == null) return null;
    try {
      final response = await client!.auth.signInAnonymously();
      return response;
    } catch (e) {
      debugPrint('Supabase anonymous sign-in error: $e');
      return null;
    }
  }

  /// Çıkış Yap
  static Future<void> signOut() async {
    if (!_isInitialized || client == null) return;
    try {
      await client!.auth.signOut();
    } catch (e) {
      debugPrint('Supabase signOut error: $e');
    }
  }

  /// Şifre Sıfırlama E-postası Gönder
  static Future<void> resetPassword(String email) async {
    if (!_isInitialized || client == null) return;
    try {
      await client!.auth.resetPasswordForEmail(email);
    } catch (e) {
      debugPrint('Supabase resetPassword error: $e');
      rethrow;
    }
  }

  /// Şifre Güncelle
  static Future<void> updatePassword(String newPassword) async {
    if (!_isInitialized || client == null) return;
    try {
      await client!.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      debugPrint('Supabase updatePassword error: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // 👤 2. PROFILES (KULLANICI PROFİLİ & AYARLARI)
  // ===========================================================================

  /// Kullanıcı Profilini Getir
  static Future<Map<String, dynamic>?> getProfile([String? userId]) async {
    if (!_isInitialized || client == null) return null;
    final uid = userId ?? currentUserId;
    if (uid == null) return null;

    try {
      final data = await client!
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();
      return data;
    } catch (e) {
      debugPrint('Supabase getProfile error: $e');
      return null;
    }
  }

  /// Kullanıcı Profilini Güncelle veya Oluştur
  static Future<void> upsertProfile(Map<String, dynamic> profileData) async {
    if (!_isInitialized || client == null) return;
    final uid = profileData['id'] ?? currentUserId;
    if (uid == null) return;

    try {
      final payload = Map<String, dynamic>.from(profileData);
      payload['id'] = uid;
      payload['updated_at'] = DateTime.now().toIso8601String();

      await client!.from('profiles').upsert(payload);
    } catch (e) {
      debugPrint('Supabase upsertProfile error: $e');
    }
  }

  /// Profil Fotoğrafı Yükle & URL Güncelle
  static Future<String?> uploadAvatar(Uint8List imageBytes, {String? userId}) async {
    if (!_isInitialized || client == null) return null;
    final uid = userId ?? currentUserId;
    if (uid == null) return null;

    try {
      final fileName = 'avatar_${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '$uid/$fileName';

      await client!.storage.from(SupabaseConfig.bucketAvatars).uploadBinary(
            path,
            imageBytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );

      final publicUrl = client!.storage.from(SupabaseConfig.bucketAvatars).getPublicUrl(path);
      await upsertProfile({'id': uid, 'avatar_url': publicUrl});
      return publicUrl;
    } catch (e) {
      debugPrint('Supabase uploadAvatar error: $e');
      return null;
    }
  }

  /// Sayaçları Artır (cv_count, scan_count, conversion_count)
  static Future<void> incrementMetric(String metricColumn) async {
    if (!_isInitialized || client == null) return;
    final uid = currentUserId;
    if (uid == null) return;

    try {
      await client!.rpc('increment_user_metric', params: {
        'user_uuid': uid,
        'metric_type': metricColumn,
      });
    } catch (_) {
      // RPC yoksa manuel güncelle
      try {
        final profile = await getProfile(uid);
        if (profile != null) {
          final currentVal = (profile[metricColumn] as int?) ?? 0;
          await client!.from('profiles').update({
            metricColumn: currentVal + 1,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', uid);
        }
      } catch (err) {
        debugPrint('Manual metric increment error: $err');
      }
    }
  }

  // ===========================================================================
  // 📄 3. RESUMES / CVs (ÖZGEÇMİŞ YÖNETİMİ)
  // ===========================================================================

  /// Kullanıcının Tüm CV'lerini Getir
  static Future<List<CvModel>> fetchResumes([String? userId]) async {
    if (!_isInitialized || client == null) return [];
    final uid = userId ?? currentUserId;
    if (uid == null) return [];

    try {
      final response = await client!
          .from('resumes')
          .select()
          .eq('user_id', uid)
          .order('updated_at', ascending: false);

      final List<CvModel> results = [];
      for (final row in response) {
        results.add(_mapRowToCvModel(row));
      }
      return results;
    } catch (e) {
      debugPrint('Supabase fetchResumes error: $e');
      return [];
    }
  }

  /// Aktif CV'yi Getir
  static Future<CvModel?> fetchActiveResume([String? userId]) async {
    if (!_isInitialized || client == null) return null;
    final uid = userId ?? currentUserId;
    if (uid == null) return null;

    try {
      final response = await client!
          .from('resumes')
          .select()
          .eq('user_id', uid)
          .eq('is_active', true)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return _mapRowToCvModel(response);
      }
    } catch (e) {
      debugPrint('Supabase fetchActiveResume error: $e');
    }
    return null;
  }

  /// CV'yi Supabase Veritabanına Kaydet / Güncelle
  static Future<void> saveResume(CvModel cv, {Uint8List? pdfBytes, Uint8List? photoBytes}) async {
    if (!_isInitialized || client == null) return;
    final uid = currentUserId;
    if (uid == null) return;

    try {
      String? uploadedPdfUrl;
      String? uploadedPhotoUrl;

      // PDF Dosyasını Storage'a yükle
      if (pdfBytes != null) {
        try {
          final pdfPath = '$uid/resumes/${cv.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
          await client!.storage.from(SupabaseConfig.bucketResumes).uploadBinary(
                pdfPath,
                pdfBytes,
                fileOptions: const FileOptions(contentType: 'application/pdf', upsert: true),
              );
          uploadedPdfUrl = client!.storage.from(SupabaseConfig.bucketResumes).getPublicUrl(pdfPath);
        } catch (err) {
          debugPrint('Resume PDF storage upload error: $err');
        }
      }

      // Vesikalık Fotoğrafı Storage'a yükle
      if (photoBytes != null || cv.profilePhotoBytes != null) {
        final bytes = photoBytes ?? cv.profilePhotoBytes;
        if (bytes != null) {
          try {
            final photoPath = '$uid/photos/${cv.id}_photo.jpg';
            await client!.storage.from(SupabaseConfig.bucketResumes).uploadBinary(
                  photoPath,
                  bytes,
                  fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
                );
            uploadedPhotoUrl = client!.storage.from(SupabaseConfig.bucketResumes).getPublicUrl(photoPath);
          } catch (err) {
            debugPrint('Resume photo storage upload error: $err');
          }
        }
      }

      final payload = _cvModelToRow(cv, uid, pdfUrl: uploadedPdfUrl, photoUrl: uploadedPhotoUrl);
      await client!.from('resumes').upsert(payload);
      await incrementMetric('cv_count');
      debugPrint('✅ CV başarıyla Supabase bulutuna kaydedildi: ${cv.fullName}');
    } catch (e) {
      debugPrint('Supabase saveResume error: $e');
    }
  }

  /// CV Sil
  static Future<void> deleteResume(String resumeId) async {
    if (!_isInitialized || client == null) return;
    try {
      await client!.from('resumes').delete().eq('id', resumeId);
    } catch (e) {
      debugPrint('Supabase deleteResume error: $e');
    }
  }

  // ===========================================================================
  // 📁 4. DOCUMENTS ARCHIVE (BELGE ARŞİVİ & DÖNÜŞTÜRÜCÜ)
  // ===========================================================================

  /// Arşivdeki Belgeleri Getir
  static Future<List<DocumentModel>> fetchDocuments([String? userId]) async {
    if (!_isInitialized || client == null) return [];
    final uid = userId ?? currentUserId;
    if (uid == null) return [];

    try {
      final response = await client!
          .from('documents')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      return response.map((row) => _mapRowToDocumentModel(row)).toList();
    } catch (e) {
      debugPrint('Supabase fetchDocuments error: $e');
      return [];
    }
  }

  /// Belgeyi Supabase'e Kaydet
  static Future<void> saveDocument(DocumentModel doc, {Uint8List? fileBytes}) async {
    if (!_isInitialized || client == null) return;
    final uid = currentUserId;
    if (uid == null) return;

    try {
      String? fileUrl;
      if (fileBytes != null) {
        final ext = doc.title.contains('.') ? doc.title.split('.').last : 'pdf';
        final storagePath = '$uid/documents/${doc.id}_${doc.title}';
        await client!.storage.from(SupabaseConfig.bucketDocuments).uploadBinary(
              storagePath,
              fileBytes,
              fileOptions: FileOptions(
                contentType: ext == 'docx' ? 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' : 'application/pdf',
                upsert: true,
              ),
            );
        fileUrl = client!.storage.from(SupabaseConfig.bucketDocuments).getPublicUrl(storagePath);
      }

      final payload = {
        'id': doc.id,
        'user_id': uid,
        'title': doc.title,
        'document_type': doc.type.name,
        'file_size': doc.fileSize,
        'page_count': doc.pageCount,
        'file_url': fileUrl,
        'preview_image_url': doc.previewImage,
        'created_at': doc.createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await client!.from('documents').upsert(payload);
      await incrementMetric('conversion_count');
    } catch (e) {
      debugPrint('Supabase saveDocument error: $e');
    }
  }

  /// Belgeyi Sil
  static Future<void> deleteDocument(String documentId) async {
    if (!_isInitialized || client == null) return;
    try {
      await client!.from('documents').delete().eq('id', documentId);
    } catch (e) {
      debugPrint('Supabase deleteDocument error: $e');
    }
  }

  // ===========================================================================
  // 📸 5. CAMSCANNER SCANS (HD BELGE TARAMALARI)
  // ===========================================================================

  /// Tarama Belgelerini Getir
  static Future<List<Map<String, dynamic>>> fetchScans([String? userId]) async {
    if (!_isInitialized || client == null) return [];
    final uid = userId ?? currentUserId;
    if (uid == null) return [];

    try {
      final response = await client!
          .from('scans')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Supabase fetchScans error: $e');
      return [];
    }
  }

  /// Tarama Belgesi Kaydet
  static Future<void> saveScan({
    required String id,
    required String title,
    required String mode,
    required String filterApplied,
    required int pageCount,
    String? extractedOcrText,
    List<Map<String, dynamic>>? pagesData,
    Uint8List? pdfBytes,
  }) async {
    if (!_isInitialized || client == null) return;
    final uid = currentUserId;
    if (uid == null) return;

    try {
      String? pdfUrl;
      if (pdfBytes != null) {
        final path = '$uid/scans/${id}_$title.pdf';
        await client!.storage.from(SupabaseConfig.bucketScans).uploadBinary(
              path,
              pdfBytes,
              fileOptions: const FileOptions(contentType: 'application/pdf', upsert: true),
            );
        pdfUrl = client!.storage.from(SupabaseConfig.bucketScans).getPublicUrl(path);
      }

      final payload = {
        'id': id,
        'user_id': uid,
        'title': title,
        'mode': mode,
        'filter_applied': filterApplied,
        'page_count': pageCount,
        'extracted_ocr_text': extractedOcrText,
        'pages_data': pagesData ?? [],
        'pdf_url': pdfUrl,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await client!.from('scans').upsert(payload);
      await incrementMetric('scan_count');
    } catch (e) {
      debugPrint('Supabase saveScan error: $e');
    }
  }

  // ===========================================================================
  // 🔍 6. OCR HISTORY (AKILLI METİN AYRIŞTIRMA GEÇMİŞİ)
  // ===========================================================================

  /// OCR Geçmişini Getir
  static Future<List<Map<String, dynamic>>> fetchOcrHistory([String? userId]) async {
    if (!_isInitialized || client == null) return [];
    final uid = userId ?? currentUserId;
    if (uid == null) return [];

    try {
      final response = await client!
          .from('ocr_history')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Supabase fetchOcrHistory error: $e');
      return [];
    }
  }

  /// OCR Metni Kaydet
  static Future<void> saveOcrExtraction({
    required String text,
    String? sourceFilename,
    String? language,
  }) async {
    if (!_isInitialized || client == null) return;
    final uid = currentUserId;
    if (uid == null) return;

    try {
      final words = text.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
      final payload = {
        'user_id': uid,
        'source_filename': sourceFilename ?? 'Belge Fotoğrafı',
        'extracted_text': text,
        'character_count': text.length,
        'word_count': words,
        'language_detected': language ?? 'auto',
        'created_at': DateTime.now().toIso8601String(),
      };

      await client!.from('ocr_history').insert(payload);
    } catch (e) {
      debugPrint('Supabase saveOcrExtraction error: $e');
    }
  }

  // ===========================================================================
  // 💬 7. SUPPORT TICKETS (YARDIM & DESTEK MESAJLARI)
  // ===========================================================================

  /// Destek Talebi / Geri Bildirim Gönder
  static Future<void> submitSupportTicket({
    required String subject,
    required String message,
    String? email,
    int? rating,
  }) async {
    if (!_isInitialized || client == null) return;
    try {
      final payload = {
        'user_id': currentUserId,
        'user_email': email ?? currentAuthUser?.email,
        'subject': subject,
        'message': message,
        'rating': rating,
        'status': 'open',
        'created_at': DateTime.now().toIso8601String(),
      };
      await client!.from('support_tickets').insert(payload);
    } catch (e) {
      debugPrint('Supabase submitSupportTicket error: $e');
    }
  }

  // ===========================================================================
  // 🔄 HELPER SERIALIZERS (CV & DOCUMENT MODEL DÖNÜŞTÜRÜCÜLER)
  // ===========================================================================

  static Map<String, dynamic> _cvModelToRow(CvModel cv, String userId, {String? pdfUrl, String? photoUrl}) {
    return {
      'id': cv.id,
      'user_id': userId,
      'title': cv.fullName.isNotEmpty ? '${cv.fullName} - ${cv.jobTitle}' : 'Özgeçmişim',
      'full_name': cv.fullName,
      'job_title': cv.jobTitle,
      'email': cv.email,
      'phone': cv.phone,
      'location': cv.location,
      'summary': cv.summary,
      'linkedin': cv.linkedin,
      'github': cv.github,
      'portfolio_url': cv.portfolioUrl,
      'has_photo': cv.hasPhoto,
      'profile_photo_url': photoUrl,
      'primary_color_hex': cv.primaryColorHex,
      'template_name': cv.template.name,
      'personal_traits': cv.personalTraits,
      'experiences': cv.experiences
          .map((e) => {
                'company': e.company,
                'position': e.position,
                'startDate': e.startDate,
                'endDate': e.endDate,
                'isCurrent': e.isCurrent,
                'description': e.description,
              })
          .toList(),
      'educations': cv.educations
          .map((e) => {
                'school': e.school,
                'degree': e.degree,
                'field': e.field,
                'startDate': e.startDate,
                'endDate': e.endDate,
                'gpa': e.gpa,
              })
          .toList(),
      'skills': cv.skills
          .map((s) => {
                'name': s.name,
                'level': s.level,
                'levelLabel': s.levelLabel,
              })
          .toList(),
      'languages': cv.languages
          .map((l) => {
                'language': l.language,
                'level': l.level,
              })
          .toList(),
      'references_data': cv.references
          .map((r) => {
                'name': r.name,
                'position': r.position,
                'company': r.company,
                'phone': r.phone,
                'email': r.email,
              })
          .toList(),
      'projects': cv.projects
          .map((p) => {
                'name': p.name,
                'role': p.role,
                'link': p.link,
                'date': p.date,
                'description': p.description,
                'technologies': p.technologies,
              })
          .toList(),
      'certificates': cv.certificates
          .map((c) => {
                'name': c.name,
                'issuer': c.issuer,
                'date': c.date,
                'credentialUrl': c.credentialUrl,
              })
          .toList(),
      'section_order': cv.sectionOrder.map((s) => s.name).toList(),
      'ats_score': cv.calculateAtsScore(),
      'is_active': true,
      'pdf_url': pdfUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  static CvModel _mapRowToCvModel(Map<String, dynamic> row) {
    Uint8List? photoBytes;
    if (row['profile_photo_base64'] != null) {
      try {
        photoBytes = base64Decode(row['profile_photo_base64'] as String);
      } catch (_) {}
    }

    final cv = CvModel(
      id: row['id'] as String? ?? 'cv_1',
      fullName: row['full_name'] as String? ?? '',
      jobTitle: row['job_title'] as String? ?? '',
      email: row['email'] as String? ?? '',
      phone: row['phone'] as String? ?? '',
      location: row['location'] as String? ?? '',
      summary: row['summary'] as String? ?? '',
      linkedin: row['linkedin'] as String? ?? '',
      github: row['github'] as String? ?? '',
      portfolioUrl: row['portfolio_url'] as String? ?? '',
      hasPhoto: row['has_photo'] as bool? ?? true,
      profilePhotoBytes: photoBytes,
      primaryColorHex: (row['primary_color_hex'] as num?)?.toInt() ?? 0xFF2563EB,
      template: CvTemplate.values.firstWhere(
        (t) => t.name == row['template_name'],
        orElse: () => CvTemplate.sidebarModern,
      ),
      personalTraits: (row['personal_traits'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      experiences: (row['experiences'] as List<dynamic>?)
              ?.map((e) => WorkExperience(
                    company: e['company'] as String? ?? '',
                    position: e['position'] as String? ?? '',
                    startDate: e['startDate'] as String? ?? '',
                    endDate: e['endDate'] as String? ?? '',
                    isCurrent: e['isCurrent'] as bool? ?? false,
                    description: e['description'] as String? ?? '',
                  ))
              .toList() ??
          [],
      educations: (row['educations'] as List<dynamic>?)
              ?.map((e) => Education(
                    school: e['school'] as String? ?? '',
                    degree: e['degree'] as String? ?? '',
                    field: e['field'] as String? ?? '',
                    startDate: e['startDate'] as String? ?? '',
                    endDate: e['endDate'] as String? ?? '',
                    gpa: e['gpa'] as String? ?? '',
                  ))
              .toList() ??
          [],
      skills: (row['skills'] as List<dynamic>?)
              ?.map((s) => SkillItem(
                    name: s['name'] as String? ?? '',
                    level: s['level'] as int? ?? 80,
                    levelLabel: s['levelLabel'] as String? ?? 'İleri Düzey',
                  ))
              .toList() ??
          [],
      languages: (row['languages'] as List<dynamic>?)
              ?.map((l) => LanguageItem(
                    language: l['language'] as String? ?? '',
                    level: l['level'] as String? ?? '',
                  ))
              .toList() ??
          [],
      references: (row['references_data'] as List<dynamic>?)
              ?.map((r) => ReferenceItem(
                    name: r['name'] as String? ?? '',
                    position: r['position'] as String? ?? '',
                    company: r['company'] as String? ?? '',
                    phone: r['phone'] as String? ?? '',
                    email: r['email'] as String? ?? '',
                  ))
              .toList() ??
          [],
      projects: (row['projects'] as List<dynamic>?)
              ?.map((p) => ProjectItem(
                    name: p['name'] as String? ?? '',
                    role: p['role'] as String? ?? '',
                    link: p['link'] as String? ?? '',
                    date: p['date'] as String? ?? '',
                    description: p['description'] as String? ?? '',
                    technologies: p['technologies'] as String? ?? '',
                  ))
              .toList() ??
          [],
      certificates: (row['certificates'] as List<dynamic>?)
              ?.map((c) => CertificateItem(
                    name: c['name'] as String? ?? '',
                    issuer: c['issuer'] as String? ?? '',
                    date: c['date'] as String? ?? '',
                    credentialUrl: c['credentialUrl'] as String? ?? '',
                  ))
              .where((c) =>
                  !(c.name.contains('Google Certified Associate Android Developer') ||
                    c.credentialUrl.contains('verify.google.com/cert/12345')))
              .toList() ??
          [],
    );

    if (row['section_order'] != null) {
      final orderList = (row['section_order'] as List<dynamic>)
          .map((s) => CvSectionType.values.firstWhere(
                (sec) => sec.name == s,
                orElse: () => CvSectionType.summary,
              ))
          .toList();
      cv.sectionOrder = orderList;
    }

    return cv;
  }

  static DocumentModel _mapRowToDocumentModel(Map<String, dynamic> row) {
    return DocumentModel(
      id: row['id'] as String? ?? 'doc_1',
      title: row['title'] as String? ?? 'Belge.pdf',
      type: DocumentType.values.firstWhere(
        (t) => t.name == row['document_type'],
        orElse: () => DocumentType.cv,
      ),
      createdAt: row['created_at'] != null
          ? DateTime.tryParse(row['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      pageCount: row['page_count'] as int? ?? 1,
      fileSize: row['file_size'] as String? ?? '250 KB',
      previewImage: row['preview_image_url'] as String?,
      fileUrl: row['file_url'] as String?,
    );
  }
}
