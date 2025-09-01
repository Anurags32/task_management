import 'package:flutter/material.dart';
import '../services/task_service.dart';
import '../services/odoo_client.dart'; // Added import for OdooClient

class AddTaskViewModel extends ChangeNotifier {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _stages = [];
  int? _selectedProjectId;
  int? _selectedAssigneeId;
  String _selectedPriority = '0';
  DateTime? _deadline;
  DateTime? _startDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _allottedTime;
  Map<String, dynamic>? _currentUser;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get projects => List.unmodifiable(_projects);
  List<Map<String, dynamic>> get users => List.unmodifiable(_users);
  List<Map<String, dynamic>> get stages => List.unmodifiable(_stages);
  int? get selectedProjectId => _selectedProjectId;
  int? get selectedAssigneeId => _selectedAssigneeId;
  String get selectedPriority => _selectedPriority;
  DateTime? get deadline => _deadline;
  DateTime? get startDate => _startDate;
  TimeOfDay? get startTime => _startTime;
  TimeOfDay? get endTime => _endTime;
  String? get allottedTime => _allottedTime;
  Map<String, dynamic>? get currentUser => _currentUser;

  /// Load initial data (projects, users, stages)
  Future<void> loadInitialData() async {
    try {
      // Load current user info
      final sessionResult = await OdooClient.instance.sessionInfo();
      if (sessionResult['success'] == true) {
        final userData = sessionResult['data'] as Map<String, dynamic>?;
        if (userData != null) {
          _currentUser = userData;
        }
      }

      // Load projects
      final projectsResult = await TaskService().getAllProjects();
      if (projectsResult['success'] == true) {
        final projectsData = projectsResult['data'] as List<dynamic>?;
        if (projectsData != null) {
          _projects = List<Map<String, dynamic>>.from(projectsData);
        }
      }

      // Load users
      final usersResult = await TaskService().getUsers();
      if (usersResult['success'] == true) {
        final usersData = usersResult['data'] as List<dynamic>?;
        if (usersData != null) {
          _users = List<Map<String, dynamic>>.from(usersData);
        }
      }

      // Load stages
      final stagesResult = await TaskService().getTaskStages();
      if (stagesResult['success'] == true) {
        final stagesData = stagesResult['data'] as List<dynamic>?;
        if (stagesData != null) {
          _stages = List<Map<String, dynamic>>.from(stagesData);
        }
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load data: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Set selected project
  void setSelectedProject(int? projectId) {
    if (projectId != null) {
      // Check if the project exists in the loaded projects
      final projectExists = _projects.any(
        (project) => project['id'] == projectId,
      );
      if (!projectExists) {
        // If project doesn't exist, don't set it
        _selectedProjectId = null;
      } else {
        _selectedProjectId = projectId;
      }
    } else {
      _selectedProjectId = null;
    }
    notifyListeners();
  }

  /// Set selected assignee
  void setSelectedAssignee(int? assigneeId) {
    _selectedAssigneeId = assigneeId;
    notifyListeners();
  }

  /// Set selected priority
  void setSelectedPriority(String priority) {
    _selectedPriority = priority;
    notifyListeners();
  }

  /// Set deadline
  void setDeadline(DateTime? deadline) {
    _deadline = deadline;
    notifyListeners();
  }

  /// Set start date
  void setStartDate(DateTime? startDate) {
    _startDate = startDate;
    notifyListeners();
  }

  /// Set start time
  void setStartTime(TimeOfDay? startTime) {
    _startTime = startTime;
    notifyListeners();
  }

  /// Set end time
  void setEndTime(TimeOfDay? endTime) {
    _endTime = endTime;
    notifyListeners();
  }

  /// Set allotted time
  void setAllottedTime(String? allottedTime) {
    _allottedTime = allottedTime;
    notifyListeners();
  }

  /// Get deadline with time
  DateTime? getDeadlineWithTime() {
    if (_deadline == null) return null;
    if (_endTime == null) return _deadline;

    return DateTime(
      _deadline!.year,
      _deadline!.month,
      _deadline!.day,
      _endTime!.hour,
      _endTime!.minute,
    );
  }

  /// Get start date with time
  DateTime? getStartDateWithTime() {
    if (_startDate == null) return null;
    if (_startTime == null) return _startDate;

    return DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Submit task creation
  Future<bool> submit() async {
    _errorMessage = null;
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();

    if (title.isEmpty) {
      _errorMessage = 'Title is required.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      final result = await TaskService().createTask(
        name: title,
        description: description.isEmpty ? 'No description' : description,
        projectId: _selectedProjectId,
        userIds: _selectedAssigneeId != null ? [_selectedAssigneeId!] : null,
        priority: _selectedPriority,
        deadline: getDeadlineWithTime(),
        dateStart: getStartDateWithTime(),
      );

      if (result['success'] == true) {
        return true;
      } else {
        _errorMessage = result['error'] ?? 'Failed to create task.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to create task. Please try again.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
