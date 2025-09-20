import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Get current authenticated user
  static User? get currentUser => _supabase.auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Get current user ID
  static String? get currentUserId => currentUser?.id;

  /// Register new user
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? idCardNumber,
  }) async {
    try {
      if (kDebugMode) {
        print('Attempting to register new user');
      }

      // Validate input
      if (email.isEmpty || password.isEmpty || fullName.isEmpty) {
        return {
          'success': false,
          'error': 'validation_error',
          'message': 'Email, password, and full name are required',
        };
      }

      if (password.length < 6) {
        return {
          'success': false,
          'error': 'password_too_short',
          'message': 'Password must be at least 6 characters long',
        };
      }

      // Register with Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'id_card_number': idCardNumber,
        },
      );

      if (response.user == null) {
        return {
          'success': false,
          'error': 'registration_failed',
          'message': 'Failed to create user account',
        };
      }

      if (kDebugMode) {
        print('User registered successfully');
      }

      // Create student profile in database
      final profileResult = await _createStudentProfile(
        response.user!,
        fullName,
        phone,
        idCardNumber,
      );

      if (!profileResult['success']) {
        if (kDebugMode) {
          print('Profile creation failed: ${profileResult['message']}');
        }
        // Don't fail registration if profile creation fails - can be retried later
      }

      return {
        'success': true,
        'message':
            'Registration successful. Please check your email for verification.',
        'user': response.user,
        'needs_email_verification': response.user!.emailConfirmedAt == null,
      };
    } on AuthException catch (e) {
      if (kDebugMode) {
        print('Registration auth error: ${e.message}');
      }

      String userMessage = 'Registration failed. Please try again.';
      if (e.message.contains('already registered') ||
          e.message.contains('already exists')) {
        userMessage =
            'This email is already registered. Please try signing in.';
      } else if (e.message.contains('invalid email')) {
        userMessage = 'Please enter a valid email address.';
      } else if (e.message.contains('weak password')) {
        userMessage =
            'Password is too weak. Please choose a stronger password.';
      }

      return {'success': false, 'error': 'auth_error', 'message': userMessage};
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected registration error: $e');
      }

      return {
        'success': false,
        'error': 'unexpected_error',
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  /// Sign in existing user
  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        print('Attempting to sign in user');
      }

      // Validate input
      if (email.isEmpty || password.isEmpty) {
        return {
          'success': false,
          'error': 'validation_error',
          'message': 'Email and password are required',
        };
      }

      // Sign in with Supabase Auth
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return {
          'success': false,
          'error': 'signin_failed',
          'message': 'Failed to sign in',
        };
      }

      if (kDebugMode) {
        print('User signed in successfully: ${response.user!.id}');
        print('Email confirmed: ${response.user!.emailConfirmedAt != null}');
      }

      // Update last login timestamp and ensure profile exists
      await _updateLastLogin(response.user!.id);

      // Ensure student profile exists (in case it was missing from registration)
      await ensureStudentProfile();

      return {
        'success': true,
        'message': 'Sign in successful',
        'user': response.user,
        'needs_email_verification': response.user!.emailConfirmedAt == null,
      };
    } on AuthException catch (e) {
      if (kDebugMode) {
        print('Sign in auth error: ${e.message}');
      }

      String userMessage = 'Sign in failed. Please check your credentials.';
      if (e.message.contains('invalid credentials') ||
          e.message.contains('Invalid login')) {
        userMessage = 'Invalid email or password. Please try again.';
      } else if (e.message.contains('email not confirmed')) {
        userMessage = 'Please verify your email address before signing in.';
      }

      return {'success': false, 'error': 'auth_error', 'message': userMessage};
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected sign in error: $e');
      }

      return {
        'success': false,
        'error': 'unexpected_error',
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  /// Sign out current user
  static Future<Map<String, dynamic>> signOut() async {
    try {
      await _supabase.auth.signOut();

      // Clear only user-specific preferences, keep app settings like theme and locale
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = AuthService.currentUserId;
      if (currentUserId != null) {
        // Clear user-specific completion data
        await prefs.remove('registration_completed_$currentUserId');
        await prefs.remove('documents_completed_$currentUserId');
        await prefs.remove('completed_items_$currentUserId');
      }
      // Also clear any legacy non-user-specific completion data
      await prefs.remove('registration_completed');
      await prefs.remove('documents_completed');
      await prefs.remove('completed_items');

      if (kDebugMode) {
        print('User signed out successfully');
      }

      return {'success': true, 'message': 'Signed out successfully'};
    } catch (e) {
      if (kDebugMode) {
        print('Sign out error: $e');
      }

      return {
        'success': false,
        'error': 'signout_error',
        'message': 'Failed to sign out. Please try again.',
      };
    }
  }

  /// Reset password
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
  }) async {
    try {
      if (email.isEmpty) {
        return {
          'success': false,
          'error': 'validation_error',
          'message': 'Email is required',
        };
      }

      await _supabase.auth.resetPasswordForEmail(email);

      return {
        'success': true,
        'message': 'Password reset email sent. Please check your inbox.',
      };
    } on AuthException catch (e) {
      if (kDebugMode) {
        print('Password reset error: ${e.message}');
      }

      return {
        'success': false,
        'error': 'auth_error',
        'message': 'Failed to send password reset email. Please try again.',
      };
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected password reset error: $e');
      }

      return {
        'success': false,
        'error': 'unexpected_error',
        'message': 'Failed to send password reset email. Please try again.',
      };
    }
  }

  /// Update user password
  static Future<Map<String, dynamic>> updatePassword({
    required String newPassword,
  }) async {
    try {
      if (!isAuthenticated) {
        return {
          'success': false,
          'error': 'not_authenticated',
          'message': 'Please sign in to update your password',
        };
      }

      if (newPassword.length < 6) {
        return {
          'success': false,
          'error': 'password_too_short',
          'message': 'Password must be at least 6 characters long',
        };
      }

      await _supabase.auth.updateUser(UserAttributes(password: newPassword));

      return {'success': true, 'message': 'Password updated successfully'};
    } on AuthException catch (e) {
      if (kDebugMode) {
        print('Password update error: ${e.message}');
      }

      return {
        'success': false,
        'error': 'auth_error',
        'message': 'Failed to update password. Please try again.',
      };
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected password update error: $e');
      }

      return {
        'success': false,
        'error': 'unexpected_error',
        'message': 'Failed to update password. Please try again.',
      };
    }
  }

  /// Get current user profile
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      if (!isAuthenticated) {
        return null;
      }

      final profile = await _supabase
          .from('dormitory_students')
          .select('*')
          .eq('auth_user_id', currentUserId!)
          .maybeSingle();

      return profile;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user profile: $e');
      }
      return null;
    }
  }

  /// Update user profile
  static Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? phone,
    String? idCardNumber,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      if (!isAuthenticated) {
        return {
          'success': false,
          'error': 'not_authenticated',
          'message': 'Please sign in to update your profile',
        };
      }

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) {
        final nameParts = fullName.split(' ');
        updateData['name'] = nameParts.isNotEmpty ? nameParts.first : '';
        updateData['family_name'] = nameParts.length > 1
            ? nameParts.skip(1).join(' ')
            : '';
      }
      if (phone != null) updateData['phone'] = phone;
      if (idCardNumber != null) updateData['id_card_number'] = idCardNumber;
      if (additionalData != null) updateData.addAll(additionalData);

      await _supabase
          .from('dormitory_students')
          .update(updateData)
          .eq('auth_user_id', currentUserId!);

      // Also update auth metadata if name changed
      if (fullName != null) {
        await _supabase.auth.updateUser(
          UserAttributes(data: {'full_name': fullName}),
        );
      }

      return {'success': true, 'message': 'Profile updated successfully'};
    } catch (e) {
      if (kDebugMode) {
        print('Profile update error: $e');
      }

      return {
        'success': false,
        'error': 'update_error',
        'message': 'Failed to update profile. Please try again.',
      };
    }
  }

  /// Delete user account
  static Future<Map<String, dynamic>> deleteAccount() async {
    try {
      if (!isAuthenticated) {
        return {
          'success': false,
          'error': 'not_authenticated',
          'message': 'Please sign in to delete your account',
        };
      }

      final userId = currentUserId!;

      // Delete user data from database (cascade will handle related tables)
      await _supabase
          .from('dormitory_students')
          .delete()
          .eq('auth_user_id', userId);

      // Sign out user
      await signOut();

      return {'success': true, 'message': 'Account deleted successfully'};
    } catch (e) {
      if (kDebugMode) {
        print('Account deletion error: $e');
      }

      return {
        'success': false,
        'error': 'deletion_error',
        'message': 'Failed to delete account. Please contact support.',
      };
    }
  }

  /// Get auth state changes stream
  static Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  /// Check if user email is confirmed
  static bool get isEmailConfirmed => currentUser?.emailConfirmedAt != null;

  /// Try to establish session if user was previously authenticated
  static Future<Map<String, dynamic>> tryEstablishSession() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null && isAuthenticated) {
        // Update last login
        await _updateLastLogin(currentUserId!);

        // Ensure profile exists
        await ensureStudentProfile();

        return {
          'success': true,
          'message': 'Session established',
          'user': currentUser,
        };
      }

      return {
        'success': false,
        'error': 'no_session',
        'message': 'No active session found',
      };
    } catch (e) {
      if (kDebugMode) {
        print('Session establishment error: $e');
      }

      return {
        'success': false,
        'error': 'session_error',
        'message': 'Failed to establish session',
      };
    }
  }

  /// Resend email verification
  static Future<Map<String, dynamic>> resendEmailVerification() async {
    try {
      if (!isAuthenticated) {
        return {
          'success': false,
          'error': 'not_authenticated',
          'message': 'Please sign in to resend verification email',
        };
      }

      if (isEmailConfirmed) {
        return {
          'success': false,
          'error': 'already_verified',
          'message': 'Email is already verified',
        };
      }

      final email = currentUser!.email;
      if (email == null) {
        return {
          'success': false,
          'error': 'no_email',
          'message': 'No email address found for current user',
        };
      }

      await _supabase.auth.resend(type: OtpType.signup, email: email);

      return {
        'success': true,
        'message': 'Verification email sent. Please check your inbox.',
      };
    } catch (e) {
      if (kDebugMode) {
        print('Resend verification error: $e');
      }

      return {
        'success': false,
        'error': 'resend_error',
        'message': 'Failed to resend verification email. Please try again.',
      };
    }
  }

  /// Ensure student profile exists (create if missing or update if needed)
  static Future<Map<String, dynamic>> ensureStudentProfile({
    String? fullName,
    String? phone,
    String? idCardNumber,
  }) async {
    try {
      if (!isAuthenticated) {
        return {
          'success': false,
          'error': 'not_authenticated',
          'message': 'User not authenticated',
        };
      }

      final user = currentUser!;
      final userId = user.id;

      // Check if profile exists
      final existing = await _supabase
          .from('dormitory_students')
          .select('*')
          .eq('auth_user_id', userId)
          .maybeSingle();

      if (existing == null) {
        // Create new profile
        final nameParts = (fullName ?? user.userMetadata?['full_name'] ?? '')
            .split(' ');
        await _supabase.from('dormitory_students').insert({
          'auth_user_id': userId,
          'email': user.email,
          'name': nameParts.isNotEmpty ? nameParts.first : '',
          'family_name': nameParts.length > 1
              ? nameParts.skip(1).join(' ')
              : '',
          'phone': phone ?? user.userMetadata?['phone'],
          'id_card_number':
              idCardNumber ?? user.userMetadata?['id_card_number'],
          'created_at': DateTime.now().toIso8601String(),
          'application_status': 'draft',
        });

        if (kDebugMode) {
          print('Student profile created for user: $userId');
        }
      } else {
        // Update last access time
        await _supabase
            .from('dormitory_students')
            .update({'updated_at': DateTime.now().toIso8601String()})
            .eq('auth_user_id', userId);

        if (kDebugMode) {
          print('Student profile exists, updated timestamp: $userId');
        }
      }

      return {'success': true, 'message': 'Profile ensured'};
    } catch (e) {
      if (kDebugMode) {
        print('Error ensuring student profile: $e');
      }

      return {
        'success': false,
        'error': 'profile_ensure_error',
        'message': 'Failed to ensure profile exists',
      };
    }
  }

  /// Create student profile in database
  static Future<Map<String, dynamic>> _createStudentProfile(
    User user,
    String fullName,
    String? phone,
    String? idCardNumber,
  ) async {
    try {
      // First check if profile already exists
      final existing = await _supabase
          .from('dormitory_students')
          .select('id')
          .eq('auth_user_id', user.id)
          .maybeSingle();

      if (existing != null) {
        if (kDebugMode) {
          print('Student profile already exists for user: ${user.id}');
        }
        return {'success': true, 'message': 'Profile already exists'};
      }

      // Create new profile
      final nameParts = fullName.split(' ');
      await _supabase.from('dormitory_students').insert({
        'auth_user_id': user.id,
        'email': user.email,
        'name': nameParts.isNotEmpty ? nameParts.first : '',
        'family_name': nameParts.length > 1 ? nameParts.skip(1).join(' ') : '',
        'phone': phone,
        'id_card_number': idCardNumber,
        'created_at': DateTime.now().toIso8601String(),
        'application_status': 'draft',
      });

      return {'success': true, 'message': 'Profile created successfully'};
    } catch (e) {
      if (kDebugMode) {
        print('Profile creation error: $e');
        print('Error type: ${e.runtimeType}');
        print('User ID: ${user.id}');
        print('User email: ${user.email}');
      }

      // Check if it's a duplicate key error (profile might have been created in parallel)
      if (e.toString().contains('duplicate') ||
          e.toString().contains('unique')) {
        if (kDebugMode) {
          print(
            'Profile creation failed due to duplicate - likely already exists',
          );
        }
        return {'success': true, 'message': 'Profile exists or created'};
      }

      return {
        'success': false,
        'error': 'profile_creation_error',
        'message': 'Failed to create user profile. Please try again.',
      };
    }
  }

  /// Update last login timestamp
  static Future<void> _updateLastLogin(String userId) async {
    try {
      await _supabase
          .from('dormitory_students')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('auth_user_id', userId);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to update last login: $e');
      }
      // Non-critical error, don't throw
    }
  }

  /// Check if email is already registered
  static Future<bool> isEmailRegistered(String email) async {
    try {
      final result = await _supabase
          .from('dormitory_students')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      return result != null;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking email registration: $e');
      }
      return false;
    }
  }

  /// Get user statistics
  static Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      if (!isAuthenticated) {
        return {
          'total_documents': 0,
          'application_status': 'not_authenticated',
          'profile_completion': 0,
        };
      }

      final userId = currentUserId!;

      // Get the student record first to get the proper student_id for documents
      final studentRecord = await _supabase
          .from('dormitory_students')
          .select('id')
          .eq('auth_user_id', userId)
          .maybeSingle();

      if (studentRecord == null) {
        return {
          'total_documents': 0,
          'application_status': 'no_profile',
          'profile_completion': 0,
        };
      }

      final studentId = studentRecord['id'];

      // Get document count using the student ID
      final documents = await _supabase
          .from('student_documents')
          .select('id')
          .eq('student_id', studentId);

      // Get profile info
      final profile = await getCurrentUserProfile();

      final profileCompletion = _calculateProfileCompletion(profile);

      return {
        'total_documents': documents.length,
        'application_status': profile?['application_status'] ?? 'draft',
        'profile_completion': profileCompletion,
        'created_at': profile?['created_at'],
        'updated_at': profile?['updated_at'],
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user statistics: $e');
      }

      return {
        'total_documents': 0,
        'application_status': 'error',
        'profile_completion': 0,
      };
    }
  }

  /// Calculate profile completion percentage
  static int _calculateProfileCompletion(Map<String, dynamic>? profile) {
    if (profile == null) return 0;

    int completedFields = 0;
    const totalFields = 6; // Adjust based on required fields

    if (profile['name']?.toString().isNotEmpty == true) completedFields++;
    if (profile['family_name']?.toString().isNotEmpty == true) {
      completedFields++;
    }
    if (profile['email']?.toString().isNotEmpty == true) completedFields++;
    if (profile['phone']?.toString().isNotEmpty == true) completedFields++;
    if (profile['id_card_number']?.toString().isNotEmpty == true) {
      completedFields++;
    }
    if (profile['university']?.toString().isNotEmpty == true) {
      completedFields++;
    }

    return ((completedFields / totalFields) * 100).round();
  }
}
