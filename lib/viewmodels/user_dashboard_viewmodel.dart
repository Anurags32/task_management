import 'package:flutter/material.dart';
import 'package:task_management/services/task_service.dart';
import 'package:task_management/services/odoo_client.dart';

class UserDashboardViewModel extends ChangeNotifier {
  final List<Map<String, dynamic>> _projects = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _tasks = <Map<String, dynamic>>[];
  bool _isRefreshing = false;
  String? _errorMessage;
  Map<String, dynamic>? _currentUser;

  List<Map<String, dynamic>> get projects => List.unmodifiable(_projects);
  List<Map<String, dynamic>> get tasks => List.unmodifiable(_tasks);
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get currentUser => _currentUser;

  UserDashboardViewModel() {
    _currentUser = OdooClient.instance.currentUser;
    refresh();
  }

  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_currentUser != null && _currentUser!['uid'] != null) {
        final userId = _currentUser!['uid'];

        // Load user's projects
        final projectsResult = await TaskService().getUserProjects(userId);
        if (projectsResult['success'] == true) {
          _projects.clear();
          _projects.addAll(
            List<Map<String, dynamic>>.from(projectsResult['data'] ?? []),
          );
        } else {
          _errorMessage = projectsResult['error'] ?? 'Failed to load projects';
        }

        // Load user's tasks
        final result = await TaskService().getUserTasks(userId);
        if (result['success'] == true) {
          _tasks.clear();
          _tasks.addAll(List<Map<String, dynamic>>.from(result['data'] ?? []));
        } else {
          _errorMessage = result['error'] ?? 'Failed to load tasks';
        }
      } else {
        _errorMessage = 'User not authenticated';
      }
    } catch (e) {
      _errorMessage = 'Failed to load data. Please try again.';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<bool> updateTaskStage(int taskId, int newStageId) async {
    try {
      final result = await TaskService().updateTask(
        taskId: taskId,
        stageId: newStageId,
      );

      if (result['success'] == true) {
        // Refresh the data
        await refresh();
        return true;
      } else {
        _errorMessage = result['error'] ?? 'Failed to update task';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to update task. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Get project by ID
  Map<String, dynamic>? getProjectById(int projectId) {
    try {
      return _projects.firstWhere((project) => project['id'] == projectId);
    } catch (e) {
      return null;
    }
  }

  /// Get tasks for a specific project
  List<Map<String, dynamic>> getTasksForProject(int projectId) {
    return _tasks.where((task) => task['project_id']?[0] == projectId).toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
