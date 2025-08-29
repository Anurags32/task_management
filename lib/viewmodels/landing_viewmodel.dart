import 'package:flutter/material.dart';

class LandingViewModel extends ChangeNotifier {
  bool _isInitializing = false;

  bool get isInitializing => _isInitializing;

  Future<void> initializeApp() async {
    if (_isInitializing) return;
    _isInitializing = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    _isInitializing = false;
    notifyListeners();
  }
}
