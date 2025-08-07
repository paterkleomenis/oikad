class ConfigService {
  // Supabase configuration - SECURITY: Never expose API keys in production
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '', // Remove default for security
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '', // Remove default for security
  );

  // Security validation
  static bool get isConfigValid {
    return supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty &&
        supabaseUrl.startsWith('https://') &&
        supabaseAnonKey.length > 20; // Basic validation
  }

  // Development fallbacks (only for development builds)
  static const String _devSupabaseUrl =
      'https://hontvzogixrfxjqsfkny.supabase.co';
  static const String _devSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhvbnR2em9naXhyZnhqcXNma255Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE5OTQ4MDUsImV4cCI6MjA2NzU3MDgwNX0.UaOMTWerS4mS4orxuOREeA4xSQEc7H_gPGSFFgl6cLg';

  // Get secure configuration
  static String get secureSupabaseUrl {
    if (supabaseUrl.isNotEmpty) return supabaseUrl;
    if (!isProduction && enableDebugMode) return _devSupabaseUrl;
    throw Exception(
      'SECURITY ERROR: Supabase URL not configured. Set SUPABASE_URL environment variable.',
    );
  }

  static String get secureSupabaseAnonKey {
    if (supabaseAnonKey.isNotEmpty) return supabaseAnonKey;
    if (!isProduction && enableDebugMode) return _devSupabaseAnonKey;
    throw Exception(
      'SECURITY ERROR: Supabase API key not configured. Set SUPABASE_ANON_KEY environment variable.',
    );
  }

  // App configuration
  static const bool isProduction = bool.fromEnvironment(
    'DART_DEFINE_PRODUCTION',
    defaultValue: false,
  );

  static const bool enableDebugMode = bool.fromEnvironment(
    'DEBUG_MODE',
    defaultValue: true,
  );

  // Security configuration
  static const int maxRegistrationAttempts = int.fromEnvironment(
    'MAX_REGISTRATION_ATTEMPTS',
    defaultValue: 3,
  );

  static const Duration rateLimitWindow = Duration(
    minutes: int.fromEnvironment('RATE_LIMIT_MINUTES', defaultValue: 15),
  );

  static const int maxInputLength = int.fromEnvironment(
    'MAX_INPUT_LENGTH',
    defaultValue: 255,
  );

  static const Duration sessionTimeout = Duration(
    hours: int.fromEnvironment('SESSION_TIMEOUT_HOURS', defaultValue: 24),
  );

  // Animation durations for performance optimization
  static const Duration fastAnimationDuration = Duration(milliseconds: 200);
  static const Duration normalAnimationDuration = Duration(milliseconds: 300);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);

  // UI constants
  static const double defaultBorderRadius = 12.0;
  static const double cardBorderRadius = 20.0;
  static const double defaultPadding = 16.0;
  static const double largePadding = 24.0;
  static const double smallPadding = 8.0;

  // Database timeouts
  static const Duration shortTimeout = Duration(seconds: 10);
  static const Duration normalTimeout = Duration(seconds: 30);
  static const Duration longTimeout = Duration(minutes: 2);

  // Security validation methods
  static void validateSecurity() {
    if (isProduction && !isConfigValid) {
      throw Exception(
        'SECURITY ERROR: Production environment requires valid configuration',
      );
    }
  }

  // Log security configuration (without exposing sensitive data)
  static Map<String, dynamic> getSecurityInfo() {
    return {
      'isProduction': isProduction,
      'debugMode': enableDebugMode,
      'configValid': isConfigValid,
      'urlConfigured': supabaseUrl.isNotEmpty,
      'keyConfigured': supabaseAnonKey.isNotEmpty,
      'maxAttempts': maxRegistrationAttempts,
      'rateLimitMinutes': rateLimitWindow.inMinutes,
    };
  }
}
