import 'package:flutter/material.dart';
import '../services/task_service.dart';
import '../services/odoo_client.dart'; // Added import for OdooClient
import '../services/notification_service.dart'; // Added import for NotificationService

class AddTaskViewModel extends ChangeNotifier {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _stages = [];
  int? _selectedProjectId;
  List<int> _selectedAssigneeIds = [];
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
  List<int> get selectedAssigneeIds => List.unmodifiable(_selectedAssigneeIds);
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

  /// Replace selected assignees with provided list
  void setSelectedAssignees(List<int> assigneeIds) {
    _selectedAssigneeIds = List<int>.from(assigneeIds);
    notifyListeners();
  }

  /// Toggle an assignee in selection
  void toggleAssignee(int assigneeId) {
    if (_selectedAssigneeIds.contains(assigneeId)) {
      _selectedAssigneeIds.remove(assigneeId);
    } else {
      _selectedAssigneeIds.add(assigneeId);
    }
    notifyListeners();
  }

  /// Clear all selected assignees
  void clearAssignees() {
    _selectedAssigneeIds.clear();
    notifyListeners();
  }

  /// Set selected priority
  void setSelectedPriority(String priority) {
    _selectedPriority = priority;
    notifyListeners();
  }

  /// Set deadline
  void setDeadline(DateTime? deadline) {
    print(
      '🔄 AddTaskViewModel: setDeadline called with: ${deadline?.toString()}',
    );
    _deadline = deadline;
    print('✅ AddTaskViewModel: Deadline set to: ${_deadline?.toString()}');
    notifyListeners();
  }

  /// Set start date
  void setStartDate(DateTime? startDate) {
    print(
      '🔄 AddTaskViewModel: setStartDate called with: ${startDate?.toString()}',
    );
    _startDate = startDate;
    print('✅ AddTaskViewModel: Start date set to: ${_startDate?.toString()}');
    notifyListeners();
  }

  /// Set start time
  void setStartTime(TimeOfDay? startTime) {
    print(
      '🔄 AddTaskViewModel: setStartTime called with: ${startTime?.toString()}',
    );
    _startTime = startTime;
    print('✅ AddTaskViewModel: Start time set to: ${_startTime?.toString()}');
    notifyListeners();
  }

  /// Set end time
  void setEndTime(TimeOfDay? endTime) {
    print(
      '🔄 AddTaskViewModel: setEndTime called with: ${endTime?.toString()}',
    );
    _endTime = endTime;
    print('✅ AddTaskViewModel: End time set to: ${_endTime?.toString()}');
    notifyListeners();
  }

  /// Set allotted time
  void setAllottedTime(String? allottedTime) {
    _allottedTime = allottedTime;
    notifyListeners();
  }

  /// Get deadline with time
  DateTime? getDeadlineWithTime() {
    print('🔄 AddTaskViewModel: getDeadlineWithTime called');
    print('🔄 AddTaskViewModel: _deadline: ${_deadline?.toString()}');
    print('🔄 AddTaskViewModel: _endTime: ${_endTime?.toString()}');

    if (_deadline == null) {
      print('❌ AddTaskViewModel: No deadline set, returning null');
      return null;
    }
    if (_endTime == null) {
      print(
        '⚠️ AddTaskViewModel: No end time set, returning deadline without time: ${_deadline?.toString()}',
      );
      return _deadline;
    }

    final deadlineWithTime = DateTime(
      _deadline!.year,
      _deadline!.month,
      _deadline!.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    print(
      '✅ AddTaskViewModel: Combined deadline with time: ${deadlineWithTime.toString()}',
    );
    return deadlineWithTime;
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
    print('🔄 AddTaskViewModel: submit() called');
    print('🔄 AddTaskViewModel: Task title: ${titleController.text.trim()}');
    print(
      '🔄 AddTaskViewModel: Task description: ${descriptionController.text.trim()}',
    );
    print('🔄 AddTaskViewModel: Selected project ID: $_selectedProjectId');
    print('🔄 AddTaskViewModel: Selected assignee IDs: $_selectedAssigneeIds');
    print('🔄 AddTaskViewModel: Selected priority: $_selectedPriority');

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
      final allocatedMinutes = _allottedTime != null
          ? int.tryParse(_allottedTime!)
          : null;

      print('🔄 AddTaskViewModel: Allocated minutes: $allocatedMinutes');

      // If allocated time provided, embed it in description so user app can schedule
      String finalDescription = description.isEmpty
          ? 'No description'
          : description;
      if (allocatedMinutes != null && allocatedMinutes > 0) {
        finalDescription =
            '$finalDescription\nAllocated: ${allocatedMinutes.toString()}';
      }

      print('🔄 AddTaskViewModel: Final description: $finalDescription');

      // Get deadline and start date with time
      final deadlineWithTime = getDeadlineWithTime();
      final startDateWithTime = getStartDateWithTime();

      print(
        '🔄 AddTaskViewModel: Deadline with time: ${deadlineWithTime?.toString()}',
      );
      print(
        '🔄 AddTaskViewModel: Start date with time: ${startDateWithTime?.toString()}',
      );

      final result = await TaskService().createTask(
        name: title,
        description: finalDescription,
        projectId: _selectedProjectId,
        userIds: _selectedAssigneeIds.isNotEmpty ? _selectedAssigneeIds : null,
        priority: _selectedPriority,
        deadline: deadlineWithTime,
        dateStart: startDateWithTime,
        allocatedMinutes: allocatedMinutes,
      );

      print('🔄 AddTaskViewModel: Task creation result: $result');

      if (result['success'] == true) {
        print('✅ AddTaskViewModel: Task created successfully!');

        // Schedule deadline reminder notification if deadline is set
        if (deadlineWithTime != null) {
          try {
            final taskId = result['id'] as int?;
            if (taskId != null) {
              await NotificationService().scheduleDeadlineReminder(
                taskId: taskId,
                taskName: title,
                deadline: deadlineWithTime,
              );
              print(
                '✅ AddTaskViewModel: Deadline reminder scheduled for task $taskId',
              );
            }
          } catch (e) {
            print(
              '⚠️ AddTaskViewModel: Failed to schedule deadline reminder: $e',
            );
            // Don't fail the task creation if reminder scheduling fails
          }
        }

        return true;
      } else {
        final error = result['error'] ?? 'Failed to create task.';
        print('❌ AddTaskViewModel: Task creation failed: $error');
        _errorMessage = error;
        return false;
      }
    } catch (e) {
      print('❌ AddTaskViewModel: Exception during task creation: $e');
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
