import 'package:flutter/foundation.dart';

class ConfigService {
  // Supabase configuration - SECURITY: Never expose API keys in production
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // Development configuration from environment only
  static const String devSupabaseUrl = String.fromEnvironment(
    'DEV_SUPABASE_URL',
    defaultValue: '',
  );

  static const String devSupabaseAnonKey = String.fromEnvironment(
    'DEV_SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // Security validation
  static bool get isConfigValid {
    return supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty &&
        supabaseUrl.startsWith('https://') &&
        supabaseAnonKey.length > 20;
  }

  static bool get isDevConfigValid {
    return devSupabaseUrl.isNotEmpty &&
        devSupabaseAnonKey.isNotEmpty &&
        devSupabaseUrl.startsWith('https://') &&
        devSupabaseAnonKey.length > 20;
  }

  // Get secure configuration
  static String get secureSupabaseUrl {
    if (supabaseUrl.isNotEmpty) return supabaseUrl;
    if (!isProduction && kDebugMode && isDevConfigValid) return devSupabaseUrl;
    throw Exception(
      'SECURITY ERROR: Supabase URL not configured. Set SUPABASE_URL environment variable.',
    );
  }

  static String get secureSupabaseAnonKey {
    if (supabaseAnonKey.isNotEmpty) return supabaseAnonKey;
    if (!isProduction && kDebugMode && isDevConfigValid) {
      return devSupabaseAnonKey;
    }
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
    };
  }
}
