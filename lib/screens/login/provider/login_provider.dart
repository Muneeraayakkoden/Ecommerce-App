import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/login_service.dart';

class LoginProvider extends ChangeNotifier {
  // Form controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  // State variables
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedUserType = 'customer';
  String? _errorMessage;
  Map<String, dynamic>? _currentUser;

  // Getters
  bool get isLoading => _isLoading;
  bool get obscurePassword => _obscurePassword;
  String get selectedUserType => _selectedUserType;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get currentUser => _currentUser;

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  // Set user type (customer/admin)
  void setUserType(String userType) {
    _selectedUserType = userType;
    clearError();
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Set error message
  void setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Set current user
  void setCurrentUser(Map<String, dynamic> user) {
    _currentUser = user;
    notifyListeners();
  }

  // Clear form fields
  void clearForm() {
    emailController.clear();
    passwordController.clear();
    clearError();
    notifyListeners();
  }

  // Validate form inputs
  bool validateForm() {
    clearError();
    
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty) {
      setError('Please enter your email');
      return false;
    }

    if (!LoginService.isValidEmail(email)) {
      setError('Please enter a valid email address');
      return false;
    }

    if (password.isEmpty) {
      setError('Please enter your password');
      return false;
    }

    if (!LoginService.isValidPassword(password)) {
      setError('Password must be at least 6 characters long');
      return false;
    }

    return true;
  }

  // Login user
  Future<bool> loginUser() async {
    if (!validateForm()) {
      return false;
    }

    setLoading(true);
    clearError();

    try {
      final result = await LoginService.authenticateUser(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        userType: _selectedUserType,
      );

      if (result['success']) {
        final userData = result['user'];
        
        // Save session to local storage
        final sessionSaved = await LoginService.saveUserSession(userData);
        if (sessionSaved) {
          setCurrentUser(userData);
          clearForm();
          return true;
        } else {
          setError('Failed to save session');
          return false;
        }
      } else {
        setError(result['message'] ?? 'Login failed');
        return false;
      }
    } catch (e) {
      setError('An unexpected error occurred');
      if (kDebugMode) {
        print('Login error: $e');
      }
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Check if user is already logged in
  Future<bool> checkExistingSession() async {
    try {
      final isLoggedIn = await LoginService.isUserLoggedIn();
      if (isLoggedIn) {
        final userSession = await LoginService.getUserSession();
        if (userSession != null) {
          setCurrentUser(userSession);
          return true;
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Session check error: $e');
      }
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      await LoginService.clearUserSession();
      _currentUser = null;
      clearForm();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Logout error: $e');
      }
    }
  }

  // Get demo credentials for testing
  Map<String, String> getDemoCredentials() {
    switch (_selectedUserType) {
      case 'customer':
        return {
          'email': 'customer@example.com',
          'password': 'customer123',
        };
      case 'admin':
        return {
          'email': 'admin@example.com',
          'password': 'admin123',
        };
      default:
        return {};
    }
  }

  // Fill demo credentials
  void fillDemoCredentials() {
    final credentials = getDemoCredentials();
    emailController.text = credentials['email'] ?? '';
    passwordController.text = credentials['password'] ?? '';
    clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
