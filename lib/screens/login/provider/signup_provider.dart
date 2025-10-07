import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/signup_service.dart';

class SignupProvider extends ChangeNotifier {
  // Form controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  
  // State variables
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  String? _successMessage;

  // Getters
  bool get isLoading => _isLoading;
  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

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

  // Toggle confirm password visibility
  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear success message
  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  // Clear all messages
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // Set error message
  void setError(String error) {
    _errorMessage = error;
    _successMessage = null;
    notifyListeners();
  }

  // Set success message
  void setSuccess(String message) {
    _successMessage = message;
    _errorMessage = null;
    notifyListeners();
  }

  // Clear form fields
  void clearForm() {
    nameController.clear();
    emailController.clear();
    phoneController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    clearMessages();
    notifyListeners();
  }

  // Validate form inputs
  bool validateForm() {
    clearMessages();
    
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // Validate name
    if (name.isEmpty) {
      setError('Please enter your full name');
      return false;
    }

    if (!SignupService.isValidName(name)) {
      setError('Name must be at least 2 characters long');
      return false;
    }

    // Validate email
    if (email.isEmpty) {
      setError('Please enter your email');
      return false;
    }

    if (!SignupService.isValidEmail(email)) {
      setError('Please enter a valid email address');
      return false;
    }

    // Validate phone
    if (phone.isEmpty) {
      setError('Please enter your phone number');
      return false;
    }

    if (!SignupService.isValidPhone(phone)) {
      setError('Please enter a valid phone number');
      return false;
    }

    // Validate password
    if (password.isEmpty) {
      setError('Please enter your password');
      return false;
    }

    if (!SignupService.isValidPassword(password)) {
      setError('Password must be at least 6 characters long');
      return false;
    }

    // Validate confirm password
    if (confirmPassword.isEmpty) {
      setError('Please confirm your password');
      return false;
    }

    if (password != confirmPassword) {
      setError('Passwords do not match');
      return false;
    }

    return true;
  }

  // Register new user
  Future<bool> registerUser() async {
    if (!validateForm()) {
      return false;
    }

    setLoading(true);
    clearMessages();

    try {
      final result = await SignupService.registerUser(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (result['success']) {
        setSuccess(result['message'] ?? 'Registration successful');
        clearForm();
        return true;
      } else {
        setError(result['message'] ?? 'Registration failed');
        return false;
      }
    } catch (e) {
      setError('An unexpected error occurred');
      if (kDebugMode) {
        print('Registration error: $e');
      }
      return false;
    } finally {
      setLoading(false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
