import 'package:flutter/material.dart';
import '../services/task_service.dart';
import '../services/odoo_client.dart';

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

      // Log available stages for debugging
      await logAvailableStages();
      await checkAvailableModels();
    } catch (e) {
      _errorMessage = 'Failed to load data: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
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
}
