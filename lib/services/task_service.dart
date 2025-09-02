import 'package:task_management/services/odoo_client.dart';
import 'package:task_management/services/task_notification_manager.dart';

class TaskService {
  static final TaskService _instance = TaskService._internal();
  factory TaskService() => _instance;
  TaskService._internal();

  /// Get all projects
  Future<Map<String, dynamic>> getAllProjects() async {
    return await OdooClient.instance.searchRead(
      model: 'project.project',
      fields: [
        'id',
        'name',
        'description',
        'user_id',
        'partner_id',
        'date_start',
        'date',
        'privacy_visibility',
        'task_count',
        'create_date',
        'write_date',
      ],
      domain: [],
      limit: 100,
    );
  }

  /// Get projects for specific user
  Future<Map<String, dynamic>> getUserProjects(int userId) async {
    return await OdooClient.instance.searchRead(
      model: 'project.project',
      fields: [
        'id',
        'name',
        'description',
        'user_id',
        'partner_id',
        'date_start',
        'date',
        'state',
        'privacy_visibility',
        'task_count',
        'create_date',
        'write_date',
      ],
      domain: [
        ['user_id', '=', userId],
      ],
      limit: 100,
    );
  }

  /// Get all tasks
  Future<Map<String, dynamic>> getAllTasks() async {
    return await OdooClient.instance.searchRead(
      model: 'project.task',
      fields: [
        'id',
        'name',
        'description',
        'project_id',
        'user_ids',
        'stage_id',
        'priority',
        'date_deadline',
        'state',
        'create_date',
        'write_date',
      ],
      domain: [],
      limit: 100,
    );
  }

  /// Get tasks assigned to specific user
  Future<Map<String, dynamic>> getUserTasks(int userId) async {
    return await OdooClient.instance.searchRead(
      model: 'project.task',
      fields: [
        'id',
        'name',
        'description',
        'project_id',
        'user_ids',
        'stage_id',
        'priority',
        'date_deadline',
        'state',
        'create_date',
        'write_date',
      ],
      domain: [
        [
          'user_ids',
          'in',
          [userId],
        ],
        ['state', '!=', '4'], // Exclude cancelled tasks
      ],
      limit: 100,
    );
  }

  /// Get tasks for specific project
  Future<Map<String, dynamic>> getProjectTasks(int projectId) async {
    return await OdooClient.instance.searchRead(
      model: 'project.task',
      fields: [
        'id',
        'name',
        'description',
        'user_ids',
        'project_id',
        'stage_id',
        'priority',
        'date_deadline',
        'create_date',
        'write_date',
        'kanban_state',
        'state',
      ],
      domain: [
        ['project_id', '=', projectId],
      ],
      limit: 100,
    );
  }

  /// Create project
  Future<Map<String, dynamic>> createProject({
    required String name,
    String? description,
    DateTime? dateStart,
    DateTime? date,
  }) async {
    final values = <String, dynamic>{'name': name};

    if (description != null && description.isNotEmpty) {
      values['description'] = description;
    }
    if (dateStart != null) {
      values['date_start'] = dateStart.toIso8601String().split('T')[0];
    }
    if (date != null) {
      values['date'] = date.toIso8601String().split('T')[0];
    }

    return await OdooClient.instance.create(
      model: 'project.project',
      values: values,
    );
  }

  /// Create task
  Future<Map<String, dynamic>> createTask({
    required String name,
    required String description,
    int? projectId,
    List<int>? userIds,
    int? stageId,
    String? priority,
    DateTime? deadline,
    DateTime? dateStart,
    int? allocatedMinutes, // NEW: allocated time in minutes
  }) async {
    final values = <String, dynamic>{'name': name, 'description': description};

    if (projectId != null) {
      values['project_id'] = projectId;
    }
    if (userIds != null && userIds.isNotEmpty) {
      values['user_ids'] = userIds;
    }
    if (stageId != null) {
      values['stage_id'] = stageId;
    }
    if (priority != null) {
      values['priority'] = priority;
    }
    if (deadline != null) {
      // Format as 'YYYY-MM-DD HH:MM:SS' (Odoo expected format)
      final formattedDeadline =
          '${deadline.year.toString().padLeft(4, '0')}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')} ${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}:${deadline.second.toString().padLeft(2, '0')}';
      values['date_deadline'] = formattedDeadline;
    }

    // Debug: print values being sent
    print('TaskService.createTask -> values: ' + values.toString());

    final result = await OdooClient.instance.create(
      model: 'project.task',
      values: values,
    );

    // Debug: print result received
    print('TaskService.createTask <- result: ' + result.toString());

    // If created, ask backend to send push to assigned users immediately
    if (result['success'] == true) {
      try {
        final createdTaskId = result['id'] as int?;
        if (createdTaskId != null && userIds != null && userIds.isNotEmpty) {
          await OdooClient.instance.sendTaskAssignedNotification(
            userIds: userIds,
            taskId: createdTaskId,
            taskName: name,
            projectName: null,
            allocatedMinutes: allocatedMinutes,
            deadline: deadline,
          );
        }
      } catch (e) {
        print('Failed to request push for task assignment: $e');
      }
    }

    return result;
  }

  /// Update task
  Future<Map<String, dynamic>> updateTask({
    required int taskId,
    String? name,
    String? description,
    int? projectId,
    List<int>? userIds,
    int? stageId,
    String? priority,
    DateTime? deadline,
    String? state,
    String? kanban_state,
  }) async {
    final values = <String, dynamic>{};
    if (name != null) values['name'] = name;
    if (description != null) values['description'] = description;
    if (projectId != null) values['project_id'] = projectId;
    if (userIds != null) values['user_ids'] = userIds;
    if (stageId != null) values['stage_id'] = stageId;
    if (priority != null) values['priority'] = priority;
    if (deadline != null) {
      final formattedDeadline =
          '${deadline.year.toString().padLeft(4, '0')}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')} ${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}:${deadline.second.toString().padLeft(2, '0')}';
      values['date_deadline'] = formattedDeadline;
    }
    if (state != null) values['state'] = state;
    // NOTE: 'kanban_state' is not available on your server's project.task model; don't send it.
    // if (kanban_state != null) values['kanban_state'] = kanban_state;

    if (values.isEmpty) {
      return {'success': false, 'error': 'No fields to update'};
    }

    print('Updating task $taskId with values: $values');

    final result = await OdooClient.instance.update(
      model: 'project.task',
      recordId: taskId,
      values: values,
    );

    // Handle notifications for task completion or cancellation
    if (result['success'] == true) {
      try {
        // Cancel local device schedules when completed/cancelled
        if (state == '3' || (state?.toLowerCase() == 'done')) {
          await TaskNotificationManager().handleTaskCompletion(taskId);
        } else if (state == '4' ||
            (state?.toLowerCase().contains('cancel') ?? false)) {
          await TaskNotificationManager().handleTaskCancellation(taskId);
        }

        // Notify admins about status update (completed/hold/in_progress/etc.)
        // Derive a friendly status label
        String statusLabel = 'updated';
        final s = state?.toLowerCase();
        if (s == '3' || (s?.contains('done') ?? false) || s == 'done') {
          statusLabel = 'completed';
        } else if (s == '4' || (s?.contains('cancel') ?? false)) {
          statusLabel = 'cancelled';
        } else if ((s?.contains('hold') ?? false)) {
          statusLabel = 'hold';
        } else if ((s?.contains('progress') ?? false) ||
            (s?.contains('in_progress') ?? false) ||
            s == '01_in_progress') {
          statusLabel = 'in_progress';
        }

        // Fetch task name for message
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

        // Get admin users to notify (default: login == 'admin')
        final adminsResult = await getAdminUsers();
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
              status: statusLabel,
              stageId: stageId,
            );
          }
        }
      } catch (e) {
        print('Error handling task update notifications: $e');
      }
    }

    print('Task update result: $result');
    return result;
  }

  /// Get admin users (basic: login == admin)
  Future<Map<String, dynamic>> getAdminUsers() async {
    try {
      final res = await OdooClient.instance.searchRead(
        model: 'res.users',
        fields: ['id', 'name', 'login', 'email'],
        domain: [
          ['active', '=', true],
          ['login', '=', 'admin'],
        ],
        limit: 10,
      );
      return res;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Update project
  Future<Map<String, dynamic>> updateProject({
    required int projectId,
    String? name,
    String? description,
    DateTime? dateStart,
    DateTime? date,
  }) async {
    final values = <String, dynamic>{};

    if (name != null) {
      values['name'] = name;
    }
    if (description != null) {
      values['description'] = description;
    }
    if (dateStart != null) {
      values['date_start'] = dateStart.toIso8601String().split('T')[0];
    }
    if (date != null) {
      values['date'] = date.toIso8601String().split('T')[0];
    }

    return await OdooClient.instance.update(
      model: 'project.project',
      recordId: projectId,
      values: values,
    );
  }

  /// Delete project
  Future<Map<String, dynamic>> deleteProject(int projectId) async {
    return await OdooClient.instance.delete(
      model: 'project.project',
      recordId: projectId,
    );
  }

  /// Complete task by updating other fields when stage-based completion fails
  Future<Map<String, dynamic>> completeTaskAlternative(int taskId) async {
    try {
      print(
        'TaskService: Attempting alternative task completion for task $taskId...',
      );

      // Try to complete the task by updating other fields that might indicate completion
      // This is a fallback when stage-based completion is not possible

      // First, check what fields are available on the task
      final taskResult = await OdooClient.instance.searchRead(
        model: 'project.task',
        fields: ['id', 'name', 'kanban_state', 'priority', 'date_deadline'],
        domain: [
          ['id', '=', taskId],
        ],
        limit: 1,
      );

      if (taskResult['success'] == true) {
        final tasks = taskResult['data'] as List<dynamic>?;
        if (tasks != null && tasks.isNotEmpty) {
          final task = Map<String, dynamic>.from(tasks.first);
          print('TaskService: Task fields available: ${task.keys.toList()}');

          // Try to update kanban_state to 'done' if it exists
          try {
            final kanbanResult = await updateTask(
              taskId: taskId,
              kanban_state: 'done',
            );

            if (kanbanResult['success'] == true) {
              print('TaskService: Successfully updated kanban_state to done');
              return kanbanResult;
            } else {
              print(
                'TaskService: Failed to update kanban_state: ${kanbanResult['error']}',
              );
            }
          } catch (e) {
            print('TaskService: Exception updating kanban_state: $e');
          }

          // If kanban_state update failed, try updating priority to indicate completion
          try {
            final priorityResult = await updateTask(
              taskId: taskId,
              priority: '0', // Set to lowest priority to indicate completion
            );

            if (priorityResult['success'] == true) {
              print(
                'TaskService: Successfully updated priority to indicate completion',
              );
              return priorityResult;
            } else {
              print(
                'TaskService: Failed to update priority: ${priorityResult['error']}',
              );
            }
          } catch (e) {
            print('TaskService: Exception updating priority: $e');
          }

          // If all else fails, try to add a completion note in the description
          try {
            final currentTask = await OdooClient.instance.searchRead(
              model: 'project.task',
              fields: ['id', 'description'],
              domain: [
                ['id', '=', taskId],
              ],
              limit: 1,
            );

            if (currentTask['success'] == true) {
              final currentTasks = currentTask['data'] as List<dynamic>?;
              if (currentTasks != null && currentTasks.isNotEmpty) {
                final currentTaskData = Map<String, dynamic>.from(
                  currentTasks.first,
                );
                final currentDescription = currentTaskData['description'] ?? '';
                final completionNote =
                    '\n\n[COMPLETED ON ${DateTime.now().toIso8601String()}]';
                final newDescription = currentDescription + completionNote;

                final descriptionResult = await updateTask(
                  taskId: taskId,
                  description: newDescription,
                );

                if (descriptionResult['success'] == true) {
                  print(
                    'TaskService: Successfully added completion note to description',
                  );
                  return descriptionResult;
                }
              }
            }
          } catch (e) {
            print('TaskService: Exception updating description: $e');
          }

          return {
            'success': false,
            'error': 'All alternative completion methods failed',
          };
        }
      }

      return {
        'success': false,
        'error': 'Failed to get task information for alternative completion',
      };
    } catch (e) {
      print('TaskService: Exception in completeTaskAlternative: $e');
      return {
        'success': false,
        'error': 'Exception in alternative completion: ${e.toString()}',
      };
    }
  }

  /// Simple task completion by moving to next stage (fallback method)
  Future<Map<String, dynamic>> completeTaskSimple(int taskId) async {
    try {
      print(
        'TaskService: Attempting simple task completion for task $taskId...',
      );

      // First, get the current task to see its current stage
      final taskResult = await OdooClient.instance.searchRead(
        model: 'project.task',
        fields: ['id', 'stage_id', 'name'],
        domain: [
          ['id', '=', taskId],
        ],
        limit: 1,
      );

      if (taskResult['success'] == true) {
        final tasks = taskResult['data'] as List<dynamic>?;
        if (tasks != null && tasks.isNotEmpty) {
          final task = Map<String, dynamic>.from(tasks.first);

          // Handle different possible types for stage_id
          dynamic stageIdRaw = task['stage_id'];
          int? currentStageId;

          if (stageIdRaw != null) {
            if (stageIdRaw is int) {
              currentStageId = stageIdRaw;
            } else if (stageIdRaw is bool) {
              print(
                'TaskService: stage_id is boolean: $stageIdRaw - cannot use for stage movement',
              );
              return {
                'success': false,
                'error':
                    'Task stage_id is boolean, cannot determine stage for movement',
              };
            } else if (stageIdRaw is List && stageIdRaw.isNotEmpty) {
              // Sometimes stage_id comes as [id, name] tuple
              currentStageId = stageIdRaw[0] as int?;
              print(
                'TaskService: stage_id is tuple, extracted ID: $currentStageId',
              );
            } else {
              print(
                'TaskService: stage_id is unexpected type: ${stageIdRaw.runtimeType} - value: $stageIdRaw',
              );
              return {
                'success': false,
                'error':
                    'Task stage_id has unexpected type: ${stageIdRaw.runtimeType}',
              };
            }
          }

          if (currentStageId != null) {
            print('TaskService: Current stage ID: $currentStageId');

            // Try to move to a different stage (increment by 1 as a simple approach)
            final newStageId = currentStageId + 1;
            print('TaskService: Attempting to move to stage ID: $newStageId');

            final updateResult = await updateTask(
              taskId: taskId,
              stageId: newStageId,
            );

            if (updateResult['success'] == true) {
              print(
                'TaskService: Successfully moved task to stage $newStageId',
              );
              return updateResult;
            } else {
              print(
                'TaskService: Failed to move to stage $newStageId: ${updateResult['error']}',
              );

              // If incrementing failed, try decrementing
              final decrementStageId = currentStageId - 1;
              if (decrementStageId > 0) {
                print(
                  'TaskService: Trying decrement to stage ID: $decrementStageId',
                );
                final decrementResult = await updateTask(
                  taskId: taskId,
                  stageId: decrementStageId,
                );

                if (decrementResult['success'] == true) {
                  print(
                    'TaskService: Successfully moved task to stage $decrementStageId',
                  );
                  return decrementResult;
                }
              }

              return updateResult;
            }
          } else {
            return {'success': false, 'error': 'Task has no current stage'};
          }
        }
      }

      return {'success': false, 'error': 'Failed to get task information'};
    } catch (e) {
      print('TaskService: Exception in completeTaskSimple: $e');
      return {
        'success': false,
        'error': 'Exception in simple completion: ${e.toString()}',
      };
    }
  }

  /// Get stage information from existing tasks (alternative to getTaskStages)
  Future<Map<String, dynamic>> getStagesFromTasks() async {
    try {
      print('TaskService: Attempting to get stages from existing tasks...');

      // Get a few tasks to extract stage information
      final tasksResult = await OdooClient.instance.searchRead(
        model: 'project.task',
        fields: ['id', 'stage_id', 'name'],
        domain: [],
        limit: 50,
      );

      if (tasksResult['success'] == true) {
        final tasks = tasksResult['data'] as List<dynamic>?;
        if (tasks != null && tasks.isNotEmpty) {
          // Extract unique stage IDs from tasks
          final Set<int> stageIds = {};
          for (final task in tasks) {
            final taskMap = Map<String, dynamic>.from(task);
            final stageIdRaw = taskMap['stage_id'];

            // Handle different possible types for stage_id
            int? stageId;
            if (stageIdRaw != null) {
              if (stageIdRaw is int) {
                stageId = stageIdRaw;
              } else if (stageIdRaw is bool) {
                print(
                  'TaskService: Skipping task with boolean stage_id: $stageIdRaw',
                );
                continue; // Skip this task
              } else if (stageIdRaw is List && stageIdRaw.isNotEmpty) {
                // Sometimes stage_id comes as [id, name] tuple
                stageId = stageIdRaw[0] as int?;
                print('TaskService: Extracted stage_id from tuple: $stageId');
              } else {
                print(
                  'TaskService: Unexpected stage_id type: ${stageIdRaw.runtimeType} - value: $stageIdRaw',
                );
                continue; // Skip this task
              }
            }

            if (stageId != null) {
              stageIds.add(stageId);
            }
          }

          print(
            'TaskService: Found ${stageIds.length} unique stage IDs: $stageIds',
          );

          // Now get details for each stage
          if (stageIds.isNotEmpty) {
            final stageDetails = await OdooClient.instance.searchRead(
              model: 'project.task.type',
              fields: ['id', 'name', 'sequence', 'is_closed'],
              domain: [
                ['id', 'in', stageIds.toList()],
              ],
              limit: 100,
            );

            print('TaskService: Stage details result: $stageDetails');
            return stageDetails;
          }
        }
      }

      return {'success': false, 'error': 'No stage information found in tasks'};
    } catch (e) {
      print('TaskService: Exception in getStagesFromTasks: $e');
      return {
        'success': false,
        'error': 'Exception while getting stages from tasks: ${e.toString()}',
      };
    }
  }

  /// Get available task stages
  Future<Map<String, dynamic>> getTaskStages() async {
    try {
      print('TaskService: Attempting to get task stages...');

      final result = await OdooClient.instance.searchRead(
        model: 'project.task.type',
        // Some servers don't expose 'is_closed' or 'fold'
        fields: ['id', 'name', 'sequence'],
        domain: [],
        limit: 100,
      );

      print('TaskService: getTaskStages result: $result');
      return result;
    } catch (e) {
      print('TaskService: Exception in getTaskStages: $e');
      return {
        'success': false,
        'error': 'Exception while getting task stages: ${e.toString()}',
      };
    }
  }

  /// Get users
  Future<Map<String, dynamic>> getUsers() async {
    return await OdooClient.instance.searchRead(
      model: 'res.users',
      fields: ['id', 'name', 'email', 'login'],
      domain: [
        ['active', '=', true],
      ],
      limit: 100,
    );
  }

  /// Get partners/contacts
  Future<Map<String, dynamic>> getPartners() async {
    return await OdooClient.instance.searchRead(
      model: 'res.partner',
      fields: ['id', 'name', 'email', 'phone'],
      domain: [
        ['active', '=', true],
        ['is_company', '=', false],
      ],
      limit: 100,
    );
  }

  /// Get valid state values for tasks by checking existing tasks
  Future<Map<String, dynamic>> getTaskStateValues() async {
    try {
      // Get a few tasks to see what state values are actually used
      final result = await getAllTasks();
      if (result['success'] == true && result['data'] != null) {
        final tasks = result['data'] as List<dynamic>;
        final stateValues = <String>{};

        for (final task in tasks) {
          final taskMap = Map<String, dynamic>.from(task);
          final state = taskMap['state']?.toString();
          if (state != null && state.isNotEmpty) {
            stateValues.add(state);
          }
        }

        print('Found task state values: $stateValues');

        // Return the valid state values we found
        return {'success': true, 'data': stateValues.toList()};
      }

      // Fallback: return common Odoo task state values
      return {
        'success': true,
        'data': ['draft', 'open', 'done', 'cancelled'],
      };
    } catch (e) {
      print('Failed to get task state values: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
