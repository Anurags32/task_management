import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_management/theme.dart' show AppTheme;
import 'package:task_management/viewmodels/user_dashboard_viewmodel.dart';

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  @override
  void initState() {
    super.initState();
    // Trigger initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserDashboardViewModel>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserDashboardViewModel>();

    return Scaffold(
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: 80,
            left: -60,
            child: _buildBlob(AppTheme.blobGreen, 200),
          ),
          Positioned(
            top: 40,
            right: -80,
            child: _buildBlob(AppTheme.blobYellow, 220),
          ),
          Positioned(
            bottom: 300,
            left: -70,
            child: _buildBlob(AppTheme.blobBlue, 240),
          ),
          Positioned(
            bottom: 150,
            right: -60,
            child: _buildBlob(AppTheme.blobPurple, 200),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Profile Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ProfileHeader(vm: vm),
                      _NotificationIcon(vm: vm),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Error Message
                  if (vm.errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              vm.errorMessage!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.red.shade700),
                            onPressed: vm.clearError,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Projects Section
                  Row(
                    children: [
                      const Text(
                        'My Projects',
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
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${vm.projects.length}',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (vm.isRefreshing)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: vm.refresh,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Projects List
                  if (vm.projects.isNotEmpty)
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: vm.projects.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final project = vm.projects[index];
                          return _buildProjectCard(context, vm, project);
                        },
                      ),
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
                            Icons.folder_open,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No projects assigned",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Tasks Section
                  Row(
                    children: [
                      const Text(
                        'My Tasks',
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
                          '${vm.tasks.length}',
                          style: const TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Task List
                  Expanded(
                    child: vm.isRefreshing
                        ? const Center(child: CircularProgressIndicator())
                        : vm.tasks.isNotEmpty
                        ? ListView.separated(
                            itemCount: vm.tasks.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final task = vm.tasks[index];
                              return _buildTaskCard(context, vm, task);
                            },
                          )
                        : Container(
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
                                  "No tasks assigned",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(
    BuildContext context,
    UserDashboardViewModel vm,
    Map<String, dynamic> project,
  ) {
    final projectId = project['id'] as int?;
    final projectTasks = projectId != null
        ? vm.getTasksForProject(projectId)
        : [];

    return Container(
      width: 200,
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
                radius: 20,
                backgroundColor: Colors.blue.shade100,
                child: Icon(
                  Icons.folder,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  project['name'] ?? 'Unnamed Project',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            project['description'] ?? 'No description',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.task_alt, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                "${projectTasks.length} tasks",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getProjectStatusColor(
                    project['state'],
                  ).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getProjectStatusText(project['state']),
                  style: TextStyle(
                    color: _getProjectStatusColor(project['state']),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    UserDashboardViewModel vm,
    Map<String, dynamic> task,
  ) {
    final projectId = task['project_id']?[0];
    final project = projectId != null ? vm.getProjectById(projectId) : null;
    final stageName = task['stage_id']?[1] ?? 'Unknown Stage';

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
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _getTaskPriorityColor(
              task['priority'],
            ).withOpacity(0.2),
            child: Icon(
              Icons.task_alt,
              color: _getTaskPriorityColor(task['priority']),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['name'] ?? 'Unnamed Task',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (project != null)
                  Text(
                    "Project: ${project['name']}",
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                const SizedBox(height: 4),
                Text(
                  "Stage: $stageName",
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
                if (task['date_deadline'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    "Deadline: ${_formatDate(task['date_deadline'])}",
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Status',
                style: TextStyle(fontSize: 12, color: Colors.black54),
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
                    fontWeight: FontWeight.bold,
                    color: _getTaskStatusColor(task['state']),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getProjectStatusColor(String? state) {
    switch (state) {
      case 'open':
        return Colors.green;
      case 'close':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getProjectStatusText(String? state) {
    switch (state) {
      case 'open':
        return 'Active';
      case 'close':
        return 'Closed';
      default:
        return 'Unknown';
    }
  }

  Color _getTaskPriorityColor(String? priority) {
    switch (priority) {
      case '0': // Low
        return Colors.green;
      case '1': // High
        return Colors.red;
      case '2': // Medium
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  Color _getTaskStatusColor(String? state) {
    switch (state) {
      case '1': // Open
        return Colors.blue;
      case '2': // In Progress
        return Colors.orange;
      case '3': // Done
        return Colors.green;
      case '4': // Cancelled
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

  String _formatDate(dynamic date) {
    if (date is String) {
      try {
        final dateTime = DateTime.parse(date);
        return "${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}";
      } catch (e) {
        return date;
      }
    }
    return date.toString();
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
}

class _ProfileHeader extends StatelessWidget {
  final UserDashboardViewModel vm;

  const _ProfileHeader({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.purple.shade100,
          child: Icon(Icons.person, color: Colors.purple.shade700, size: 28),
        ),
        const SizedBox(width: 12),
        _HelloName(vm: vm),
      ],
    );
  }
}

class _HelloName extends StatelessWidget {
  final UserDashboardViewModel vm;

  const _HelloName({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hello!',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        Text(
          vm.currentUser?['name'] ?? 'User',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  final UserDashboardViewModel vm;

  const _NotificationIcon({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Icon(Icons.notifications, size: 28),
        if (vm.errorMessage != null)
          Positioned(
            right: 0,
            top: 2,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
