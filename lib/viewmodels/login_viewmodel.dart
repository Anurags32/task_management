import 'package:flutter/material.dart';
import 'package:task_management/services/notification_service.dart' show NotificationService;
import 'package:task_management/services/odoo_client.dart';

class LoginViewModel extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get currentUser => _currentUser;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> login() async {
    final usernameOrEmail = emailController.text.trim();
    final password = passwordController.text;

    _errorMessage = null;
    if (usernameOrEmail.isEmpty) {
      _errorMessage = 'Please enter username or email.';
      notifyListeners();
      return {'success': false, 'error': _errorMessage, 'userType': null};
    }
    if (password.isEmpty) {
      _errorMessage = 'Password is required.';
      notifyListeners();
      return {'success': false, 'error': _errorMessage, 'userType': null};
    }

    _isLoading = true;
    notifyListeners();

    try {
      final result = await OdooClient.instance.login(
        login: usernameOrEmail,
        password: password,
      );

      if (result['success'] == true) {
        _currentUser = result['user'];
        _errorMessage = null;

        // Determine user type
        String userType;
        if (OdooClient.instance.isAdmin) {
          userType = 'admin';
        } else if (usernameOrEmail.toLowerCase() == 'anurag@gmail.com') {
          userType = 'task_creator';
        } else {
          userType = 'normal_user';
        }

        // Ensure device token is registered after successful login
        try {
          // Register FCM token for this logged-in user
          await NotificationService().registerCurrentTokenWithBackend();
        } catch (e) {
          debugPrint('Failed to register token after login: $e');
        }

        return {
          'success': true,
          'userType': userType,
          'user': _currentUser,
          'uid': result['uid'],
        };
      } else {
        _errorMessage = result['error'] ?? 'Login failed.';
        return {'success': false, 'error': _errorMessage, 'userType': null};
      }
    } catch (e) {
      _errorMessage = 'Login failed. Please try again.';
      return {'success': false, 'error': _errorMessage, 'userType': null};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Logout current user
  Future<void> logout() async {
    await OdooClient.instance.logout();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }
}
