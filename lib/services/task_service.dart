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

  /// Get user tasks
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

  /// Create new project
  Future<Map<String, dynamic>> createProject({
    required String name,
    String? description,
    int? userId,
    int? partnerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final values = {
      'name': name,
      if (description != null) 'description': description,
      if (userId != null) 'user_id': userId,
      if (partnerId != null) 'partner_id': partnerId,
      if (startDate != null) 'date_start': startDate.toIso8601String(),
      if (endDate != null) 'date': endDate.toIso8601String(),
      'state': 'open',
      'privacy_visibility': 'employees',
    };

    return await OdooClient.instance.create(
      model: 'project.project',
      values: values,
    );
  }

  /// Create new task
  Future<Map<String, dynamic>> createTask({
    required String name,
    required String description,
    int? projectId,
    List<int>? userIds,
    int? stageId,
    String? priority,
    DateTime? deadline,
  }) async {
    final values = {
      'name': name,
      'description': description,
      if (projectId != null) 'project_id': projectId,
      if (userIds != null) 'user_ids': userIds,
      if (stageId != null) 'stage_id': stageId,
      if (priority != null) 'priority': priority,
      if (deadline != null) 'date_deadline': deadline.toIso8601String(),
    };

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

    if (values.isEmpty) {
      return {'success': false, 'error': 'No fields to update'};
    }

    return await OdooClient.instance.update(
      model: 'project.task',
      recordId: taskId,
      values: values,
    );
  }

  /// Update project
  Future<Map<String, dynamic>> updateProject({
    required int projectId,
    String? name,
    String? description,
    int? userId,
    DateTime? startDate,
    DateTime? endDate,
    String? state,
  }) async {
    final values = <String, dynamic>{};
    if (name != null) values['name'] = name;
    if (description != null) values['description'] = description;
    if (userId != null) values['user_id'] = userId;
    if (startDate != null) values['date_start'] = startDate.toIso8601String();
    if (endDate != null) values['date'] = endDate.toIso8601String();
    if (state != null) values['state'] = state;

    if (values.isEmpty) {
      return {'success': false, 'error': 'No fields to update'};
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

  /// Get task stages
  Future<Map<String, dynamic>> getTaskStages() async {
    return await OdooClient.instance.searchRead(
      model: 'project.task.type',
      fields: ['id', 'name', 'sequence', 'is_closed'],
      domain: [],
      limit: 50,
    );
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
