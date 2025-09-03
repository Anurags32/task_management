import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_dashboard_viewmodel.dart';

class TaskDetailsPage extends StatefulWidget {
  final Map<String, dynamic> task;

  const TaskDetailsPage({super.key, required this.task});

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  late Map<String, dynamic> task;

  @override
  void initState() {
    super.initState();
    task = Map<String, dynamic>.from(widget.task);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Header Card
            _buildTaskHeaderCard(),
            const SizedBox(height: 20),

            // Task Description Card
            if (task['description'] != null &&
                task['description'].toString().isNotEmpty)
              _buildDescriptionCard(),
            if (task['description'] != null &&
                task['description'].toString().isNotEmpty)
              const SizedBox(height: 20),

            // Task Details Card
            _buildDetailsCard(),
            const SizedBox(height: 20),

            // Task Actions Card
            _buildActionsCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskHeaderCard() {
    final status = _normalizedStatusForTask(task);
    final isCompleted = status == 'done';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.purple.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _getTaskIcon(task),
                  color: _getTaskStatusColor(status),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['name'] ?? 'Unnamed Task',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: isCompleted
                            ? Colors.grey.shade600
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getTaskStatusColor(status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getTaskStatusColor(status),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _getTaskStatusText(status),
                        style: TextStyle(
                          color: _getTaskStatusColor(status),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
              Icon(Icons.description, color: Colors.blue.shade600, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Description',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _stripHtmlTags(task['description']),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
              Icon(Icons.info_outline, color: Colors.green.shade600, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Task Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Priority
          _buildDetailRow(
            'Priority',
            _getTaskPriorityText(task['priority']),
            _getTaskPriorityIcon(task['priority']),
            _getTaskPriorityColor(task['priority']),
          ),

          const SizedBox(height: 16),

          // Created Date
          if (task['create_date'] != null)
            _buildDetailRow(
              'Created',
              _formatDate(task['create_date']),
              Icons.calendar_today,
              Colors.blue.shade600,
            ),

          if (task['create_date'] != null) const SizedBox(height: 16),

          // Start Date
          if (task['date_start'] != null)
            _buildDetailRow(
              'Start Date',
              _formatDate(task['date_start']),
              Icons.play_arrow,
              Colors.green.shade600,
            ),

          if (task['date_start'] != null) const SizedBox(height: 16),

          // Deadline
          if (task['date_deadline'] != null)
            _buildDetailRow(
              'Deadline',
              _formatDate(task['write_date']),
              Icons.schedule,
              Colors.orange.shade600,
            ),

          if (task['date_deadline'] != null) const SizedBox(height: 16),

          // Last Updated
          if (task['write_date'] != null)
            _buildDetailRow(
              'Last Updated',
              _formatDate(task['write_date']),
              Icons.update,
              Colors.purple.shade600,
            ),

          if (task['write_date'] != null) const SizedBox(height: 16),

          // Task ID
          _buildDetailRow(
            'Task ID',
            '#${task['id']}',
            Icons.tag,
            Colors.grey.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionsCard(BuildContext context) {
    final isCompleted = _normalizedStatusForTask(task) == 'done';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                Icons.play_circle_outline,
                color: Colors.blue.shade600,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Task Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (!isCompleted) ...[
            // Start Task Button
            if (_canStartTask(task))
              _buildActionButton(
                context,
                'Start Task',
                Icons.play_arrow,
                Colors.blue,
                () => _showStartTaskDialog(context),
              ),

            if (_canStartTask(task)) const SizedBox(height: 12),

            // Set Pending Button
            if (_canSetPending(task))
              _buildActionButton(
                context,
                'Set to Pending',
                Icons.pause,
                Colors.orange,
                () => _showPendingTaskDialog(context),
              ),

            if (_canSetPending(task)) const SizedBox(height: 12),

            // Complete Task Button
            _buildActionButton(
              context,
              'Complete Task',
              Icons.check_circle,
              Colors.green,
              () => _showCompleteTaskDialog(context),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Task Completed',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  // Helper methods
  IconData _getTaskIcon(Map<String, dynamic> task) {
    final s = _normalizedStatusForTask(task);
    switch (s) {
      case 'open':
        return Icons.radio_button_unchecked;
      case 'in_progress':
        return Icons.play_arrow;
      case 'done':
        return Icons.check_circle;
      case 'hold':
        return Icons.pause_circle_filled;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.task_alt;
    }
  }

  Color _getTaskStatusColor(String? status) {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'done':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'hold':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getTaskStatusText(String? status) {
    switch (status) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'done':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'hold':
        return 'On Hold';
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
      final hour12 = (dateTime.hour % 12 == 0) ? 12 : (dateTime.hour % 12);
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at $hour12:$minute $period';
    } catch (e) {
      return date.toString();
    }
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

  // Helpers to normalize status similar to dashboard
  String _normalizeState(dynamic state) {
    if (state == null) return 'open';
    final s = state.toString().toLowerCase();
    if (s == '1') return 'open';
    if (s == '2') return 'in_progress';
    if (s == '3') return 'done';
    if (s == '4') return 'hold';
    if (s.contains('progress')) return 'in_progress';
    if (s.contains('done') || s.contains('complete')) return 'done';
    if (s.contains('hold') || s.contains('waiting') || s.contains('blocked'))
      return 'hold';
    if (s.contains('cancel')) return 'cancelled';
    if (s.contains('open') || s.contains('draft') || s.contains('todo'))
      return 'open';
    return 'open';
  }

  String _normalizedStatusForTask(Map<String, dynamic> task) {
    try {
      final stage = task['stage_id'];
      if (stage is List && stage.length >= 2) {
        final stageName = stage[1]?.toString().toLowerCase() ?? '';
        if (stageName.contains('done') || stageName.contains('complete'))
          return 'done';
        if (stageName.contains('progress') || stageName.contains('working'))
          return 'in_progress';
        if (stageName.contains('hold') ||
            stageName.contains('waiting') ||
            stageName.contains('blocked'))
          return 'hold';
        if (stageName.contains('open') ||
            stageName.contains('todo') ||
            stageName.contains('new'))
          return 'open';
      }
    } catch (_) {}
    return _normalizeState(task['state']);
  }

  bool _canStartTask(Map<String, dynamic> task) {
    final status = _normalizedStatusForTask(task);
    return status == 'open';
  }

  bool _canSetPending(Map<String, dynamic> task) {
    final status = _normalizedStatusForTask(task);
    return status == 'open' || status == 'in_progress';
  }

  void _showStartTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.play_arrow, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              const Text('Start Task'),
            ],
          ),
          content: Text(
            'Are you sure you want to start working on "${_stripHtmlTags(task['name'])}"?',
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Start'),
              onPressed: () async {
                Navigator.of(context).pop();
                final vm = context.read<UserDashboardViewModel>();
                final success = await vm.startTask(task['id']);
                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Task started successfully!'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                    Navigator.of(context).pop(); // Go back to dashboard
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          vm.errorMessage ?? 'Failed to start task',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showPendingTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.pause, color: Colors.orange.shade600),
              const SizedBox(width: 8),
              const Text('Set Task to Pending'),
            ],
          ),
          content: Text(
            'Are you sure you want to set "${_stripHtmlTags(task['name'])}" to pending?',
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Set Pending'),
              onPressed: () async {
                Navigator.of(context).pop();
                final vm = context.read<UserDashboardViewModel>();
                final success = await vm.setTaskPending(task['id']);
                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Task set to pending!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    Navigator.of(context).pop(); // Go back to dashboard
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          vm.errorMessage ?? 'Failed to set task pending',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showCompleteTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600),
              const SizedBox(width: 8),
              const Text('Complete Task'),
            ],
          ),
          content: Text(
            'Are you sure you want to mark "${_stripHtmlTags(task['name'])}" as completed?',
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Complete'),
              onPressed: () async {
                Navigator.of(context).pop();
                final vm = context.read<UserDashboardViewModel>();
                final success = await vm.completeTask(task['id']);
                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Task marked as completed!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Navigate to user dashboard after completion
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/user_dashboard', (r) => false);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          vm.errorMessage ?? 'Failed to complete task',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}
