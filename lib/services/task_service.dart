import 'package:task_management/services/odoo_client.dart';

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
      values['date_deadline'] = deadline.toIso8601String().split(
        'T',
      )[0]; // Only date part YYYY-MM-DD
    }

    return await OdooClient.instance.create(
      model: 'project.task',
      values: values,
    );
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
    if (deadline != null) values['date_deadline'] = deadline.toIso8601String();
    if (state != null) values['state'] = state;
    if (kanban_state != null) values['kanban_state'] = kanban_state;

    if (values.isEmpty) {
      return {'success': false, 'error': 'No fields to update'};
    }

    print('Updating task $taskId with values: $values');

    final result = await OdooClient.instance.update(
      model: 'project.task',
      recordId: taskId,
      values: values,
    );

    print('Task update result: $result');
    return result;
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
        fields: ['id', 'name', 'sequence', 'is_closed', 'fold'],
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
}
