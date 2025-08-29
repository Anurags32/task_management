import 'package:flutter/material.dart';

class OnboardingViewModel extends ChangeNotifier {
  int _currentPageIndex = 0;

  int get currentPageIndex => _currentPageIndex;

  void setPage(int index) {
    if (index == _currentPageIndex) return;
    _currentPageIndex = index;
    notifyListeners();
  }
}
