import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseServices {
  static SupabaseClient get _supabase => Supabase.instance.client;

  // Sign up a new user with email/password and store user details
  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = authResponse.user;

      if (user != null) {
        // Insert into custom "user" table
        await _supabase.from('user').insert({
          'uid': user.id,
          'email': email,
          'name': name,
          'role': role,
          'created_at': DateTime.now().toIso8601String(),
        });

        return {
          'success': true,
          'user': user,
          'uid': user.id,
          'email': email,
          'name': name,
          'role': role,
        };
      } else {
        return {
          'success': false,
          'error': 'User creation failed',
        };
      }
    } on AuthException catch (e) {
      return {
        'success': false,
        'error': e.message,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Sign in with email and password
  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      print("Login response --- $response");
      print("login response data --- ${response.user}");

      if (response.user != null) {
        // Fetch user details from database
        final userDetails = await getUserDetails(response.user!.id);
        if (userDetails != null) {
          return {
            'success': true,
            'user': response.user,
            'uid': response.user!.id,
            'email': userDetails['email'],
            'name': userDetails['name'],
            'role': userDetails['role'],
          };
        } else {
          print("Login failed else 1 ---");
          return {
            'success': false,
            'error': 'User details not found in database',
          };
        }
      } else {
        print("Login failed else 2 ---");
        return {
          'success': false,
          'error': 'Login failed',
        };
      }
    } on AuthException catch (e) {
      print("Login auth exc. error --- $e");
      return {
        'success': false,
        'error': e.message,
      };
    } catch (e) {
      print("Login catch error --- $e");
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Sign out current user
  static Future<Map<String, dynamic>> signOut() async {
    try {
      await _supabase.auth.signOut();
      return {
        'success': true,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get current user session
  static User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  // Get current session
  static Session? getCurrentSession() {
    return _supabase.auth.currentSession;
  }

  // Check if user is logged in
  static bool isLoggedIn() {
    return _supabase.auth.currentUser != null;
  }

  static Future<Map<String, dynamic>?> getUserDetails(String uid) async {
    try {
      final response =
      await _supabase.from('user').select().eq('uid', uid).maybeSingle();
      return response;
    } catch (e) {
      print('Error fetching user details: $e');
      return null;
    }
  }


  // Get user details by email
  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final response =
          await _supabase.from('user').select().eq('email', email).single();

      return response;
    } catch (e) {
      print('Error fetching user by email: $e');
      return null;
    }
  }

  // Update user details
  static Future<Map<String, dynamic>> updateUserDetails({
    required String uid,
    String? name,
    String? role,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (role != null) updateData['role'] = role;

      await _supabase.from('user').update(updateData).eq('uid', uid);

      return {
        'success': true,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Check if user has specific role
  static Future<bool> checkUserRole(String uid, String expectedRole) async {
    try {
      final userDetails = await getUserDetails(uid);
      if (userDetails != null) {
        return userDetails['role'] == expectedRole;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
