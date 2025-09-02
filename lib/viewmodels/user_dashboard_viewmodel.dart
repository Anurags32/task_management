import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/task_service.dart';
import '../services/odoo_client.dart';
import '../services/notification_service.dart';

class UserDashboardViewModel extends ChangeNotifier {
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _currentUser;

  List<Map<String, dynamic>> get tasks => List.unmodifiable(_tasks);
  List<Map<String, dynamic>> get projects => List.unmodifiable(_projects);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get currentUser => _currentUser;

  // Listen to push events to auto-refresh data
  StreamSubscription<Map<String, dynamic>>? _pushSub;

  UserDashboardViewModel() {
    _subscribeToPushEvents();
  }

  void _subscribeToPushEvents() {
    try {
      // Auto-refresh tasks when a task_assigned push arrives
      _pushSub?.cancel();
      _pushSub = NotificationService().events.listen((event) async {
        if (event['type'] == 'task_assigned') {
          final uid = _currentUser?['uid'] as int?;
          if (uid != null) {
            await loadUserData();
          }
        }
      });
    } catch (e) {
      // ignore
    }
  }

  @override
  void dispose() {
    _pushSub?.cancel();
    super.dispose();
  }

  /// Tasks sorted by latest (based on write_date then create_date)
  List<Map<String, dynamic>> get sortedTasksLatest {
    if (_tasks.isEmpty) return const [];
    final sorted = List<Map<String, dynamic>>.from(_tasks);
    sorted.sort((a, b) {
      final aWrite = a['write_date']?.toString();
      final bWrite = b['write_date']?.toString();
      final aCreate = a['create_date']?.toString();
      final bCreate = b['create_date']?.toString();

      DateTime? dtA;
      DateTime? dtB;
      try {
        if (aWrite != null && aWrite.isNotEmpty) {
          dtA = DateTime.parse(aWrite);
        } else if (aCreate != null && aCreate.isNotEmpty) {
          dtA = DateTime.parse(aCreate);
        }
      } catch (_) {}
      try {
        if (bWrite != null && bWrite.isNotEmpty) {
          dtB = DateTime.parse(bWrite);
        } else if (bCreate != null && bCreate.isNotEmpty) {
          dtB = DateTime.parse(bCreate);
        }
      } catch (_) {}

      if (dtA == null && dtB == null) return 0;
      if (dtA == null) return 1;
      if (dtB == null) return -1;
      return dtB.compareTo(dtA);
    });
    return sorted;
  }

  /// Get the latest task (most recently created or updated)
  Map<String, dynamic>? get latestTask {
    if (_tasks.isEmpty) return null;

    // Sort tasks by creation date (most recent first)
    final sortedTasks = List<Map<String, dynamic>>.from(_tasks);
    sortedTasks.sort((a, b) {
      final dateA = a['create_date'] ?? a['write_date'] ?? '';
      final dateB = b['create_date'] ?? b['write_date'] ?? '';

      if (dateA == '' && dateB == '') return 0;
      if (dateA == '') return 1;
      if (dateB == '') return -1;

      try {
        final dateTimeA = DateTime.parse(dateA.toString());
        final dateTimeB = DateTime.parse(dateB.toString());
        return dateTimeB.compareTo(dateTimeA); // Most recent first
      } catch (e) {
        return 0;
      }
    });

    return sortedTasks.first;
  }

  /// Logout current user
  Future<bool> logout() async {
    try {
      await OdooClient.instance.logout();
      _currentUser = null;
      _tasks.clear();
      _projects.clear();
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to logout: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Detect new assignments and schedule notifications locally on user device
  Future<void> _processNewAssignments(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seenKey =
          'seen_tasks_user_'
          '${userId.toString()}';
      final seenIds = prefs.getStringList(seenKey) ?? <String>[];
      final Set<String> seen = seenIds.toSet();

      // Build a map of current tasks by ID
      final Map<int, Map<String, dynamic>> taskById = {
        for (final t in _tasks)
          if (t['id'] is int) t['id'] as int: t,
      };

      // Find newly assigned tasks (present now but not in seen)
      final List<Map<String, dynamic>> newlyAssigned = [];
      for (final entry in taskById.entries) {
        final idStr = entry.key.toString();
        if (!seen.contains(idStr)) {
          newlyAssigned.add(entry.value);
        }
      }

      // Update seen with current IDs
      await prefs.setStringList(
        seenKey,
        taskById.keys.map((e) => e.toString()).toList(),
      );

      if (newlyAssigned.isEmpty) return;

      final notificationService = NotificationService();

      for (final task in newlyAssigned) {
        final int taskId = task['id'] as int;
        final String taskName = (task['name']?.toString() ?? 'Task');

        // Show immediate "Task Assigned" notification
        await notificationService.showTaskAssignmentNotification(
          taskId: taskId,
          taskName: taskName,
          projectName: _projectNameForTask(task),
        );

        // Schedule reminders and final deadline
        await _scheduleRemindersForTask(notificationService, task);
      }
    } catch (e) {
      print('UserDashboardViewModel._processNewAssignments error: $e');
    }
  }

  String _projectNameForTask(Map<String, dynamic> task) {
    try {
      // project_id can be [id, name]
      final p = task['project_id'];
      if (p is List && p.length >= 2) {
        return p[1]?.toString() ?? 'Project';
      }
    } catch (_) {}
    return 'Project';
  }

  Future<void> _scheduleRemindersForTask(
    NotificationService notificationService,
    Map<String, dynamic> task,
  ) async {
    try {
      final int taskId = task['id'] as int;
      final String taskName = (task['name']?.toString() ?? 'Task');

      // Prefer allocated window (if encoded in description like "Allocated: <minutes>")
      int? allocatedMinutes;
      DateTime base = DateTime.now();

      // Try to parse allocated time from description pattern e.g., "Allocated: 60"
      final desc = task['description']?.toString() ?? '';
      final match = RegExp(r'Allocated\s*:\s*(\d+)').firstMatch(desc);
      if (match != null) {
        allocatedMinutes = int.tryParse(match.group(1)!);
      }

      // Try date_deadline from server
      DateTime? deadline;
      final dl = task['date_deadline'];
      if (dl is String && dl.isNotEmpty) {
        try {
          deadline = DateTime.parse(dl);
        } catch (_) {}
      }

      if (allocatedMinutes != null && allocatedMinutes > 0) {
        final endTime = base.add(Duration(minutes: allocatedMinutes));

        // Schedule reminders 30,45,55 minutes into the window if fit
        final points = [
          30,
          45,
          55,
        ].where((m) => m < allocatedMinutes!).toList();
        for (final m in points) {
          final minutesBeforeEnd = allocatedMinutes - m;
          await notificationService.scheduleTaskReminder(
            taskId: taskId,
            taskName: taskName,
            deadline: endTime,
            reminderMinutes: minutesBeforeEnd,
          );
        }
        await notificationService.scheduleTaskDeadline(
          taskId: taskId,
          taskName: taskName,
          deadline: endTime,
        );
        return;
      }

      // Fallback to deadline based reminders if available
      if (deadline != null) {
        await notificationService.scheduleTaskReminder(
          taskId: taskId,
          taskName: taskName,
          deadline: deadline,
          reminderMinutes: 30,
        );
        await notificationService.scheduleTaskReminder(
          taskId: taskId,
          taskName: taskName,
          deadline: deadline,
          reminderMinutes: 45,
        );
        await notificationService.scheduleTaskReminder(
          taskId: taskId,
          taskName: taskName,
          deadline: deadline,
          reminderMinutes: 55,
        );
        await notificationService.scheduleTaskDeadline(
          taskId: taskId,
          taskName: taskName,
          deadline: deadline,
        );
      }
    } catch (e) {
      print('UserDashboardViewModel._scheduleRemindersForTask error: $e');
    }
  }

  /// Load user-specific data
  Future<void> loadUserData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get current user info
      final sessionResult = await OdooClient.instance.sessionInfo();
      if (sessionResult['success'] == true) {
        final userData = sessionResult['data'] as Map<String, dynamic>?;
        if (userData != null) {
          _currentUser = userData;
          print('Session data: $userData');
        }
      }

      // Get user ID from session
      final userId = _currentUser?['uid'] as int?;
      if (userId == null) {
        _errorMessage = 'User session not found';
        return;
      }

      // Load only tasks assigned to this user
      final tasksResult = await TaskService().getUserTasks(userId);
      if (tasksResult['success'] == true) {
        final tasksData = tasksResult['data'] as List<dynamic>?;
        if (tasksData != null) {
          // Remove any duplicate tasks by ID
          final Map<int, Map<String, dynamic>> uniqueTasks = {};
          for (final task in tasksData) {
            final taskMap = Map<String, dynamic>.from(task);
            final taskId = taskMap['id'] as int?;
            if (taskId != null) {
              uniqueTasks[taskId] = taskMap;
            }
          }
          _tasks = uniqueTasks.values.toList();

          // Debug logging
          print('User ID: $userId');
          print('Total tasks loaded: ${tasksData.length}');
          print('Unique tasks after deduplication: ${_tasks.length}');
          print('Task IDs: ${_tasks.map((t) => t['id']).toList()}');
        }
      } else {
        _errorMessage = tasksResult['error'] ?? 'Failed to load tasks';
      }

      // Load projects that contain user's tasks
      final projectsResult = await TaskService().getUserProjects(userId);
      if (projectsResult['success'] == true) {
        final projectsData = projectsResult['data'] as List<dynamic>?;
        if (projectsData != null) {
          _projects = List<Map<String, dynamic>>.from(projectsData);
        }
      }

      // Trigger user-side notifications for new assignments
      await _processNewAssignments(userId);

      // Optional: logs
      await logAvailableStages();
      await checkAvailableModels();
      await logTaskStates();
    } catch (e) {
      _errorMessage = 'Failed to load data: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update a task's status (open/in_progress/done/hold), prefer stage moves, notify admin
  Future<bool> updateTaskStatus(int taskId, String statusKey) async {
    try {
      final idx = _tasks.indexWhere((t) => t['id'] == taskId);
      if (idx == -1) return false;

      final oldState = _tasks[idx]['state'];
      _tasks[idx]['state'] = statusKey; // optimistic UI
      notifyListeners();

      // Try to map the requested status to a stage
      int? desiredStageId;
      try {
        final stagesResult = await TaskService().getTaskStages();
        if (stagesResult['success'] == true) {
          final stages = stagesResult['data'] as List<dynamic>?;
          if (stages != null) {
            for (final s in stages) {
              final m = Map<String, dynamic>.from(s);
              final name = (m['name']?.toString().toLowerCase() ?? '');
              if (statusKey == 'done' &&
                  (name.contains('done') || name.contains('complete'))) {
                desiredStageId = m['id'] as int?;
                break;
              }
              if (statusKey == 'in_progress' &&
                  (name.contains('progress') ||
                      name.contains('working') ||
                      name.contains('started'))) {
                desiredStageId = m['id'] as int?;
                break;
              }
              if (statusKey == 'hold' &&
                  (name.contains('hold') ||
                      name.contains('waiting') ||
                      name.contains('blocked'))) {
                desiredStageId = m['id'] as int?;
                break;
              }
              if (statusKey == 'open' &&
                  (name.contains('new') ||
                      name.contains('todo') ||
                      name.contains('backlog') ||
                      name.contains('open'))) {
                desiredStageId = m['id'] as int?;
                break;
              }
            }
          }
        }
      } catch (_) {}

      Map<String, dynamic> result;
      if (desiredStageId == null) {
        // Try alternative stage discovery from existing tasks
        try {
          final alt = await TaskService().getStagesFromTasks();
          if (alt['success'] == true) {
            final stages =
                (alt['data'] as List<dynamic>?)
                    ?.map((e) => Map<String, dynamic>.from(e))
                    .toList() ??
                [];
            if (stages.isNotEmpty) {
              int? pick;
              if (statusKey == 'done') {
                stages.sort(
                  (a, b) => (a['sequence'] ?? 0).compareTo(b['sequence'] ?? 0),
                );
                pick = stages.last['id'] as int?;
              } else if (statusKey == 'in_progress') {
                final match = stages.firstWhere(
                  (m) => (m['name']?.toString().toLowerCase() ?? '').contains(
                    'progress',
                  ),
                  orElse: () => stages.first,
                );
                pick = match['id'] as int?;
              } else if (statusKey == 'hold') {
                final match = stages.firstWhere((m) {
                  final n = (m['name']?.toString().toLowerCase() ?? '');
                  return n.contains('hold') ||
                      n.contains('waiting') ||
                      n.contains('blocked');
                }, orElse: () => stages.first);
                pick = match['id'] as int?;
              } else {
                stages.sort(
                  (a, b) => (a['sequence'] ?? 0).compareTo(b['sequence'] ?? 0),
                );
                pick = stages.first['id'] as int?;
              }
              desiredStageId = pick;
            }
          }
        } catch (_) {}
      }

      if (desiredStageId != null) {
        result = await TaskService().updateTask(
          taskId: taskId,
          stageId: desiredStageId,
        );
      } else if (statusKey == 'done') {
        // As a last resort for completion, try built-in simple completion
        result = await TaskService().completeTaskSimple(taskId);
      } else {
        result = {
          'success': false,
          'error': 'No suitable stage available for update',
        };
      }

      final success = result['success'] == true;
      if (!success) {
        _tasks[idx]['state'] = oldState; // rollback
        _errorMessage = result['error']?.toString();
        notifyListeners();
        return false;
      }

      // On completion, cancel device schedules
      if (statusKey == 'done') {
        try {
          await NotificationService().cancelTaskNotifications(taskId);
        } catch (_) {}
      }

      // Ensure admins receive push about this status
      try {
        // Fetch task name for better message
        String taskName = 'Task';
        try {
          final taskInfo = await OdooClient.instance.searchRead(
            model: 'project.task',
            fields: ['id', 'name'],
            domain: [
              ['id', '=', taskId],
            ],
            limit: 1,
          );
          if (taskInfo['success'] == true) {
            final list = taskInfo['data'] as List<dynamic>?;
            if (list != null && list.isNotEmpty) {
              final m = Map<String, dynamic>.from(list.first);
              taskName = (m['name']?.toString() ?? taskName);
            }
          }
        } catch (_) {}

        final adminsResult = await TaskService().getAdminUsers();
        if (adminsResult['success'] == true) {
          final admins =
              (adminsResult['data'] as List<dynamic>?)
                  ?.map((e) => Map<String, dynamic>.from(e))
                  .toList() ??
              [];
          final adminIds = admins.map((u) => u['id']).whereType<int>().toList();
          if (adminIds.isNotEmpty) {
            await OdooClient.instance.sendTaskStatusNotification(
              userIds: adminIds,
              taskId: taskId,
              taskName: taskName,
              status: statusKey,
              stageId: desiredStageId,
            );
          }
        }
      } catch (e) {
        print('Failed to send admin status notification: $e');
      }

      // Refresh once to ensure UI reflects server values everywhere
      try {
        await Future.delayed(const Duration(milliseconds: 300));
        await loadUserData();
      } catch (_) {}

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Refresh user session
  Future<bool> refreshSession() async {
    try {
      final sessionResult = await OdooClient.instance.sessionInfo();
      if (sessionResult['success'] == true) {
        final userData = sessionResult['data'] as Map<String, dynamic>?;
        if (userData != null) {
          _currentUser = userData;
          print('Session refreshed successfully');
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Failed to refresh session: $e');
      return false;
    }
  }

  /// Log detailed task field information for debugging
  Future<void> logTaskFieldInfo(int taskId) async {
    try {
      print('=== Task Field Information for Task $taskId ===');

      final taskResult = await TaskService().getUserTasks(
        _currentUser?['uid'] ?? 0,
      );
      if (taskResult['success'] == true) {
        final tasks = taskResult['data'] as List<dynamic>?;
        if (tasks != null) {
          final task = tasks.firstWhere(
            (t) => t['id'] == taskId,
            orElse: () => {},
          );

          if (task.isNotEmpty) {
            print('Task found: ${task['name']}');
            print('All fields: ${task.keys.toList()}');

            // Log specific field types and values
            for (final field in [
              'stage_id',
              'state',
              'kanban_state',
              'priority',
            ]) {
              if (task.containsKey(field)) {
                final value = task[field];
                print('Field $field: type=${value.runtimeType}, value=$value');
              } else {
                print('Field $field: NOT PRESENT');
              }
            }
          } else {
            print('Task not found in user tasks');
          }
        }
      } else {
        print('Failed to get user tasks: ${taskResult['error']}');
      }

      print('=== End Task Field Information ===');
    } catch (e) {
      print('Exception while logging task field info: $e');
    }
  }

  /// Check available models in Odoo instance
  Future<void> checkAvailableModels() async {
    try {
      print('=== Checking Available Models ===');

      final modelsToCheck = [
        'project.task.type',
        'project.task',
        'project.project',
        'res.users',
        'ir.model',
      ];

      for (final model in modelsToCheck) {
        final exists = await OdooClient.instance.modelExists(model);
        print('Model $model: ${exists ? "EXISTS" : "NOT FOUND"}');
      }

      print('=== End Model Check ===');
    } catch (e) {
      print('Exception while checking models: $e');
    }
  }

  /// Log all available task stages for debugging
  Future<void> logAvailableStages() async {
    try {
      print('=== Available Task Stages ===');
      final stagesResult = await TaskService().getTaskStages();
      if (stagesResult['success'] == true) {
        final stages = stagesResult['data'] as List<dynamic>?;
        if (stages != null) {
          for (final stage in stages) {
            final stageMap = Map<String, dynamic>.from(stage);
            print(
              'Stage ID: ${stageMap['id']}, Name: ${stageMap['name']}, Sequence: ${stageMap['sequence']}, Is Closed: ${stageMap['is_closed']}',
            );
          }
        } else {
          print('No stages data available');
        }
      } else {
        print('Failed to get stages: ${stagesResult['error']}');
      }
      print('=== End Task Stages ===');
    } catch (e) {
      print('Exception while logging stages: $e');
    }
  }

  /// Check Odoo server connectivity
  Future<bool> checkServerConnectivity() async {
    try {
      final sessionResult = await OdooClient.instance.sessionInfo();
      return sessionResult['success'] == true;
    } catch (e) {
      print('Server connectivity check failed: $e');
      return false;
    }
  }

  /// Mark task as complete
  Future<bool> completeTask(int taskId) async {
    try {
      print('Attempting to complete task with ID: $taskId');

      // Check server connectivity first
      if (!await checkServerConnectivity()) {
        _errorMessage =
            'Cannot connect to server. Please check your internet connection.';
        notifyListeners();
        return false;
      }

      // Check if user is logged in
      if (_currentUser == null) {
        _errorMessage = 'User session expired. Please login again.';
        notifyListeners();
        return false;
      }

      // Check if task exists and is assigned to current user
      final task = _tasks.firstWhere(
        (task) => task['id'] == taskId,
        orElse: () => {},
      );

      if (task.isEmpty) {
        _errorMessage = 'Task not found or not accessible.';
        notifyListeners();
        return false;
      }

      // Check if task is already completed
      bool isCompleted = false;

      // First check if we have stage information and can determine completion
      if (task['stage_id'] != null) {
        try {
          final stagesResult = await TaskService().getTaskStages();
          if (stagesResult['success'] == true) {
            final stages = stagesResult['data'] as List<dynamic>?;
            if (stages != null) {
              // Handle different possible types for stage_id
              dynamic stageIdRaw = task['stage_id'];
              int? currentStageId;

              if (stageIdRaw != null) {
                if (stageIdRaw is int) {
                  currentStageId = stageIdRaw;
                } else if (stageIdRaw is bool) {
                  print(
                    'ViewModel: stage_id is boolean: $stageIdRaw - skipping stage check',
                  );
                  // Skip stage-based completion check for boolean stage_id
                } else if (stageIdRaw is List && stageIdRaw.isNotEmpty) {
                  // Sometimes stage_id comes as [id, name] tuple
                  currentStageId = stageIdRaw[0] as int?;
                  print(
                    'ViewModel: stage_id is tuple, extracted ID: $currentStageId',
                  );
                } else {
                  print(
                    'ViewModel: stage_id has unexpected type: ${stageIdRaw.runtimeType} - value: $stageIdRaw',
                  );
                  // Skip stage-based completion check for unexpected types
                }
              }

              if (currentStageId != null) {
                for (final stage in stages) {
                  final stageMap = Map<String, dynamic>.from(stage);
                  if (stageMap['id'] == currentStageId) {
                    final stageName =
                        stageMap['name']?.toString().toLowerCase() ?? '';
                    if (stageName.contains('done') ||
                        stageName.contains('completed') ||
                        stageName.contains('closed') ||
                        stageMap['is_closed'] == true) {
                      isCompleted = true;
                      print(
                        'Task is completed based on stage: ${stageMap['name']}',
                      );
                    }
                    break;
                  }
                }
              }
            }
          }
        } catch (e) {
          print('Failed to check stage completion status: $e');
        }
      }

      // Only check state field as a fallback, but be cautious since it's problematic
      if (!isCompleted && task['state'] != null) {
        // Check if state indicates completion, but don't rely on it heavily
        if (task['state'] == '3' ||
            task['state'] == 'done' ||
            task['state'] == 'completed') {
          isCompleted = true;
          print('Task is completed based on state: ${task['state']}');
        }
      }

      if (isCompleted) {
        _errorMessage = 'Task is already completed.';
        notifyListeners();
        return false;
      }

      print('Task validation passed. Proceeding with completion...');

      // Log task field information for debugging
      await logTaskFieldInfo(taskId);

      // First, try to find a completed stage
      int? completedStageId;
      try {
        final stagesResult = await TaskService().getTaskStages();
        if (stagesResult['success'] == true) {
          final stages = stagesResult['data'] as List<dynamic>?;
          if (stages != null) {
            // Look for a stage that indicates completion (e.g., "Done", "Completed", "Closed")
            for (final stage in stages) {
              final stageMap = Map<String, dynamic>.from(stage);
              final stageName =
                  stageMap['name']?.toString().toLowerCase() ?? '';
              if (stageName.contains('done') ||
                  stageName.contains('completed') ||
                  stageName.contains('closed') ||
                  stageMap['is_closed'] == true) {
                completedStageId = stageMap['id'] as int?;
                print(
                  'Found completed stage: ${stageMap['name']} with ID: $completedStageId',
                );
                break;
              }
            }
          }
        } else {
          print('Direct stage query failed: ${stagesResult['error']}');
          print('Trying alternative approach...');

          // Try alternative approach to get stages
          final altStagesResult = await TaskService().getStagesFromTasks();
          if (altStagesResult['success'] == true) {
            final stages = altStagesResult['data'] as List<dynamic>?;
            if (stages != null) {
              for (final stage in stages) {
                final stageMap = Map<String, dynamic>.from(stage);
                final stageName =
                    stageMap['name']?.toString().toLowerCase() ?? '';
                if (stageName.contains('done') ||
                    stageName.contains('completed') ||
                    stageName.contains('closed') ||
                    stageMap['is_closed'] == true) {
                  completedStageId = stageMap['id'] as int?;
                  print(
                    'Found completed stage via alternative method: ${stageMap['name']} with ID: $completedStageId',
                  );
                  break;
                }
              }
            }
          }
        }
      } catch (e) {
        print('Failed to get task stages: $e');
      }

      // If we found a completed stage, use it; otherwise, try the state approach
      Map<String, dynamic> result = {
        'success': false,
        'error': 'No update method succeeded',
      };
      if (completedStageId != null) {
        print(
          'Using stage_id approach with completed stage: $completedStageId',
        );
        result = await TaskService().updateTask(
          taskId: taskId,
          stageId: completedStageId,
        );
      } else {
        print('No completed stage found, trying alternative approaches...');

        // Since state field is causing errors, try to find any available stage
        try {
          final stagesResult = await TaskService().getTaskStages();
          if (stagesResult['success'] == true) {
            final stages = stagesResult['data'] as List<dynamic>?;
            if (stages != null && stages.isNotEmpty) {
              // Try to find a stage that might indicate progress or completion
              int? alternativeStageId;

              // First, look for stages with names that suggest completion
              for (final stage in stages) {
                final stageMap = Map<String, dynamic>.from(stage);
                final stageName =
                    stageMap['name']?.toString().toLowerCase() ?? '';
                if (stageName.contains('progress') ||
                    stageName.contains('review') ||
                    stageName.contains('testing') ||
                    stageName.contains('final')) {
                  alternativeStageId = stageMap['id'] as int?;
                  print(
                    'Found alternative stage: ${stageMap['name']} with ID: $alternativeStageId',
                  );
                  break;
                }
              }

              // If no alternative found, use the last stage (usually the final one)
              if (alternativeStageId == null && stages.isNotEmpty) {
                final lastStage = stages.last;
                alternativeStageId = lastStage['id'] as int?;
                print('Using last available stage: $alternativeStageId');
              }

              if (alternativeStageId != null) {
                result = await TaskService().updateTask(
                  taskId: taskId,
                  stageId: alternativeStageId,
                );
              } else {
                result = {
                  'success': false,
                  'error': 'No suitable task stage found for completion',
                };
              }
            } else {
              result = {'success': false, 'error': 'No task stages available'};
            }
          } else {
            print('Direct stage query failed, trying alternative approach...');

            // Try alternative approach to get stages
            final altStagesResult = await TaskService().getStagesFromTasks();
            if (altStagesResult['success'] == true) {
              final stages = altStagesResult['data'] as List<dynamic>?;
              if (stages != null && stages.isNotEmpty) {
                // Try to find a stage that might indicate progress or completion
                int? alternativeStageId;

                for (final stage in stages) {
                  final stageMap = Map<String, dynamic>.from(stage);
                  final stageName =
                      stageMap['name']?.toString().toLowerCase() ?? '';
                  if (stageName.contains('progress') ||
                      stageName.contains('review') ||
                      stageName.contains('testing') ||
                      stageName.contains('final')) {
                    alternativeStageId = stageMap['id'] as int?;
                    print(
                      'Found alternative stage via alternative method: ${stageMap['name']} with ID: $alternativeStageId',
                    );
                    break;
                  }
                }

                // If no alternative found, use the last stage
                if (alternativeStageId == null && stages.isNotEmpty) {
                  final lastStage = stages.last;
                  alternativeStageId = lastStage['id'] as int?;
                  print(
                    'Using last available stage via alternative method: $alternativeStageId',
                  );
                }

                if (alternativeStageId != null) {
                  result = await TaskService().updateTask(
                    taskId: taskId,
                    stageId: alternativeStageId,
                  );
                } else {
                  result = {
                    'success': false,
                    'error': 'No suitable task stage found for completion',
                  };
                }
              } else {
                result = {
                  'success': false,
                  'error': 'No task stages available',
                };
              }
            } else {
              result = {
                'success': false,
                'error':
                    'Failed to retrieve task stages via alternative method',
              };
            }
          }
        } catch (e) {
          print('Failed to try stage approach: $e');
          result = {
            'success': false,
            'error': 'Failed to update task stage: ${e.toString()}',
          };
        }

        // If all stage approaches failed, try the simple completion method
        if (result['success'] == false) {
          print('All stage approaches failed, trying simple completion...');
          try {
            final simpleResult = await TaskService().completeTaskSimple(taskId);
            if (simpleResult['success'] == true) {
              print('Simple completion succeeded!');
              result = simpleResult;
            } else {
              print('Simple completion also failed: ${simpleResult['error']}');

              // Try alternative completion method as final fallback
              print('Trying alternative completion method...');
              try {
                final altResult = await TaskService().completeTaskAlternative(
                  taskId,
                );
                if (altResult['success'] == true) {
                  print('Alternative completion succeeded!');
                  result = altResult;
                } else {
                  print(
                    'Alternative completion also failed: ${altResult['error']}',
                  );
                  result = {
                    'success': false,
                    'error':
                        'All completion methods failed. Last error: ${altResult['error']}',
                  };
                }
              } catch (e) {
                print('Exception in alternative completion: $e');
                result = {
                  'success': false,
                  'error':
                      'All completion methods failed with exception: ${e.toString()}',
                };
              }
            }
          } catch (e) {
            print('Exception in simple completion: $e');
            result = {
              'success': false,
              'error':
                  'All completion methods failed with exception: ${e.toString()}',
            };
          }
        }
      }

      print('Task completion result: $result');

      if (result['success'] == true) {
        // Update local task state
        final taskIndex = _tasks.indexWhere((task) => task['id'] == taskId);
        if (taskIndex != -1) {
          if (completedStageId != null) {
            _tasks[taskIndex]['stage_id'] = completedStageId;
            // Don't try to update state field since it's causing errors
            print('Updated task stage_id to: $completedStageId');
          } else {
            // For alternative stages, just update the stage_id
            // Extract stage_id from the result if available
            print('Task updated successfully with alternative approach');
          }
          print('Successfully updated local task state for task ID: $taskId');
          notifyListeners();

          // Refresh the task list to ensure consistency
          await Future.delayed(const Duration(milliseconds: 500));
          await loadUserData();
        } else {
          print('Warning: Task not found in local list for ID: $taskId');
          // Refresh the task list to get updated data
          await loadUserData();
        }
        return true;
      } else {
        final errorMsg = result['error'] ?? 'Failed to complete task';
        print('Task completion failed with error: $errorMsg');

        // Categorize errors for better user experience
        if (errorMsg.contains('permission') || errorMsg.contains('access')) {
          _errorMessage = 'You do not have permission to complete this task.';
        } else if (errorMsg.contains('not found') ||
            errorMsg.contains('does not exist')) {
          _errorMessage = 'Task not found. It may have been deleted.';
        } else if (errorMsg.contains('HTTP Error')) {
          _errorMessage = 'Server connection error. Please try again.';
        } else if (errorMsg.contains('Wrong value')) {
          _errorMessage =
              'Invalid task status value. Please contact administrator.';
        } else {
          _errorMessage = errorMsg;
        }

        notifyListeners();
        return false;
      }
    } catch (e) {
      final errorMsg = 'Failed to complete task: ${e.toString()}';
      print('Exception during task completion: $errorMsg');
      _errorMessage = errorMsg;
      notifyListeners();
      return false;
    }
  }

  /// Refresh data
  Future<void> refresh() async {
    await loadUserData();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Log task states for debugging
  Future<void> logTaskStates() async {
    try {
      print('=== Task States Debug Info ===');
      for (final task in _tasks) {
        final taskId = task['id'];
        final taskName = task['name'];
        final state = task['state'];
        final stageId = task['stage_id'];
        print(
          'Task ID: $taskId, Name: $taskName, State: $state, Stage ID: $stageId',
        );
      }
      print('=== End Task States Debug Info ===');
    } catch (e) {
      print('Failed to log task states: $e');
    }
  }

  /// Start a task (set to in progress)
  Future<bool> startTask(int taskId) async {
    try {
      print('Attempting to start task with ID: $taskId');

      // Check server connectivity first
      if (!await checkServerConnectivity()) {
        _errorMessage =
            'Cannot connect to server. Please check your internet connection.';
        notifyListeners();
        return false;
      }

      // Check if user is logged in
      if (_currentUser == null) {
        _errorMessage = 'User session expired. Please login again.';
        notifyListeners();
        return false;
      }

      // Check if task exists and is assigned to current user
      final task = _tasks.firstWhere(
        (task) => task['id'] == taskId,
        orElse: () => {},
      );

      if (task.isEmpty) {
        _errorMessage = 'Task not found or not accessible.';
        notifyListeners();
        return false;
      }

      // Find an "in progress" stage
      int? inProgressStageId;
      try {
        final stagesResult = await TaskService().getTaskStages();
        if (stagesResult['success'] == true) {
          final stages = stagesResult['data'] as List<dynamic>?;
          if (stages != null) {
            for (final stage in stages) {
              final stageMap = Map<String, dynamic>.from(stage);
              final stageName =
                  stageMap['name']?.toString().toLowerCase() ?? '';
              if (stageName.contains('progress') ||
                  stageName.contains('working') ||
                  stageName.contains('started') ||
                  stageName.contains('in progress')) {
                inProgressStageId = stageMap['id'] as int?;
                print(
                  'Found in progress stage: ${stageMap['name']} with ID: $inProgressStageId',
                );
                break;
              }
            }
          }
        }
      } catch (e) {
        print('Failed to get task stages: $e');
      }

      // Update the task
      Map<String, dynamic> result;
      if (inProgressStageId != null) {
        result = await TaskService().updateTask(
          taskId: taskId,
          stageId: inProgressStageId,
        );
      } else {
        // Fallback: try to update state field with correct Odoo values
        result = await TaskService().updateTask(
          taskId: taskId,
          state: 'open', // Use 'open' instead of '2' for in progress
        );
      }

      if (result['success'] == true) {
        // Update local task state
        final taskIndex = _tasks.indexWhere((task) => task['id'] == taskId);
        if (taskIndex != -1) {
          if (inProgressStageId != null) {
            _tasks[taskIndex]['stage_id'] = inProgressStageId;
          }
          _tasks[taskIndex]['state'] = 'open';
          print('Successfully updated local task state for task ID: $taskId');
          notifyListeners();
        }

        // Refresh the task list
        await Future.delayed(const Duration(milliseconds: 500));
        await loadUserData();
        return true;
      } else {
        final errorMsg = result['error'] ?? 'Failed to start task';
        _errorMessage = errorMsg;
        notifyListeners();
        return false;
      }
    } catch (e) {
      final errorMsg = 'Failed to start task: ${e.toString()}';
      print('Exception during task start: $errorMsg');
      _errorMessage = errorMsg;
      notifyListeners();
      return false;
    }
  }

  /// Set a task to pending
  Future<bool> setTaskPending(int taskId) async {
    try {
      print('Attempting to set task to pending with ID: $taskId');

      // Check server connectivity first
      if (!await checkServerConnectivity()) {
        _errorMessage =
            'Cannot connect to server. Please check your internet connection.';
        notifyListeners();
        return false;
      }

      // Check if user is logged in
      if (_currentUser == null) {
        _errorMessage = 'User session expired. Please login again.';
        notifyListeners();
        return false;
      }

      // Check if task exists and is assigned to current user
      final task = _tasks.firstWhere(
        (task) => task['id'] == taskId,
        orElse: () => {},
      );

      if (task.isEmpty) {
        _errorMessage = 'Task not found or not accessible.';
        notifyListeners();
        return false;
      }

      // Find a "pending" stage
      int? pendingStageId;
      try {
        final stagesResult = await TaskService().getTaskStages();
        if (stagesResult['success'] == true) {
          final stages = stagesResult['data'] as List<dynamic>?;
          if (stages != null) {
            for (final stage in stages) {
              final stageMap = Map<String, dynamic>.from(stage);
              final stageName =
                  stageMap['name']?.toString().toLowerCase() ?? '';
              if (stageName.contains('pending') ||
                  stageName.contains('waiting') ||
                  stageName.contains('on hold') ||
                  stageName.contains('blocked')) {
                pendingStageId = stageMap['id'] as int?;
                print(
                  'Found pending stage: ${stageMap['name']} with ID: $pendingStageId',
                );
                break;
              }
            }
          }
        }
      } catch (e) {
        print('Failed to get task stages: $e');
      }

      // Update the task
      Map<String, dynamic> result;
      if (pendingStageId != null) {
        result = await TaskService().updateTask(
          taskId: taskId,
          stageId: pendingStageId,
        );
      } else {
        // Fallback: try to update state field with correct Odoo values
        result = await TaskService().updateTask(
          taskId: taskId,
          state: 'open', // Use 'open' for pending tasks
        );
      }

      if (result['success'] == true) {
        // Update local task state
        final taskIndex = _tasks.indexWhere((task) => task['id'] == taskId);
        if (taskIndex != -1) {
          if (pendingStageId != null) {
            _tasks[taskIndex]['stage_id'] = pendingStageId;
          }
          _tasks[taskIndex]['state'] = 'open';
          print('Successfully updated local task state for task ID: $taskId');
          notifyListeners();
        }

        // Refresh the task list
        await Future.delayed(const Duration(milliseconds: 500));
        await loadUserData();
        return true;
      } else {
        final errorMsg = result['error'] ?? 'Failed to set task pending';
        _errorMessage = errorMsg;
        notifyListeners();
        return false;
      }
    } catch (e) {
      final errorMsg = 'Failed to set task pending: ${e.toString()}';
      print('Exception during task pending: $errorMsg');
      _errorMessage = errorMsg;
      notifyListeners();
      return false;
    }
  }
}
