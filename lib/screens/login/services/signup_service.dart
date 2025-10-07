import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class SignupService {
  static const String _registeredUsersKey = 'registered_users';
  static const String _userProfilesKey = 'user_profiles';

  // Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate password
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  // Validate phone number
  static bool isValidPhone(String phone) {
    return RegExp(r'^\+?[\d\s\-\(\)]{10,}$').hasMatch(phone);
  }

  // Validate name
  static bool isValidName(String name) {
    return name.trim().length >= 2;
  }

  // Check if email already exists
  static Future<bool> emailExists(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final registeredUsers = prefs.getString(_registeredUsersKey);

      if (registeredUsers != null) {
        final users = jsonDecode(registeredUsers) as Map<String, dynamic>;
        return users.containsKey(email.toLowerCase());
      }
      return false;
    } catch (e) {
      debugPrint('Error checking email existence: $e');
      return false;
    }
  }

  // Register new user
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      // Check if email already exists
      if (await emailExists(email)) {
        return {'success': false, 'message': 'Email already registered'};
      }

      final prefs = await SharedPreferences.getInstance();

      // Get existing registered users
      final registeredUsersData = prefs.getString(_registeredUsersKey);
      Map<String, dynamic> registeredUsers = {};
      if (registeredUsersData != null) {
        registeredUsers = jsonDecode(registeredUsersData);
      }

      // Get existing user profiles
      final userProfilesData = prefs.getString(_userProfilesKey);
      Map<String, dynamic> userProfiles = {};
      if (userProfilesData != null) {
        userProfiles = jsonDecode(userProfilesData);
      }

      // Generate user ID
      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      final userEmail = email.toLowerCase();

      // Store user credentials
      registeredUsers[userEmail] = {
        'password': password,
        'userId': userId,
        'userType': 'customer', // Only customers can sign up
      };

      // Store user profile
      userProfiles[userId] = {
        'id': userId,
        'name': name.trim(),
        'email': userEmail,
        'phone': phone.trim(),
        'userType': 'customer',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Save to local storage
      await prefs.setString(_registeredUsersKey, jsonEncode(registeredUsers));
      await prefs.setString(_userProfilesKey, jsonEncode(userProfiles));

      return {
        'success': true,
        'message': 'Registration successful',
        'user': userProfiles[userId],
      };
    } catch (e) {
      debugPrint('Registration error: $e');
      return {
        'success': false,
        'message': 'Registration failed. Please try again.',
      };
    }
  }

  // Authenticate registered user
  static Future<Map<String, dynamic>> authenticateRegisteredUser({
    required String email,
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final registeredUsersData = prefs.getString(_registeredUsersKey);
      final userProfilesData = prefs.getString(_userProfilesKey);

      if (registeredUsersData == null || userProfilesData == null) {
        return {'success': false, 'message': 'No registered users found'};
      }

      final registeredUsers =
          jsonDecode(registeredUsersData) as Map<String, dynamic>;
      final userProfiles = jsonDecode(userProfilesData) as Map<String, dynamic>;

      final userEmail = email.toLowerCase();
      final userCredentials = registeredUsers[userEmail];

      if (userCredentials == null || userCredentials['password'] != password) {
        return {'success': false, 'message': 'Invalid email or password'};
      }

      final userId = userCredentials['userId'];
      final userProfile = userProfiles[userId];

      if (userProfile == null) {
        return {'success': false, 'message': 'User profile not found'};
      }

      // Generate session token
      final token = _generateToken(userEmail, userId);

      return {
        'success': true,
        'user': {
          ...userProfile,
          'token': token,
          'loginTime': DateTime.now().toIso8601String(),
        },
        'message': 'Login successful',
      };
    } catch (e) {
      debugPrint('Authentication error: $e');
      return {'success': false, 'message': 'Authentication failed'};
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userProfilesData = prefs.getString(_userProfilesKey);

      if (userProfilesData == null) {
        return {'success': false, 'message': 'User profile not found'};
      }

      final userProfiles = jsonDecode(userProfilesData) as Map<String, dynamic>;
      final userProfile = userProfiles[userId];

      if (userProfile == null) {
        return {'success': false, 'message': 'User profile not found'};
      }

      // Check if email is being changed and if it already exists
      if (userProfile['email'] != email.toLowerCase()) {
        if (await emailExists(email)) {
          return {'success': false, 'message': 'Email already registered'};
        }
      }

      // Update profile
      userProfiles[userId] = {
        ...userProfile,
        'name': name.trim(),
        'email': email.toLowerCase(),
        'phone': phone.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Save updated profiles
      await prefs.setString(_userProfilesKey, jsonEncode(userProfiles));

      return {
        'success': true,
        'message': 'Profile updated successfully',
        'user': userProfiles[userId],
      };
    } catch (e) {
      debugPrint('Profile update error: $e');
      return {'success': false, 'message': 'Failed to update profile'};
    }
  }

  // Get user profile by ID
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userProfilesData = prefs.getString(_userProfilesKey);

      if (userProfilesData == null) {
        return null;
      }

      final userProfiles = jsonDecode(userProfilesData) as Map<String, dynamic>;
      return userProfiles[userId];
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  // Generate session token
  static String _generateToken(String email, String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${email}_${userId}_$timestamp'.hashCode.toString();
  }
}
