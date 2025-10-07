import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'signup_service.dart';

class LoginService {
  // Mock API endpoints
  static const String baseUrl = 'https://jsonplaceholder.typicode.com';
  
  // Mock users (admin only - customers register through signup)
  static const Map<String, Map<String, String>> mockUsers = {
    'admin': {
      'admin@example.com': 'admin123',
      'admin@test.com': 'admin456',
    },
  };

  static Future<void> _simulateDelay() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  static Future<Map<String, dynamic>> authenticateUser({
    required String email,
    required String password,
    required String userType,
  }) async {
    try {
      await _simulateDelay();
      
      // For customers, check registered users first
      if (userType == 'customer') {
        final result = await SignupService.authenticateRegisteredUser(
          email: email,
          password: password,
        );
        
        if (result['success']) {
          return {
            'success': true,
            'user': result['user'],
            'message': 'Login successful',
          };
        } else {
          return {
            'success': false,
            'error': result['message'],
            'message': result['message'],
          };
        }
      }
      
      // For admin, check mock data
      final userCredentials = mockUsers[userType];
      if (userCredentials == null) {
        throw Exception('Invalid user type');
      }
      
      final storedPassword = userCredentials[email.toLowerCase()];
      if (storedPassword == null || storedPassword != password) {
        throw Exception('Invalid credentials');
      }
      
      // Generate mock admin user data
      final userData = {
        'id': email.hashCode.toString(),
        'email': email,
        'name': _getNameFromEmail(email),
        'phone': '+1-555-0123', // Mock phone for admin
        'type': userType,
        'token': _generateToken(email, userType),
        'loginTime': DateTime.now().toIso8601String(),
        'createdAt': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      return {
        'success': true,
        'user': userData,
        'message': 'Login successful',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Login failed',
      };
    }
  }

  static String _generateToken(String email, String userType) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${userType}_${email}_$timestamp'.hashCode.toString();
  }

  static String _getNameFromEmail(String email) {
    final name = email.split('@')[0];
    return name.split('.').map((word) => 
      word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  static Future<bool> saveUserSession(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_session', jsonEncode(userData));
      await prefs.setString('auth_token', userData['token']);
      await prefs.setString('user_type', userData['type']);
      return true;
    } catch (e) {
      debugPrint('Error saving session: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionData = prefs.getString('user_session');
      if (sessionData != null) {
        return jsonDecode(sessionData);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting session: $e');
      return null;
    }
  }

  static Future<bool> isUserLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      return token != null && token.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking login status: $e');
      return false;
    }
  }

  static Future<String?> getUserType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_type');
    } catch (e) {
      debugPrint('Error getting user type: $e');
      return null;
    }
  }

  static Future<bool> clearUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_session');
      await prefs.remove('auth_token');
      await prefs.remove('user_type');
      return true;
    } catch (e) {
      debugPrint('Error clearing session: $e');
      return false;
    }
  }

  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }
}
