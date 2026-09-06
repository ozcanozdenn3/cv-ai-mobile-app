// ==============================================================================
// 🚀 SUPABASE CONFIGURATION & CONSTANTS
// ==============================================================================
// Supabase projenizi bağlamak için aşağıdaki URL ve Anon Key değerlerini
// Supabase Dashboard -> Project Settings -> API kısmından kopyalayıp buraya yapıştırın.
// ==============================================================================

class SupabaseConfig {
  /// Supabase Project URL
  static const String supabaseUrl = 'https://efyyriclhlthpdkwexbj.supabase.co';

  /// Supabase Anon / Publishable Key
  static const String supabaseAnonKey = 'sb_publishable_XY-x6VcWpxRs0eaq7ph7Lw_vhRjLRn0';

  /// Supabase bağlı mı kontrolü
  static bool get isConfigured =>
      supabaseUrl.startsWith('https://') && supabaseAnonKey.isNotEmpty;

  /// Google OAuth Web Client ID (Supabase Dashboard -> Auth -> Providers -> Google ile eşleşen Web Client ID)
  static const String googleWebClientId =
      '617214485526-dps3thvlqsa3l1t2rckn42oo6m9at1t8.apps.googleusercontent.com';

  /// Google iOS Client ID (Google Cloud Console iOS Client ID)
  static const String googleIosClientId =
      '617214485526-drv5rlpdhfnoigbcp6uq6i2hqs7gkrdq.apps.googleusercontent.com';

  /// OAuth Deep Link Redirect URL
  static const String authCallbackUrl = 'io.supabase.cvai://login-callback';

  // Supabase Storage Bucket İsimleri
  static const String bucketResumes = 'resumes';
  static const String bucketDocuments = 'documents';
  static const String bucketScans = 'scans';
  static const String bucketAvatars = 'avatars';
}

