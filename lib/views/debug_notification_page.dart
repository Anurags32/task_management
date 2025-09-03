import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/task_notification_manager.dart';

class DebugNotificationPage extends StatefulWidget {
  const DebugNotificationPage({super.key});

  @override
  State<DebugNotificationPage> createState() => _DebugNotificationPageState();
}

class _DebugNotificationPageState extends State<DebugNotificationPage> {
  final NotificationService _notificationService = NotificationService();
  final TaskNotificationManager _taskNotificationManager =
      TaskNotificationManager();
  String _logMessage = '';

  void _addLog(String message) {
    setState(() {
      _logMessage +=
          '${DateTime.now().toString().substring(11, 19)}: $message\n';
    });
    print(message);
  }

  Future<void> _runDebugTests() async {
    _addLog('🔍 Starting debug tests...');
    try {
      await _notificationService.runDebugTests();
      _addLog('✅ Debug tests completed successfully');
    } catch (e) {
      _addLog('❌ Error running debug tests: $e');
    }
  }

  Future<void> _testDeadlineReminder() async {
    _addLog('🧪 Testing deadline reminder...');
    try {
      await _notificationService.testDeadlineReminder();
      _addLog('✅ Test deadline reminder scheduled');
    } catch (e) {
      _addLog('❌ Error testing deadline reminder: $e');
    }
  }

  Future<void> _checkScheduledNotifications() async {
    _addLog('📋 Checking scheduled notifications...');
    try {
      await _notificationService.checkScheduledNotifications();
      _addLog('✅ Check completed');
    } catch (e) {
      _addLog('❌ Error checking notifications: $e');
    }
  }

  Future<void> _testSpecificTaskDeadline() async {
    _addLog('🧪 Testing specific task deadline reminder...');
    try {
      // Test with a sample task that has a deadline 10 minutes from now
      final testTaskId = 999999;
      final testTaskName = 'Test Task for Deadline Reminder';
      final testDeadline = DateTime.now().add(const Duration(minutes: 10));

      await _notificationService.scheduleDeadlineReminder(
        taskId: testTaskId,
        taskName: testTaskName,
        deadline: testDeadline,
      );
      _addLog(
        '✅ Specific task deadline reminder scheduled for 10 minutes from now',
      );
      _addLog('Task ID: $testTaskId, Name: $testTaskName');
      _addLog('Deadline: ${testDeadline.toString()}');
    } catch (e) {
      _addLog('❌ Error testing specific task deadline reminder: $e');
    }
  }

  Future<void> _refreshAllTaskReminders() async {
    _addLog('🔄 Refreshing all task reminders...');
    try {
      await _taskNotificationManager.refreshAllTaskReminders();
      _addLog('✅ All task reminders refreshed successfully');
    } catch (e) {
      _addLog('❌ Error refreshing task reminders: $e');
    }
  }

  Future<void> _testDeadlineReminderWithRefresh() async {
    _addLog('🧪 Testing deadline reminder with dashboard refresh...');
    try {
      // Test with a sample task that has a deadline 2 minutes from now
      final testTaskId = 999997;
      final testTaskName = 'Test Task for Dashboard Refresh';
      final testDeadline = DateTime.now().add(const Duration(minutes: 2));

      await _notificationService.scheduleDeadlineReminder(
        taskId: testTaskId,
        taskName: testTaskName,
        deadline: testDeadline,
      );
      _addLog('✅ Deadline reminder scheduled for 2 minutes from now');
      _addLog('Task ID: $testTaskId, Name: $testTaskName');
      _addLog('Deadline: ${testDeadline.toString()}');
      _addLog('Dashboard will auto-refresh in 2 minutes when reminder fires');
    } catch (e) {
      _addLog('❌ Error testing deadline reminder with refresh: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Debug'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Debug Notification Functions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _runDebugTests,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('🔍 Run All Debug Tests'),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _testDeadlineReminder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('🧪 Test Deadline Reminder'),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _testSpecificTaskDeadline,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('🧪 Test Specific Task Deadline (10 min)'),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _checkScheduledNotifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('📋 Check Scheduled Notifications'),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _refreshAllTaskReminders,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('🔄 Refresh All Task Reminders'),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _testDeadlineReminderWithRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                '🧪 Test Deadline Reminder with Dashboard Refresh (2 min)',
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Debug Log:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _logMessage.isEmpty
                        ? 'No logs yet. Run tests to see results.'
                        : _logMessage,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _logMessage = '';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear Logs'),
            ),
          ],
        ),
      ),
    );
  }
}
