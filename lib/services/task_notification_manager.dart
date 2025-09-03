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

        print(
          '🔄 TaskNotificationManager: Scheduling 5-minute deadline reminder...',
        );
        // Schedule 5-minute deadline reminder
        await _notificationService.scheduleDeadlineReminder(
          taskId: taskId,
          taskName: taskName,
          deadline: endTime,
        );
        print(
          '✅ TaskNotificationManager: 5-minute deadline reminder scheduled',
        );

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
          final raw = taskDetails['date_deadline'].toString();
          DateTime deadline = DateTime.parse(raw);
          // If only a date is provided (no time), use end-of-day local so reminders are in future
          final isDateOnly = !raw.contains('T') && !raw.contains(' ');
          if (isDateOnly) {
            deadline = DateTime(
              deadline.year,
              deadline.month,
              deadline.day,
              23,
              59,
            );
          }

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

          print(
            '🔄 TaskNotificationManager: Scheduling 5-minute deadline reminder for server task...',
          );
          // Schedule 5-minute deadline reminder
          await _notificationService.scheduleDeadlineReminder(
            taskId: taskId,
            taskName: taskName,
            deadline: deadline,
          );
          print(
            '✅ TaskNotificationManager: 5-minute deadline reminder scheduled for server task',
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
      
      // Check for existing tasks with deadlines and schedule reminders
      await _scheduleRemindersForExistingTasks();
      
    } catch (e) {
      print('Error initializing TaskNotificationManager: $e');
    }
  }

  /// Schedule reminders for existing tasks that have deadlines
  Future<void> _scheduleRemindersForExistingTasks() async {
    try {
      print('🔄 TaskNotificationManager: Checking for existing tasks with deadlines...');
      
      final tasksResult = await _taskService.getAllTasks();
      if (tasksResult['success'] == true) {
        final tasks = tasksResult['data'] as List<dynamic>?;
        if (tasks != null) {
          int scheduledCount = 0;
          for (final task in tasks) {
            final taskData = Map<String, dynamic>.from(task);
            final taskId = taskData['id'] as int?;
            final taskName = taskData['name']?.toString() ?? 'Task';
            final deadlineStr = taskData['date_deadline']?.toString();
            
            if (taskId != null && deadlineStr != null && deadlineStr.isNotEmpty) {
              try {
                final deadline = DateTime.parse(deadlineStr);
                final now = DateTime.now();
                
                // Only schedule if deadline is in the future
                if (deadline.isAfter(now)) {
                  // Check if we're within 5 minutes of deadline
                  final timeUntilDeadline = deadline.difference(now);
                  if (timeUntilDeadline.inMinutes > 5) {
                    // Schedule 5-minute reminder
                    await _notificationService.scheduleDeadlineReminder(
                      taskId: taskId,
                      taskName: taskName,
                      deadline: deadline,
                    );
                    scheduledCount++;
                    print('✅ TaskNotificationManager: Scheduled reminder for existing task $taskId (${taskName})');
                  } else if (timeUntilDeadline.inMinutes > 0) {
                    // If within 5 minutes but not passed, show immediate reminder
                    await _notificationService.showTaskAssignmentNotification(
                      taskId: taskId,
                      taskName: taskName,
                      projectName: 'System',
                    );
                    print('⚠️ TaskNotificationManager: Showed immediate reminder for task $taskId (${taskName}) - due soon!');
                  }
                }
              } catch (e) {
                print('⚠️ TaskNotificationManager: Failed to parse deadline for task $taskId: $e');
              }
            }
          }
          print('✅ TaskNotificationManager: Scheduled reminders for $scheduledCount existing tasks');
        }
      }
    } catch (e) {
      print('⚠️ TaskNotificationManager: Error scheduling reminders for existing tasks: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _notificationService.dispose();
  }

  /// Public method to manually refresh reminders for all tasks
  Future<void> refreshAllTaskReminders() async {
    try {
      print('🔄 TaskNotificationManager: Manually refreshing all task reminders...');
      await _scheduleRemindersForExistingTasks();
      print('✅ TaskNotificationManager: All task reminders refreshed successfully');
    } catch (e) {
      print('❌ TaskNotificationManager: Error refreshing task reminders: $e');
    }
  }
}
