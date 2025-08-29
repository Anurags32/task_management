import 'package:task_management/services/odoo_client.dart';

class TaskService {
  TaskService._();
  static final TaskService instance = TaskService._();

  Future<List<Map<String, dynamic>>> fetchTasks({
    bool onlyMyTasks = true,
  }) async {
    // Example for project.task; adjust domain based on your needs
    final domain = onlyMyTasks ? [] : [];
    final fields = <String>['name', 'user_id', 'date_deadline', 'stage_id'];
    final result = await OdooClient.instance.searchRead(
      model: 'project.task',
      domain: domain,
      fields: fields,
      limit: 50,
    );
    return result.cast<Map<String, dynamic>>();
  }

  Future<int?> createTask({
    required String name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final values = <String, dynamic>{
      'name': name,
      if (description != null) 'description': description,
      if (endDate != null) 'date_deadline': endDate.toIso8601String(),
    };
    return OdooClient.instance.create(model: 'project.task', values: values);
  }
}
