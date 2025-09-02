import '../services/notification_service.dart';
import '../services/task_service.dart';

class TaskNotificationManager {
  static final TaskNotificationManager _instance =
      TaskNotificationManager._internal();
  factory TaskNotificationManager() => _instance;
  TaskNotificationManager._internal();

  final NotificationService _notificationService = NotificationService();
  final TaskService _taskService = TaskService();

  /// Handle new task assignment
  Future<void> handleTaskAssignment({
    required int taskId,
    required String taskName,
    required String projectName,
    required List<int> userIds,
    int? allocatedMinutes, // NEW
    DateTime? startAt, // NEW
  }) async {
    try {
      // Show immediate notification for task assignment
      await _notificationService.showTaskAssignmentNotification(
        taskId: taskId,
        taskName: taskName,
        projectName: projectName,
      );

      // Schedule reminders and deadline notifications for each assigned user
      for (final userId in userIds) {
        await _scheduleTaskNotifications(
          taskId,
          taskName,
          userId,
          allocatedMinutes: allocatedMinutes,
          startAt: startAt,
        );
      }

      print('Task assignment notifications handled for task $taskId');
    } catch (e) {
      print('Error handling task assignment notifications: $e');
    }
  }

  /// Schedule all notifications for a task
  Future<void> _scheduleTaskNotifications(
    int taskId,
    String taskName,
    int userId, {
    int? allocatedMinutes, // NEW
    DateTime? startAt, // NEW
  }) async {
    try {
      // If allocated time is provided, schedule based on it
      if (allocatedMinutes != null && allocatedMinutes > 0) {
        final base = startAt ?? DateTime.now();
        final endTime = base.add(Duration(minutes: allocatedMinutes));

        // 30, 45, 55-minute reminders within the allocation window
        final reminderPoints = <int>[
          30,
          45,
          55,
        ].where((m) => m < allocatedMinutes).toList();

        for (final m in reminderPoints) {
          // schedule X minutes before end
          final minutesBeforeEnd = allocatedMinutes - m;
          await _notificationService.scheduleTaskReminder(
            taskId: taskId,
            taskName: taskName,
            deadline: endTime,
            reminderMinutes: minutesBeforeEnd,
          );
        }

        // Final notification at allocated end time
        await _notificationService.scheduleTaskDeadline(
          taskId: taskId,
          taskName: taskName,
          deadline: endTime,
        );

        print('Scheduled allocated-time notifications for task $taskId');
        return;
      }

      // Fallback: schedule using task deadline from server
      final taskResult = await _taskService.getAllTasks();

      if (taskResult['success'] == true) {
        final tasks = taskResult['data'] as List<dynamic>?;
        final taskDetails = tasks?.firstWhere(
          (task) => task['id'] == taskId,
          orElse: () => null,
        );

        if (taskDetails != null && taskDetails['date_deadline'] != null) {
          final deadline = DateTime.parse(taskDetails['date_deadline']);

          // Schedule reminders at 30, 45, and 55 minutes before deadline
          await _notificationService.scheduleTaskReminder(
            taskId: taskId,
            taskName: taskName,
            deadline: deadline,
            reminderMinutes: 30,
          );

          await _notificationService.scheduleTaskReminder(
            taskId: taskId,
            taskName: taskName,
            deadline: deadline,
            reminderMinutes: 45,
          );

          await _notificationService.scheduleTaskReminder(
            taskId: taskId,
            taskName: taskName,
            deadline: deadline,
            reminderMinutes: 55,
          );

          // Schedule deadline notification
          await _notificationService.scheduleTaskDeadline(
            taskId: taskId,
            taskName: taskName,
            deadline: deadline,
          );

          print('Scheduled all notifications for task $taskId');
        } else {
          print(
            'No deadline found for task $taskId, skipping reminder notifications',
          );
        }
      }
    } catch (e) {
      print('Error scheduling task notifications: $e');
    }
  }

  /// Handle task completion - cancel all scheduled notifications
  Future<void> handleTaskCompletion(int taskId) async {
    try {
      await _notificationService.cancelTaskNotifications(taskId);
      print('Cancelled all notifications for completed task $taskId');
    } catch (e) {
      print('Error cancelling task notifications: $e');
    }
  }

  /// Handle task cancellation - cancel all scheduled notifications
  Future<void> handleTaskCancellation(int taskId) async {
    try {
      await _notificationService.cancelTaskNotifications(taskId);
      print('Cancelled all notifications for cancelled task $taskId');
    } catch (e) {
      print('Error cancelling task notifications: $e');
    }
  }

  /// Handle task deadline passed - show deadline notification
  Future<void> handleTaskDeadlinePassed({
    required int taskId,
    required String taskName,
  }) async {
    try {
      await _notificationService.showTaskAssignmentNotification(
        taskId: taskId,
        taskName: taskName,
        projectName: 'System',
      );
      print('Showed deadline notification for task $taskId');
    } catch (e) {
      print('Error showing deadline notification: $e');
    }
  }

  /// Initialize notification manager
  Future<void> initialize() async {
    try {
      await _notificationService.initialize();
      print('TaskNotificationManager initialized successfully');
    } catch (e) {
      print('Error initializing TaskNotificationManager: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _notificationService.dispose();
  }
}
