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
      if (mounted) {
        context.read<AdminDashboardViewModel>().refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _stripHtmlTags(widget.project['name'] ?? 'Project Details'),
        ),
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
              if (mounted) {
                try {
                  context.read<AdminDashboardViewModel>().refresh();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to refresh: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: Consumer<AdminDashboardViewModel>(
        builder: (context, vm, child) {
          try {
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
                          Navigator.pushNamed(
                            context,
                            '/add_task',
                            arguments: {'projectId': widget.project['id']},
                          );
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
                        return RepaintBoundary(
                          child: _buildTaskCard(context, vm, task),
                        );
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

                  // Activity Summary Section
                  if (tasks.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildActivitySummaryCard(
                      List<Map<String, dynamic>>.from(tasks),
                    ),
                  ],
                ],
              ),
            );
          } catch (e) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading project details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try refreshing the page',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (mounted) {
                        context.read<AdminDashboardViewModel>().refresh();
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
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
                      _stripHtmlTags(
                        widget.project['name'] ?? 'Unnamed Project',
                      ),
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
                      _stripHtmlTags(task['name'] ?? 'Unnamed Task'),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  (() {
                    final statusText = _getTaskStatusText(task['state']);
                    if (statusText.isEmpty) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getTaskStatusColor(task['state']),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 2),
                          Icon(
                            _getTaskStatusIcon(task['state']),
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 2),
                        ],
                      ),
                    );
                  })(),
                  if (task['stage_id'] != null) ...[
                    const SizedBox(height: 6),
                    (() {
                      final stage = _getStageName(task['stage_id']);
                      if (stage.isEmpty) return const SizedBox.shrink();

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple.shade400,
                              Colors.purple.shade200,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.3),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.layers,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              stage,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      );
                    })(),
                  ],
                ],
              ),
            ],
          ),
          if (task['description'] != null &&
              task['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _stripHtmlTags(task['description']),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
          if (assignedUsers
              .where((u) => _stripHtmlTags(u['name']).isNotEmpty)
              .isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.blue.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: "Assigned to ",
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                      children: [
                        TextSpan(
                          text: assignedUsers
                              .map((user) => _stripHtmlTags(user['name']))
                              .where((name) => name.isNotEmpty)
                              .join(', '),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (task['date_start'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.play_arrow, size: 14, color: Colors.green.shade600),
                const SizedBox(width: 4),
                Text(
                  'Start: ${_formatDate(task['date_start'])}',
                  style: TextStyle(
                    color: Colors.green.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          if (task['date_deadline'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.orange.shade600),
                const SizedBox(width: 4),
                Text(
                  'Deadline: ${_formatDate(task['write_date'])}',
                  style: TextStyle(
                    color: Colors.orange.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          // Last Updated Information
          // if (task['write_date'] != null) ...[
          //   const SizedBox(height: 8),
          //   Row(
          //     children: [
          //       Icon(Icons.update, size: 14, color: Colors.grey.shade600),
          //       const SizedBox(width: 4),
          //       Text(
          //         'Last updated: ${_formatDate(task['write_date'])}',
          //         style: TextStyle(
          //           color: Colors.grey.shade600,
          //           fontSize: 11,
          //           fontWeight: FontWeight.w400,
          //         ),
          //       ),
          //     ],
          //   ),
          // ],
        ],
      ),
    );
  }

  // Clean HTML tags and special characters from text
  String _stripHtmlTags(dynamic text) {
    if (text == null || text == false) {
      return '';
    }

    String cleanText = text.toString();
    cleanText = cleanText.replaceAll(RegExp(r'<[^>]*>'), '');
    cleanText = cleanText
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');

    return cleanText.trim();
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
      case 'open':
      case 'draft':
        return Colors.blue;
      case '2':
      case 'in_progress':
        return Colors.orange;
      case '3':
      case 'done':
        return Colors.green;
      case '4':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getTaskStatusText(String? state) {
    switch (state) {
      case '1':
      case 'open':
        return 'Open';
      case '2':
      case 'in_progress':
        return 'In Progress';
      case '3':
      case 'done':
        return 'Done';
      case '4':
      case 'cancelled':
        return 'Cancelled';
      case 'draft':
        return 'Draft';
      default:
        return '';
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
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return date.toString();
    }
  }

  bool _isValidDescription(dynamic description) {
    if (description == null || description == false) {
      return false;
    }
    final cleanDesc = _stripHtmlTags(description);
    return cleanDesc.isNotEmpty;
  }

  String _getProjectDescription(dynamic description) {
    if (description == null || description == false) {
      return 'No description available';
    }
    return _stripHtmlTags(description);
  }

  bool _isValidDate(dynamic date) {
    return date != null && date.toString().isNotEmpty;
  }

  // Get stage name from stage_id
  String _getStageName(dynamic stageId) {
    if (stageId == null) return '';

    if (stageId is List && stageId.length > 1) {
      return stageId[1]?.toString() ?? '';
    } else if (stageId is int) {
      return 'Stage $stageId';
    } else {
      return stageId.toString();
    }
  }

  IconData _getTaskStatusIcon(String? state) {
    switch (state) {
      case '1':
      case 'open':
      case 'draft':
        return Icons.fiber_new;
      case '2':
      case 'in_progress':
        return Icons.hourglass_bottom;
      case '3':
      case 'done':
        return Icons.check_circle;
      case '4':
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildActivitySummaryCard(List<Map<String, dynamic>> tasks) {
    final openTasks = tasks
        .where(
          (task) =>
              task['state'] == '1' ||
              task['state'] == 'open' ||
              task['state'] == 'draft',
        )
        .length;
    final inProgressTasks = tasks
        .where((task) => task['state'] == '2' || task['state'] == 'in_progress')
        .length;
    final doneTasks = tasks
        .where((task) => task['state'] == '3' || task['state'] == 'done')
        .length;
    final cancelledTasks = tasks
        .where((task) => task['state'] == '4' || task['state'] == 'cancelled')
        .length;

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
          const Text(
            "Activity Summary",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildActivityItem("Open Tasks", openTasks, Colors.blue),
          const SizedBox(height: 12),
          _buildActivityItem(
            "In Progress Tasks",
            inProgressTasks,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildActivityItem("Done Tasks", doneTasks, Colors.green),
          const SizedBox(height: 12),
          _buildActivityItem("Cancelled Tasks", cancelledTasks, Colors.red),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withOpacity(0.5),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$title: $count',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}
