import 'package:flutter/material.dart';
import 'package:task_management/services/task_service.dart';
import 'package:task_management/services/odoo_client.dart';

class AdminDashboardViewModel extends ChangeNotifier {
  final List<Map<String, dynamic>> _projects = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _tasks = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _users = <Map<String, dynamic>>[];
  bool _isRefreshing = false;
  String? _errorMessage;
  Map<String, dynamic>? _currentUser;

  List<Map<String, dynamic>> get projects => List.unmodifiable(_projects);
  List<Map<String, dynamic>> get tasks => List.unmodifiable(_tasks);
  List<Map<String, dynamic>> get users => List.unmodifiable(_users);
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get currentUser => _currentUser;

  AdminDashboardViewModel() {
    _currentUser = OdooClient.instance.currentUser;
    refresh();
  }

  /// Refresh data
  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final projectsResult = await TaskService().getAllProjects();

      if (projectsResult['success'] == true) {
        final projectsData = projectsResult['data'] as List<dynamic>?;

        _projects.clear();
        if (projectsData != null) {
          _projects.addAll(List<Map<String, dynamic>>.from(projectsData));
        }
      } else {
        _errorMessage = projectsResult['error'] ?? 'Failed to load projects';
      }

      final tasksResult = await TaskService().getAllTasks();

      if (tasksResult['success'] == true) {
        final tasksData = tasksResult['data'] as List<dynamic>?;

        _tasks.clear();
        if (tasksData != null) {
          _tasks.addAll(List<Map<String, dynamic>>.from(tasksData));
        }
      } else {
        _errorMessage = tasksResult['error'] ?? 'Failed to load tasks';
      }

      final usersResult = await TaskService().getUsers();

      if (usersResult['success'] == true) {
        final usersData = usersResult['data'] as List<dynamic>?;

        _users.clear();
        if (usersData != null) {
          _users.addAll(List<Map<String, dynamic>>.from(usersData));
        }
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

  Future<bool> assignTaskToUser(int taskId, List<int> userIds) async {
    try {
      final result = await TaskService().updateTask(
        taskId: taskId,
        userIds: userIds,
      );

      if (result['success'] == true) {
        await refresh();
        return true;
      } else {
        _errorMessage = result['error'] ?? 'Failed to assign task';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to assign task. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Create project
  Future<bool> createProject({
    required String name,
    String? description,
    DateTime? dateStart,
    DateTime? date,
  }) async {
    try {
      final result = await TaskService().createProject(
        name: name,
        description: description,
        dateStart: dateStart,
        date: date,
      );

      if (result['success'] == true) {
        await refresh();
        return true;
      } else {
        _errorMessage = result['error'] ?? 'Failed to create project';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to create project. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Update project
  Future<bool> updateProject({
    required int projectId,
    String? name,
    String? description,
    DateTime? dateStart,
    DateTime? date,
  }) async {
    try {
      final result = await TaskService().updateProject(
        projectId: projectId,
        name: name,
        description: description,
        dateStart: dateStart,
        date: date,
      );

      if (result['success'] == true) {
        await refresh();
        return true;
      } else {
        _errorMessage = result['error'] ?? 'Failed to update project';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to update project. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Delete project
  Future<bool> deleteProject(int projectId) async {
    try {
      final result = await TaskService().deleteProject(projectId);

      if (result['success'] == true) {
        await refresh();
        return true;
      } else {
        _errorMessage = result['error'] ?? 'Failed to delete project';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to delete project. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> createTask({
    required String name,
    required String description,
    int? projectId,
    List<int>? userIds,
    int? stageId,
    String? priority,
    DateTime? deadline,
  }) async {
    try {
      final result = await TaskService().createTask(
        name: name,
        description: description,
        projectId: projectId,
        userIds: userIds,
        stageId: stageId,
        priority: priority,
        deadline: deadline,
      );

      if (result['success'] == true) {
        await refresh();
        return true;
      } else {
        _errorMessage = result['error'] ?? 'Failed to create task';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to create task. Please try again.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
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

  /// Get user by ID
  Map<String, dynamic>? getUserById(int userId) {
    try {
      return _users.firstWhere((user) => user['id'] == userId);
    } catch (e) {
      return null;
    }
  }
}
