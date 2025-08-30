import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/admin_dashboard_viewmodel.dart';

class ProjectDetailsPage extends StatefulWidget {
  final Map<String, dynamic> project;

  const ProjectDetailsPage({super.key, required this.project});

  @override
  State<ProjectDetailsPage> createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<ProjectDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminDashboardViewModel>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project['name'] ?? 'Project Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AdminDashboardViewModel>().refresh();
            },
          ),
        ],
      ),
      body: Consumer<AdminDashboardViewModel>(
        builder: (context, vm, child) {
          final projectId = widget.project['id'] as int?;
          final tasks = projectId != null
              ? vm.getTasksForProject(projectId)
              : [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project Header Card
                _buildProjectHeaderCard(),
                const SizedBox(height: 24),

                // Tasks Section
                Row(
                  children: [
                    const Text(
                      "Tasks",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${tasks.length}",
                        style: TextStyle(
                          color: Colors.purple.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/add_task');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Task'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tasks List
                if (tasks.isNotEmpty)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _buildTaskCard(context, vm, task);
                    },
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.task_alt,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No tasks found",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Create your first task for this project",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProjectHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue.shade100,
                child: Icon(
                  Icons.folder_open,
                  color: Colors.blue.shade700,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.project['name'] ?? 'Unnamed Project',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getProjectStatusColor(
                          widget.project['state'],
                        ).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getProjectStatusText(widget.project['state']),
                        style: TextStyle(
                          color: _getProjectStatusColor(
                            widget.project['state'],
                          ),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isValidDescription(widget.project['description'])) ...[
            const SizedBox(height: 16),
            Text(
              'Description',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getProjectDescription(widget.project['description']),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
          if (_isValidDate(widget.project['date_start']) ||
              _isValidDate(widget.project['date'])) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (_isValidDate(widget.project['date_start'])) ...[
                  Icon(Icons.play_arrow, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Started: ${_formatDate(widget.project['date_start'])}',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (_isValidDate(widget.project['date_start']) &&
                    _isValidDate(widget.project['date']))
                  const SizedBox(width: 24),
                if (_isValidDate(widget.project['date'])) ...[
                  Icon(Icons.stop, color: Colors.red.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Ends: ${_formatDate(widget.project['date'])}',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    AdminDashboardViewModel vm,
    Map<String, dynamic> task,
  ) {
    final userIds = task['user_ids'] as List<dynamic>?;
    final assignedUsers =
        userIds
            ?.map((id) => vm.getUserById(id))
            .whereType<Map<String, dynamic>>()
            .toList() ??
        [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _getTaskPriorityColor(
                  task['priority'],
                ).withOpacity(0.2),
                child: Icon(
                  _getTaskIcon(task),
                  color: _getTaskPriorityColor(task['priority']),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['name'] ?? 'Unnamed Task',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Priority: ${_getTaskPriorityText(task['priority'])}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getTaskStatusColor(task['state']).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getTaskStatusText(task['state']),
                  style: TextStyle(
                    color: _getTaskStatusColor(task['state']),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (task['description'] != null &&
              task['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              task['description'],
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
          if (assignedUsers.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                text: "Assigned to ",
                style: const TextStyle(color: Colors.black54, fontSize: 12),
                children: [
                  TextSpan(
                    text: assignedUsers
                        .map((user) => user['name'] ?? 'Unknown')
                        .join(', '),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (task['date_deadline'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.orange.shade600),
                const SizedBox(width: 4),
                Text(
                  'Deadline: ${_formatDate(task['date_deadline'])}',
                  style: TextStyle(
                    color: Colors.orange.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getProjectStatusColor(String? state) {
    // Since 'state' field doesn't exist for projects, use a default color
    return Colors.blue;
  }

  String _getProjectStatusText(String? state) {
    // Since 'state' field doesn't exist for projects, use a default status
    return 'Active';
  }

  Color _getTaskPriorityColor(String? priority) {
    switch (priority) {
      case '0':
        return Colors.green;
      case '1':
        return Colors.red;
      case '2':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _getTaskIcon(Map<String, dynamic> task) {
    switch (task['state']) {
      case '1':
        return Icons.radio_button_unchecked;
      case '2':
        return Icons.play_arrow;
      case '3':
        return Icons.check_circle;
      case '4':
        return Icons.cancel;
      default:
        return Icons.task_alt;
    }
  }

  Color _getTaskStatusColor(String? state) {
    switch (state) {
      case '1':
        return Colors.blue;
      case '2':
        return Colors.orange;
      case '3':
        return Colors.green;
      case '4':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getTaskStatusText(String? state) {
    switch (state) {
      case '1':
        return 'Open';
      case '2':
        return 'In Progress';
      case '3':
        return 'Done';
      case '4':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  String _getTaskPriorityText(String? priority) {
    switch (priority) {
      case '0':
        return 'Low';
      case '1':
        return 'High';
      case '2':
        return 'Medium';
      default:
        return 'Normal';
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return date.toString();
    }
  }

  bool _isValidDescription(dynamic description) {
    return description != null && description.toString().isNotEmpty;
  }

  String _getProjectDescription(dynamic description) {
    return description ?? 'No description available';
  }

  bool _isValidDate(dynamic date) {
    return date != null && date.toString().isNotEmpty;
  }
}
