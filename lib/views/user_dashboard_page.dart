import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_dashboard_viewmodel.dart';

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserDashboardViewModel>().loadUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background blobs
          Positioned(top: 80, left: -60, child: _buildBlob(Colors.green, 200)),
          Positioned(
            top: 40,
            right: -80,
            child: _buildBlob(Colors.yellow, 220),
          ),
          Positioned(
            bottom: 300,
            left: -70,
            child: _buildBlob(Colors.blue, 240),
          ),
          Positioned(
            bottom: 150,
            right: -60,
            child: _buildBlob(Colors.purple, 200),
          ),

          SafeArea(
            child: Consumer<UserDashboardViewModel>(
              builder: (context, vm, child) {
                if (vm.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (vm.errorMessage != null) {
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
                          vm.errorMessage!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => vm.refresh(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Logout Button
                      _buildHeader(vm),
                      const SizedBox(height: 32),

                      // Latest Task Section
                      if (vm.latestTask != null) ...[
                        _buildLatestTaskSection(vm),
                        const SizedBox(height: 32),
                      ],

                      // Projects Summary Section
                      if (vm.projects.isNotEmpty) ...[
                        _buildProjectsSection(vm),
                        const SizedBox(height: 24),
                      ],

                      // All Tasks Section
                      _buildAllTasksSection(vm),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(UserDashboardViewModel vm) {
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.purple.shade100,
          child: Icon(Icons.person, color: Colors.purple.shade700, size: 30),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Welcome Back!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                "You have ${vm.tasks.length} assigned tasks",
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        // Logout Button
        IconButton(
          onPressed: () => _showLogoutDialog(context, vm),
          icon: const Icon(Icons.logout),
          style: IconButton.styleFrom(
            backgroundColor: Colors.red.shade50,
            foregroundColor: Colors.red.shade600,
            elevation: 2,
          ),
        ),
        const SizedBox(width: 8),
        // Refresh Button
        IconButton(
          onPressed: () => vm.refresh(),
          icon: const Icon(Icons.refresh),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            elevation: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildLatestTaskSection(UserDashboardViewModel vm) {
    final latestTask = vm.latestTask!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star, color: Colors.amber.shade600, size: 24),
            const SizedBox(width: 8),
            const Text(
              "Latest Task",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "NEW",
                style: TextStyle(
                  color: Colors.amber.shade700,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Latest Task Card
        GestureDetector(
          onTap: () => _navigateToTaskDetails(latestTask),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade50, Colors.orange.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade200, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getTaskIcon(latestTask),
                        color: _getTaskStatusColor(latestTask['state']),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            latestTask['name'] ?? 'Unnamed Task',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getProjectName(vm, latestTask) ?? 'No Project',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.amber.shade600,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Task Status and Priority
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getTaskStatusColor(
                          latestTask['state'],
                        ).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getTaskStatusText(latestTask['state']),
                        style: TextStyle(
                          color: _getTaskStatusColor(latestTask['state']),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      _getTaskPriorityIcon(latestTask['priority']),
                      size: 16,
                      color: _getTaskPriorityColor(latestTask['priority']),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getTaskPriorityText(latestTask['priority']),
                      style: TextStyle(
                        color: _getTaskPriorityColor(latestTask['priority']),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (latestTask['date_deadline'] != null) ...[
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: Colors.orange.shade600,
                      ),
                      const SizedBox(width: 4),

                      Text(
                        'Deadline: ${_formatDate(latestTask['write_date'])}',
                        style: TextStyle(
                          color: Colors.orange.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToTaskDetails(latestTask),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('View Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectsSection(UserDashboardViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "My Project Tasks",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${vm.projects.length}",
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Projects List
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: vm.projects.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final project = vm.projects[index];
              final projectTasks = vm.tasks.where((task) {
                final projectId = task['project_id'];
                int? actualProjectId;
                if (projectId is List && projectId.isNotEmpty) {
                  actualProjectId = projectId[0] as int?;
                } else if (projectId is int) {
                  actualProjectId = projectId;
                }
                return actualProjectId == project['id'];
              }).toList();

              return _buildProjectSummaryCard(project, projectTasks);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAllTasksSection(UserDashboardViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "All My Tasks",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${vm.tasks.length}",
                style: TextStyle(
                  color: Colors.purple.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Tasks List
        if (vm.tasks.isNotEmpty)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: vm.sortedTasksLatest.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final task = vm.sortedTasksLatest[index];
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
                Icon(Icons.task_alt, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  "No tasks assigned",
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  "You don't have any tasks assigned yet",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    UserDashboardViewModel vm,
    Map<String, dynamic> task,
  ) {
    // Check if task is completed
    bool isCompleted = false;
    if (task['state'] == '3') {
      isCompleted = true;
    }

    final projectName = _getProjectName(vm, task);

    return GestureDetector(
      onTap: () => _navigateToTaskDetails(task),
      child: Container(
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
                Icon(
                  _getTaskIcon(task),
                  color: _getTaskStatusColor(task['state']),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task['name'] ?? 'Unnamed Task',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: isCompleted ? Colors.grey.shade600 : Colors.black,
                    ),
                  ),
                ),
                _buildStatusDropdown(vm, task),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (task['description'] != null &&
                task['description'].toString().isNotEmpty) ...[
              Text(
                _stripHtmlTags(task['description']),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  height: 1.4,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                if (projectName != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.folder,
                          size: 14,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          projectName,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Icon(
                  _getTaskPriorityIcon(task['priority']),
                  size: 16,
                  color: _getTaskPriorityColor(task['priority']),
                ),
                const SizedBox(width: 4),
                Text(
                  _getTaskPriorityText(task['priority']),
                  style: TextStyle(
                    color: _getTaskPriorityColor(task['priority']),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
                const Spacer(),
                if (task['date_start'] != null) ...[
                  Icon(
                    Icons.play_arrow,
                    size: 14,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Start: ${_formatDate(task['date_start'])}',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (task['date_start'] != null && task['date_deadline'] != null)
                  const SizedBox(width: 8),
                if (task['date_deadline'] != null) ...[
                  Icon(Icons.schedule, size: 14, color: Colors.orange.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Deadline: ${_formatDate(task['write_date'])}',
                    style: TextStyle(
                      color: Colors.orange.shade600,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(
    UserDashboardViewModel vm,
    Map<String, dynamic> task,
  ) {
    final String current = _normalizeState(task['state']);
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          items: const [
            DropdownMenuItem(value: 'open', child: Text('Not Started')),
            DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
            DropdownMenuItem(value: 'done', child: Text('Completed')),
            DropdownMenuItem(value: 'hold', child: Text("On Hold")),
          ],
          onChanged: (value) async {
            if (value == null) return;
            final taskId = task['id'] as int?;
            if (taskId == null) return;
            await vm.updateTaskStatus(taskId, value);
          },
        ),
      ),
    );
  }

  String _normalizeState(dynamic state) {
    if (state == null) return 'open';
    final s = state.toString();
    switch (s) {
      case '1':
      case 'draft':
      case 'open':
        return 'open';
      case '2':
      case 'in_progress':
        return 'in_progress';
      case '3':
      case 'done':
        return 'done';
      case '4':
      case 'hold':
        return 'done';
      default:
        return 'open';
    }
  }

  Widget _buildProjectSummaryCard(
    Map<String, dynamic> project,
    List<Map<String, dynamic>> projectTasks,
  ) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.folder, size: 36, color: Colors.blue.shade600),
          const SizedBox(height: 8),
          Text(
            project['name'] ?? 'Unnamed Project',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${projectTasks.length} tasks',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 120,
            spreadRadius: 60,
          ),
        ],
      ),
    );
  }

  // Navigation method
  void _navigateToTaskDetails(Map<String, dynamic> task) {
    Navigator.of(context).pushNamed('/task_details', arguments: task);
  }

  // Logout dialog
  void _showLogoutDialog(BuildContext context, UserDashboardViewModel vm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red.shade600),
              const SizedBox(width: 8),
              const Text('Logout'),
            ],
          ),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await vm.logout();
                if (context.mounted && success) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Helper methods
  String? _getProjectName(
    UserDashboardViewModel vm,
    Map<String, dynamic> task,
  ) {
    final projectId = task['project_id'];

    int? actualProjectId;
    if (projectId is List && projectId.isNotEmpty) {
      actualProjectId = projectId[0] as int?;
    } else if (projectId is int) {
      actualProjectId = projectId;
    } else if (projectId == false || projectId == null) {
      return null;
    }

    if (actualProjectId != null) {
      final project = vm.projects.firstWhere(
        (p) => p['id'] == actualProjectId,
        orElse: () => <String, dynamic>{},
      );
      return project['name'] as String?;
    }
    return null;
  }

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
        return 'Completed';
      case '4':
      case 'cancelled':
        return 'Cancelled';
      case 'draft':
        return 'Draft';
      default:
        return 'Unknown';
    }
  }

  IconData _getTaskPriorityIcon(String? priority) {
    switch (priority) {
      case '0':
        return Icons.keyboard_arrow_down;
      case '1':
        return Icons.keyboard_arrow_up;
      case '2':
        return Icons.remove;
      default:
        return Icons.remove;
    }
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
}
