import 'package:flutter/material.dart';

class AdminDashboardViewModel extends ChangeNotifier {
  final List<String> _tasks = <String>[
    'Plan sprint backlog',
    'Assign tasks to team',
  ];

  List<String> get tasks => List.unmodifiable(_tasks);

  void addTask(String title) {
    _tasks.add(title);
    notifyListeners();
  }
}
