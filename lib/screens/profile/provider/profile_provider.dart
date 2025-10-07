import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../login/services/signup_service.dart';

class ProfileProvider extends ChangeNotifier {
  // Form controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  
  // State variables
  bool _isLoading = false;
  bool _isEditing = false;
  String? _errorMessage;
  String? _successMessage;
  Map<String, dynamic>? _userProfile;

  // Getters
  bool get isLoading => _isLoading;
  bool get isEditing => _isEditing;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  Map<String, dynamic>? get userProfile => _userProfile;

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set editing state
  void setEditing(bool editing) {
    _isEditing = editing;
    if (!editing) {
      clearMessages();
    }
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

  // Set user profile
  void setUserProfile(Map<String, dynamic> profile) {
    _userProfile = profile;
    _populateFormFields();
    notifyListeners();
  }

  // Populate form fields with user data
  void _populateFormFields() {
    if (_userProfile != null) {
      nameController.text = _userProfile!['name'] ?? '';
      emailController.text = _userProfile!['email'] ?? '';
      phoneController.text = _userProfile!['phone'] ?? '';
    }
  }

  // Load user profile
  Future<void> loadUserProfile(String userId) async {
    setLoading(true);
    clearMessages();

    try {
      final profile = await SignupService.getUserProfile(userId);
      if (profile != null) {
        setUserProfile(profile);
      } else {
        setError('Failed to load user profile');
      }
    } catch (e) {
      setError('An unexpected error occurred while loading profile');
      if (kDebugMode) {
        print('Profile load error: $e');
      }
    } finally {
      setLoading(false);
    }
  }

  // Validate form inputs
  bool validateForm() {
    clearMessages();
    
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();

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

    return true;
  }

  // Update user profile
  Future<bool> updateProfile() async {
    if (!validateForm()) {
      return false;
    }

    if (_userProfile == null) {
      setError('User profile not found');
      return false;
    }

    setLoading(true);
    clearMessages();

    try {
      final result = await SignupService.updateUserProfile(
        userId: _userProfile!['id'],
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
      );

      if (result['success']) {
        setUserProfile(result['user']);
        setSuccess(result['message'] ?? 'Profile updated successfully');
        setEditing(false);
        return true;
      } else {
        setError(result['message'] ?? 'Failed to update profile');
        return false;
      }
    } catch (e) {
      setError('An unexpected error occurred');
      if (kDebugMode) {
        print('Profile update error: $e');
      }
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Cancel editing and reset form
  void cancelEditing() {
    _populateFormFields();
    setEditing(false);
    clearMessages();
  }

  // Format date for display
  String formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  // Get user type display name
  String getUserTypeDisplayName() {
    final userType = _userProfile?['userType'] ?? 'customer';
    return userType == 'admin' ? 'Administrator' : 'Customer';
  }

  // Get user initials for avatar
  String getUserInitials() {
    final name = _userProfile?['name'] ?? '';
    if (name.isEmpty) return 'U';
    
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else {
      return words[0][0].toUpperCase();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}

