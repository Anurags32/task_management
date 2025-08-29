import 'package:flutter/material.dart';
import 'package:task_management/services/task_service.dart';

class UserDashboardViewModel extends ChangeNotifier {
  final List<Map<String, dynamic>> _tasks = <Map<String, dynamic>>[];
  bool _isRefreshing = false;

  List<Map<String, dynamic>> get tasks => List.unmodifiable(_tasks);
  bool get isRefreshing => _isRefreshing;

  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    notifyListeners();
    try {
      final data = await TaskService.instance.fetchTasks(onlyMyTasks: true);
      _tasks
        ..clear()
        ..addAll(data);
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }
}
