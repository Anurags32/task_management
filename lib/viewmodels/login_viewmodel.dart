import 'package:flutter/material.dart';
import 'package:task_management/services/odoo_client.dart';

class LoginViewModel extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<bool> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    _errorMessage = null;
    if (email.isEmpty || !email.contains('@')) {
      _errorMessage = 'Please enter a valid email.';
      notifyListeners();
      return false;
    }
    if (password.isEmpty) {
      _errorMessage = 'Password is required.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final success = await OdooClient.instance.login(
        login: email,
        password: password,
      );
      if (!success) {
        _errorMessage = 'Invalid credentials.';
        return false;
      }
      return true;
    } catch (e) {
      _errorMessage = 'Login failed. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
