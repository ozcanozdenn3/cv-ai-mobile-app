import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription_model.dart';
import 'supabase_service.dart';
import 'localization_service.dart';

enum AuthProviderType { email, google, apple, guest }

class UserModel {
  final String id;
  String fullName;
  String email;
  String? avatarUrl;
  bool isPro;
  AuthProviderType provider;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    this.isPro = false,
    this.provider = AuthProviderType.email,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'avatarUrl': avatarUrl,
        'isPro': isPro,
        'provider': provider.name,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String? ?? 'usr_1',
        fullName: json['fullName'] as String? ?? LocalizationService.tr('auth_user'),
        email: json['email'] as String? ?? 'kullanici@cvai.app',
        avatarUrl: json['avatarUrl'] as String?,
        isPro: json['isPro'] as bool? ?? false,
        provider: AuthProviderType.values.firstWhere(
          (p) => p.name == json['provider'],
          orElse: () => AuthProviderType.email,
        ),
      );
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _userPrefsKey = 'cv_ai_active_user_session';
  static const String _subscriptionPrefsKey = 'cv_ai_active_subscription_info';

  static StreamSubscription<AuthState>? _authStateSubscription;

  static final ValueNotifier<UserModel?> currentUserNotifier = ValueNotifier<UserModel?>(null);

  static final ValueNotifier<SubscriptionInfo?> activeSubscriptionNotifier =
      ValueNotifier<SubscriptionInfo?>(null);

  static UserModel? get currentUser => currentUserNotifier.value;
  static SubscriptionInfo? get activeSubscription => activeSubscriptionNotifier.value;
  static bool get isLoggedIn => currentUserNotifier.value != null;

  /// Uygulama başlarken kullanıcı oturumunu ve abonelik geçerlilik süresini denetler
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Önce kayıtlı abonelik bilgisini ve geçerliliğini kontrol et
      await checkSubscriptionExpiry();

      final hasPurchasedVip = prefs.getBool('cv_ai_has_purchased_vip') ?? false;

      // 2. Supabase Deep Link & Auth State Listener (Her zaman aktif dinler)
      if (SupabaseService.isInitialized && SupabaseService.client != null) {
        _authStateSubscription?.cancel();
        _authStateSubscription = SupabaseService.client!.auth.onAuthStateChange.listen((data) async {
          final event = data.event;
          final session = data.session;
          debugPrint('🔔 Supabase onAuthStateChange: $event (user: ${session?.user.email})');

          if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.userUpdated) {
            if (session?.user != null) {
              final authUser = session!.user;
              final profile = await SupabaseService.getProfile(authUser.id);
              final user = UserModel(
                id: authUser.id,
                fullName: profile?['full_name'] ??
                    authUser.userMetadata?['full_name'] ??
                    authUser.email?.split('@').first.toUpperCase() ??
                    LocalizationService.tr('auth_user'),
                email: authUser.email ?? 'user@cvai.app',
                avatarUrl: profile?['avatar_url'],
                isPro: profile?['is_vip'] ?? false,
                provider: AuthProviderType.email,
              );
              currentUserNotifier.value = user;
              await _persistUser(user);
              debugPrint('✅ Supabase oturumu otomatik açıldı ve kaydedildi: ${user.email}');
            }
          } else if (event == AuthChangeEvent.signedOut) {
            currentUserNotifier.value = null;
          }
        });
      }

      // 3. Eğer Supabase bağlı ve aktif oturum varsa
      if (SupabaseService.isInitialized && SupabaseService.currentAuthUser != null) {
        final authUser = SupabaseService.currentAuthUser!;
        final profile = await SupabaseService.getProfile(authUser.id);
        
        final bool isVipFromProfile = (profile?['is_vip'] as bool?) ?? false;
        final String? expiresAtStr = profile?['vip_expires_at'] as String?;
        bool isProActive = isVipFromProfile;

        // Buluttaki süre kontrolü
        if (expiresAtStr != null) {
          final expDate = DateTime.tryParse(expiresAtStr);
          if (expDate != null && DateTime.now().isAfter(expDate)) {
            isProActive = false;
            // Supabase süresi dolmuşsa bulutta güncelle
            await SupabaseService.upsertProfile({
              'id': authUser.id,
              'is_vip': false,
              'vip_tier': 'free',
              'vip_status': 'expired',
            });
          }
        }

        final user = UserModel(
          id: authUser.id,
          fullName: profile?['full_name'] ?? authUser.userMetadata?['full_name'] ?? LocalizationService.tr('auth_user'),
          email: authUser.email ?? 'user@cvai.app',
          avatarUrl: profile?['avatar_url'],
          isPro: isProActive && (activeSubscriptionNotifier.value?.isValid ?? isProActive),
          provider: AuthProviderType.email,
        );
        currentUserNotifier.value = user;
        await _persistUser(user);
        return;
      }

      // 4. Yerel Kayıtlı Kullanıcı Oturumu (Cache)
      final isSubValid = activeSubscriptionNotifier.value?.isValid ?? false;
      final jsonStr = prefs.getString(_userPrefsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> map = json.decode(jsonStr) as Map<String, dynamic>;
        final user = UserModel.fromJson(map);
        user.isPro = isSubValid && hasPurchasedVip;
        currentUserNotifier.value = user;
      } else {
        currentUserNotifier.value = null;
      }
    } catch (e) {
      debugPrint('AuthService init error: $e');
    }
  }

  /// Aboneliğin süresini kontrol eder ve süresi bitmişse anında PRO durumunu iptal eder
  static Future<bool> checkSubscriptionExpiry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final subJson = prefs.getString(_subscriptionPrefsKey);
      
      if (subJson != null && subJson.isNotEmpty) {
        final map = json.decode(subJson) as Map<String, dynamic>;
        final sub = SubscriptionInfo.fromJson(map);
        
        if (!sub.isValid) {
          // SÜRESİ BİTMİŞ VEYA İPTAL EDİLMİŞ!
          debugPrint('⚠️ Abonelik süresi doldu veya iptal edildi. PRO yetkileri geri alınıyor.');
          final expiredSub = sub.copyWith(status: SubscriptionStatus.expired, autoRenew: false);
          await prefs.setString(_subscriptionPrefsKey, json.encode(expiredSub.toJson()));
          await prefs.setBool('cv_ai_has_purchased_vip', false);
          activeSubscriptionNotifier.value = expiredSub;

          final user = currentUserNotifier.value;
          if (user != null && user.isPro) {
            final updatedUser = UserModel(
              id: user.id,
              fullName: user.fullName,
              email: user.email,
              avatarUrl: user.avatarUrl,
              isPro: false,
              provider: user.provider,
            );
            currentUserNotifier.value = updatedUser;
            await _persistUser(updatedUser);
          }

          if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
            final uid = SupabaseService.currentUserId;
            if (uid != null) {
              await SupabaseService.upsertProfile({
                'id': uid,
                'is_vip': false,
                'vip_tier': 'free',
                'vip_status': 'expired',
              });
            }
          }
          return false;
        } else {
          // Aktif ve Geçerli Abonelik
          activeSubscriptionNotifier.value = sub;
          await prefs.setBool('cv_ai_has_purchased_vip', true);
          return true;
        }
      } else {
        activeSubscriptionNotifier.value = null;
        return false;
      }
    } catch (e) {
      debugPrint('checkSubscriptionExpiry error: $e');
      return false;
    }
  }

  static Future<void> _persistUser(UserModel? user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (user != null) {
        await prefs.setString(_userPrefsKey, json.encode(user.toJson()));
      } else {
        await prefs.remove(_userPrefsKey);
      }
    } catch (e) {
      debugPrint('AuthService persist error: $e');
    }
  }

  /// PRO Üyeliğe Yükseltme (Seçilen Pakete Göre Süre Ataması Yapar)
  static Future<void> upgradeToPro({SubscriptionTier tier = SubscriptionTier.yearly}) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    DateTime? expiresAt;

    switch (tier) {
      case SubscriptionTier.weekly:
        expiresAt = now.add(const Duration(days: 7));
        break;
      case SubscriptionTier.monthly:
        expiresAt = now.add(const Duration(days: 30));
        break;
      case SubscriptionTier.yearly:
        expiresAt = now.add(const Duration(days: 365));
        break;
      case SubscriptionTier.unlimited:
        expiresAt = null; // Sınırsız
        break;
    }

    final newSub = SubscriptionInfo(
      tier: tier,
      startDate: now,
      expiresAt: expiresAt,
      autoRenew: tier != SubscriptionTier.unlimited,
      status: SubscriptionStatus.active,
    );

    await prefs.setString(_subscriptionPrefsKey, json.encode(newSub.toJson()));
    await prefs.setBool('cv_ai_has_purchased_vip', true);
    activeSubscriptionNotifier.value = newSub;

    final current = currentUserNotifier.value;
    if (current != null) {
      final updatedUser = UserModel(
        id: current.id,
        fullName: current.fullName,
        email: current.email,
        avatarUrl: current.avatarUrl,
        isPro: true,
        provider: current.provider,
      );
      currentUserNotifier.value = updatedUser;
      await _persistUser(updatedUser);

      if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
        await SupabaseService.upsertProfile({
          'id': current.id,
          'is_vip': true,
          'vip_tier': tier.name,
          'vip_expires_at': expiresAt?.toIso8601String(),
          'vip_status': 'active',
        });
      }
    } else {
      final newUser = UserModel(
        id: SupabaseService.currentUserId ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
        fullName: LocalizationService.tr('auth_user'),
        email: 'user@cvai.app',
        isPro: true,
      );
      currentUserNotifier.value = newUser;
      await _persistUser(newUser);
    }
  }

  /// Aboneliği İptal Et (Kullanıcı İptal Ettiği An Yetkiler Geri Alınır)
  static Future<void> cancelSubscription() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentSub = activeSubscriptionNotifier.value;

      final cancelledSub = (currentSub ?? SubscriptionInfo(
        tier: SubscriptionTier.yearly,
        startDate: DateTime.now(),
      )).copyWith(
        status: SubscriptionStatus.cancelled,
        autoRenew: false,
      );

      await prefs.setString(_subscriptionPrefsKey, json.encode(cancelledSub.toJson()));
      await prefs.setBool('cv_ai_has_purchased_vip', false);
      activeSubscriptionNotifier.value = cancelledSub;

      final current = currentUserNotifier.value;
      if (current != null) {
        final updatedUser = UserModel(
          id: current.id,
          fullName: current.fullName,
          email: current.email,
          avatarUrl: current.avatarUrl,
          isPro: false,
          provider: current.provider,
        );
        currentUserNotifier.value = updatedUser;
        await _persistUser(updatedUser);

        if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
          await SupabaseService.upsertProfile({
            'id': current.id,
            'is_vip': false,
            'vip_tier': 'free',
            'vip_status': 'cancelled',
            'vip_cancelled_at': DateTime.now().toIso8601String(),
          });
        }
      }
      debugPrint('🛑 Abonelik başarıyla iptal edildi ve PRO yetkileri kapatıldı.');
    } catch (e) {
      debugPrint('cancelSubscription error: $e');
    }
  }

  /// E-posta ve Şifre ile Giriş
  static Future<bool> loginWithEmail({
    required String emailOrUsername,
    required String password,
  }) async {
    if (emailOrUsername.trim().isEmpty || password.trim().isEmpty) {
      throw Exception(LocalizationService.tr('auth_enter_credentials'));
    }

    final email = emailOrUsername.contains('@') ? emailOrUsername.trim() : '${emailOrUsername.trim()}@cvai.app';

    // Supabase aktifse gerçek Supabase Auth ile giriş yap
    if (SupabaseService.isInitialized) {
      try {
        final res = await SupabaseService.signInWithEmail(email: email, password: password);
        if (res?.user != null) {
          final profile = await SupabaseService.getProfile(res!.user!.id);
          final user = UserModel(
            id: res.user!.id,
            fullName: profile?['full_name'] ?? res.user!.userMetadata?['full_name'] ?? email.split('@').first.toUpperCase(),
            email: email,
            avatarUrl: profile?['avatar_url'],
            isPro: profile?['is_vip'] ?? false,
            provider: AuthProviderType.email,
          );
          currentUserNotifier.value = user;
          await _persistUser(user);
          return true;
        } else {
          throw Exception(LocalizationService.tr('auth_err_invalid_credentials'));
        }
      } catch (err) {
        debugPrint('Supabase login error: $err');
        final errStr = err.toString();
        if (errStr.contains('Email not confirmed')) {
          throw Exception(LocalizationService.tr('auth_err_email_not_confirmed'));
        } else if (errStr.contains('Invalid login credentials')) {
          throw Exception(LocalizationService.tr('auth_err_invalid_credentials'));
        }
        throw Exception(localizeAuthError(err));
      }
    }

    throw Exception(LocalizationService.tr('auth_err_generic'));
  }

  /// Kimlik Doğrulama Hatalarını 19 Desteklenen Dile Yerelleştir
  static String localizeAuthError(dynamic err) {
    if (err == null) return LocalizationService.tr('auth_err_generic');
    final errStr = err.toString().toLowerCase();
    if (errStr.contains('email not confirmed') || errStr.contains('not_confirmed')) {
      return LocalizationService.tr('auth_err_email_not_confirmed');
    } else if (errStr.contains('invalid login credentials') ||
        errStr.contains('invalid_credentials') ||
        errStr.contains('hatalı') ||
        errStr.contains('invalid email or password')) {
      return LocalizationService.tr('auth_err_invalid_credentials');
    } else if (errStr.contains('user already registered') ||
        errStr.contains('already registered') ||
        errStr.contains('already exists') ||
        errStr.contains('zaten kayıt')) {
      return LocalizationService.tr('auth_err_already_registered');
    } else if (errStr.contains('over_email_send_rate_limit') ||
        errStr.contains('rate limit') ||
        errStr.contains('too many')) {
      return LocalizationService.tr('auth_err_rate_limit');
    } else if (errStr.contains('password') &&
        (errStr.contains('length') || errStr.contains('least 6') || errStr.contains('6 karakter'))) {
      return LocalizationService.tr('auth_password_length');
    } else if (errStr.contains('mismatch') || errStr.contains('eşleşmiyor')) {
      return LocalizationService.tr('auth_err_password_mismatch');
    } else if (errStr.contains('terms') || errStr.contains('şartlar')) {
      return LocalizationService.tr('auth_accept_terms');
    } else if (errStr.contains('fill') || errStr.contains('doldurun') || errStr.contains('required')) {
      return LocalizationService.tr('auth_err_fill_all');
    }
    return LocalizationService.tr('auth_err_generic');
  }

  /// Yeni Hesap Kaydı (Doğrulama E-postası Destekli)
  static Future<bool> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
    required bool acceptedTerms,
    void Function(bool requiresEmailConfirmation)? onConfirmationRequired,
  }) async {
    if (!acceptedTerms) {
      throw Exception(LocalizationService.tr('auth_accept_terms'));
    }

    if (fullName.trim().isEmpty || email.trim().isEmpty || password.trim().isEmpty) {
      throw Exception(LocalizationService.tr('auth_err_fill_all'));
    }

    if (password.length < 6) {
      throw Exception(LocalizationService.tr('auth_password_length'));
    }

    // Supabase aktifse gerçek Supabase Auth ile kaydol
    if (SupabaseService.isInitialized) {
      final res = await SupabaseService.signUpWithEmail(
        email: email.trim(),
        password: password,
        fullName: fullName.trim(),
      );

      if (!res.isSuccess) {
        throw Exception(res.errorMessage ?? LocalizationService.tr('auth_err_generic'));
      }

      if (res.requiresEmailConfirmation) {
        debugPrint('✉️ Supabase e-posta doğrulaması bekliyor: $email');
        onConfirmationRequired?.call(true);
        return false; // Oturum henüz açılmadı, onay bekleniyor
      }

      // E-posta onayı gerekmeyen doğrudan oturum
      final user = UserModel(
        id: res.user!.id,
        fullName: fullName.trim(),
        email: email.trim(),
        isPro: false,
        provider: AuthProviderType.email,
      );
      currentUserNotifier.value = user;
      await _persistUser(user);
      onConfirmationRequired?.call(false);
      return true;
    }

    throw Exception(LocalizationService.tr('auth_err_generic'));
  }

  /// Google ile Giriş / Kayıt
  static Future<bool> signInWithGoogle() async {
    try {
      final res = await SupabaseService.signInWithGoogle();

      if (res.isCancelled) {
        debugPrint('Google Sign-In iptal edildi.');
        return false;
      }

      if (!res.isSuccess) {
        if (res.errorMessage != null) {
          throw Exception(res.errorMessage);
        }
        return false;
      }

      // Kullanıcı doğrulandı (Supabase ve/veya Yerel)
      bool isVip = false;
      if (res.authResponse?.user != null) {
        final profile = await SupabaseService.getProfile(res.authResponse!.user!.id);
        isVip = profile?['is_vip'] ?? false;
      }

      final user = UserModel(
        id: res.userId ?? 'goog_${DateTime.now().millisecondsSinceEpoch}',
        fullName: res.displayName ?? LocalizationService.tr('auth_google_user'),
        email: res.email ?? 'user@gmail.com',
        avatarUrl: res.photoUrl,
        isPro: isVip,
        provider: AuthProviderType.google,
      );

      currentUserNotifier.value = user;
      await _persistUser(user);
      return true;
    } catch (e) {
      debugPrint('AuthService signInWithGoogle error: $e');
      rethrow;
    }
  }

  /// Apple ile Giriş / Kayıt
  static Future<bool> signInWithApple() async {
    try {
      final res = await SupabaseService.signInWithApple();

      if (res.isCancelled) {
        debugPrint('Apple Sign-In iptal edildi.');
        return false;
      }

      if (!res.isSuccess) {
        if (res.errorMessage != null) {
          throw Exception(res.errorMessage);
        }
        return false;
      }

      // Kullanıcı doğrulandı (Supabase ve/veya Yerel)
      bool isVip = false;
      if (res.authResponse?.user != null) {
        final profile = await SupabaseService.getProfile(res.authResponse!.user!.id);
        isVip = profile?['is_vip'] ?? false;
      }

      final user = UserModel(
        id: res.userId ?? 'apple_${DateTime.now().millisecondsSinceEpoch}',
        fullName: res.displayName ?? LocalizationService.tr('auth_apple_user'),
        email: res.email ?? 'user@privaterelay.appleid.com',
        avatarUrl: res.photoUrl,
        isPro: isVip,
        provider: AuthProviderType.apple,
      );

      currentUserNotifier.value = user;
      await _persistUser(user);
      return true;
    } catch (e) {
      debugPrint('AuthService signInWithApple error: $e');
      rethrow;
    }
  }

  /// Misafir Girişi
  static Future<void> continueAsGuest() async {
    if (SupabaseService.isInitialized) {
      await SupabaseService.signInAnonymously();
    }

    final user = UserModel(
      id: SupabaseService.currentUserId ?? 'guest_${DateTime.now().millisecondsSinceEpoch}',
      fullName: LocalizationService.tr('auth_guest_user'),
      email: 'misafir@cvai.app',
      isPro: false,
      provider: AuthProviderType.guest,
    );
    currentUserNotifier.value = user;
    await _persistUser(user);
  }

  /// Profil Bilgilerini Güncelle
  static Future<void> updateProfile({
    String? fullName,
    String? email,
    String? avatarUrl,
  }) async {
    final current = currentUserNotifier.value;
    if (current != null) {
      if (fullName != null && fullName.trim().isNotEmpty) current.fullName = fullName.trim();
      if (email != null && email.trim().isNotEmpty) current.email = email.trim();
      if (avatarUrl != null) current.avatarUrl = avatarUrl;
      currentUserNotifier.value = current;
      await _persistUser(current);

      if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
        await SupabaseService.upsertProfile({
          'id': current.id,
          if (fullName != null) 'full_name': current.fullName,
          if (email != null) 'email': current.email,
          if (avatarUrl != null) 'avatar_url': current.avatarUrl,
        });
      }
    }
  }

  /// Çıkış Yap
  static Future<void> logout() async {
    if (SupabaseService.isInitialized) {
      await SupabaseService.signOut();
    }
    currentUserNotifier.value = null;
    await _persistUser(null);
  }

  /// Hesabı Kalıcı Olarak Sil
  static Future<void> deleteAccount() async {
    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      try {
        final uid = SupabaseService.currentUserId;
        if (uid != null) {
          await SupabaseService.client?.from('profiles').delete().eq('id', uid);
        }
        await SupabaseService.signOut();
      } catch (e) {
        debugPrint('Supabase delete account error: $e');
      }
    }
    currentUserNotifier.value = null;
    await _persistUser(null);
  }
}
