import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../firebase_options.dart';
import 'odoo_client.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase for background isolate
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    // Initialize local notifications in background isolate
    final plugin = FlutterLocalNotificationsPlugin();
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await plugin.initialize(initSettings);

    // Create channels (id/name/description must match foreground for grouping)
    const assignmentChannel = AndroidNotificationChannel(
      'task_assignment',
      'Task Assignment',
      description: 'Notifications for new task assignments',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    const reminderChannel = AndroidNotificationChannel(
      'task_reminder',
      'Task Reminders',
      description: 'Notifications for task time reminders',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: true,
    );
    const deadlineChannel = AndroidNotificationChannel(
      'task_deadline',
      'Task Deadlines',
      description: 'Notifications for task deadlines',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final androidImpl = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.createNotificationChannel(assignmentChannel);
    await androidImpl?.createNotificationChannel(reminderChannel);
    await androidImpl?.createNotificationChannel(deadlineChannel);

    // Determine channel and content
    final data = message.data;
    final type = (data['type'] ?? '').toString();
    String channelId;
    String channelName;
    String channelDescription;
    switch (type) {
      case 'task_assigned':
        channelId = 'task_assignment';
        channelName = 'Task Assignment';
        channelDescription = 'Notifications for new task assignments';
        break;
      case 'task_reminder':
        channelId = 'task_reminder';
        channelName = 'Task Reminders';
        channelDescription = 'Notifications for task time reminders';
        break;
      case 'task_deadline':
        channelId = 'task_deadline';
        channelName = 'Task Deadlines';
        channelDescription = 'Notifications for task deadlines';
        break;
      default:
        channelId = 'task_assignment';
        channelName = 'Task Assignment';
        channelDescription = 'Notifications for new task assignments';
    }

    final notification = message.notification;
    final title =
        notification?.title ??
        (type == 'task_assigned' ? 'New Task Assigned' : 'Task Update');
    final body =
        notification?.body ??
        (data['task_name']?.toString() ?? 'Open the app to view details');

    await plugin.show(
      // Unique id for each notification
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  } catch (e) {
    print('Background handler error: $e');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Simple event stream to notify app about push-triggered events
  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get events => _eventController.stream;
  void _emitEvent(Map<String, dynamic> event) {
    try {
      _eventController.add(event);
    } catch (_) {}
  }

  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _backgroundMessageSubscription;

  // Notification channels
  static const String _taskAssignmentChannel = 'task_assignment';
  static const String _taskReminderChannel = 'task_reminder';
  static const String _taskDeadlineChannel = 'task_deadline';

  /// Initialize Firebase and local notifications
  Future<void> initialize() async {
    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Initialize Firebase with proper options
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Request permission for notifications
      await _requestNotificationPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Set up Firebase message handlers
      await _setupFirebaseMessaging();

      // Get FCM token
      await _getFCMToken();

      // Listen for token refreshes and re-register
      _firebaseMessaging.onTokenRefresh.listen((token) async {
        await _saveFCMToken(token);
      });

      print('NotificationService initialized successfully');
    } catch (e) {
      print('Error initializing NotificationService: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestNotificationPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional notification permission');
    } else {
      print('User declined or has not accepted notification permission');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    const androidChannelSettings = AndroidNotificationChannel(
      _taskAssignmentChannel,
      'Task Assignment',
      description: 'Notifications for new task assignments',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const androidReminderChannelSettings = AndroidNotificationChannel(
      _taskReminderChannel,
      'Task Reminders',
      description: 'Notifications for task time reminders',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: true,
    );

    const androidDeadlineChannelSettings = AndroidNotificationChannel(
      _taskDeadlineChannel,
      'Task Deadlines',
      description: 'Notifications for task deadlines',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannelSettings);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidReminderChannelSettings);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidDeadlineChannelSettings);
  }

  /// Set up Firebase messaging handlers
  Future<void> _setupFirebaseMessaging() async {
    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle initial message when app is opened from terminated state
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  /// Get FCM token for the device
  Future<void> _getFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
        await _saveFCMToken(token);
      }
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  /// Public: call after successful login to ensure token is linked to user session
  Future<void> registerCurrentTokenWithBackend() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveFCMToken(token);
      }
    } catch (e) {
      print('registerCurrentTokenWithBackend error: $e');
    }
  }

  /// Save FCM token locally and send to backend (associate with current user)
  Future<void> _saveFCMToken(String token) async {
    try {
      print('FCM Token saved: $token');
      // Send token to Odoo backend to link with current user
      final res = await OdooClient.instance.registerDeviceToken(token);
      if (res['success'] != true) {
        print('Failed to register FCM token on backend: ${res['error']}');
      }
    } catch (e) {
      print('Error registering FCM token on backend: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');

    // If this is a task assignment push, schedule local workflow on user device
    final data = message.data;
    final type = data['type'];
    if (type == 'task_assigned') {
      // Optional: de-dup using SharedPreferences if server may retry
      final prefs = await SharedPreferences.getInstance();
      final id = data['task_id']?.toString() ?? message.messageId ?? '';
      final key = 'push_seen_task_$id';
      if (prefs.getBool(key) == true) {
        return;
      }
      await prefs.setBool(key, true);

      // Extract needed fields from payload
      final taskId = int.tryParse(data['task_id']?.toString() ?? '');
      final taskName = data['task_name']?.toString() ?? 'Task';
      final projectName = data['project_name']?.toString() ?? 'Project';

      // Notify app to refresh data (e.g., UserDashboardViewModel can listen)
      _emitEvent({'type': 'task_assigned', 'task_id': taskId});

      // Immediate "Task Assigned" local notification
      await showTaskAssignmentNotification(
        taskId: taskId ?? (message.hashCode),
        taskName: taskName,
        projectName: projectName,
      );

      // Schedule reminders from payload
      // Option A: allocated window
      final allocated = int.tryParse(
        data['allocated_minutes']?.toString() ?? '',
      );
      // Option B: absolute deadline ISO8601
      final deadlineStr = data['deadline']?.toString();
      DateTime? deadline;
      if (deadlineStr != null && deadlineStr.isNotEmpty) {
        try {
          deadline = DateTime.parse(deadlineStr);
        } catch (_) {}
      }

      if (allocated != null && allocated > 0) {
        final endTime = DateTime.now().add(Duration(minutes: allocated));
        for (final m in [30, 45, 55]) {
          if (m < allocated) {
            final minutesBeforeEnd = allocated - m;
            await scheduleTaskReminder(
              taskId: taskId ?? message.hashCode,
              taskName: taskName,
              deadline: endTime,
              reminderMinutes: minutesBeforeEnd,
            );
          }
        }
        await scheduleTaskDeadline(
          taskId: taskId ?? message.hashCode,
          taskName: taskName,
          deadline: endTime,
        );
      } else if (deadline != null) {
        for (final m in [30, 45, 55]) {
          await scheduleTaskReminder(
            taskId: taskId ?? message.hashCode,
            taskName: taskName,
            deadline: deadline,
            reminderMinutes: m,
          );
        }
        await scheduleTaskDeadline(
          taskId: taskId ?? message.hashCode,
          taskName: taskName,
          deadline: deadline,
        );
      }

      return; // we've handled locally
    } else if (type == 'task_status') {
      // Status update for admins (or watchers)
      final taskId = int.tryParse(data['task_id']?.toString() ?? '');
      final taskName = data['task_name']?.toString() ?? 'Task';
      final status = (data['status']?.toString() ?? 'updated').toLowerCase();

      String title = 'Task Status Updated';
      String body = '"$taskName" is $status';
      if (status == 'completed') {
        title = 'Task Completed';
        body = '"$taskName" has been completed';
      } else if (status == 'hold') {
        title = 'Task On Hold';
        body = '"$taskName" is put on hold';
      } else if (status == 'in_progress') {
        title = 'Task In Progress';
        body = '"$taskName" is now in progress';
      }

      // Emit event so dashboards can refresh
      _emitEvent({'type': 'task_status', 'task_id': taskId, 'status': status});

      _localNotifications.show(
        (taskId ?? message.hashCode) + 50000,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _taskAssignmentChannel,
            'Task Assignment',
            channelDescription: 'Notifications for new task assignments',
            icon: '@mipmap/ic_launcher',
            color: Colors.blue,
            priority: Priority.high,
            importance: Importance.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: json.encode({
          'type': 'task_status',
          'task_id': (taskId ?? message.hashCode).toString(),
          'task_name': taskName,
          'status': status,
        }),
      );
      return;
    }

    // Default: show the notification
    _showLocalNotification(message);
  }

  /// Show local notification for foreground messages
  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _getChannelId(message.data),
            _getChannelName(message.data),
            channelDescription: _getChannelDescription(message.data),
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            color: _getNotificationColor(message.data),
            priority: Priority.high,
            importance: Importance.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: json.encode(message.data),
      );
    }
  }

  /// Show background notification
  static Future<void> _showBackgroundNotification(RemoteMessage message) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      await flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _getChannelId(message.data),
            _getChannelName(message.data),
            channelDescription: _getChannelDescription(message.data),
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            color: _getNotificationColor(message.data),
            priority: Priority.high,
            importance: Importance.high,
          ),
        ),
        payload: json.encode(message.data),
      );
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final data = json.decode(response.payload!);
      _handleNotificationTap(data);
    }
  }

  /// Handle message opened from app
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('App opened from notification: ${message.messageId}');
    // Emit event so viewmodels can refresh data immediately
    final type = message.data['type'];
    if (type == 'task_assigned') {
      _emitEvent({'type': 'task_assigned'});
    }
    _handleNotificationTap(message.data);
  }

  /// Handle notification tap based on type
  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'];
    final taskId = data['task_id'];

    switch (type) {
      case 'task_assigned':
        // Navigate to task details
        _navigateToTask(taskId);
        break;
      case 'task_reminder':
        // Navigate to task details
        _navigateToTask(taskId);
        break;
      case 'task_deadline':
        // Navigate to task details
        _navigateToTask(taskId);
        break;
      default:
        print('Unknown notification type: $type');
    }
  }

  /// Navigate to task details
  void _navigateToTask(String? taskId) {
    // TODO: Implement navigation to task details
    print('Navigate to task: $taskId');
  }

  /// Get channel ID based on notification type
  static String _getChannelId(Map<String, dynamic> data) {
    final type = data['type'];
    switch (type) {
      case 'task_assigned':
        return _taskAssignmentChannel;
      case 'task_reminder':
        return _taskReminderChannel;
      case 'task_deadline':
        return _taskDeadlineChannel;
      default:
        return _taskAssignmentChannel;
    }
  }

  /// Get channel name based on notification type
  static String _getChannelName(Map<String, dynamic> data) {
    final type = data['type'];
    switch (type) {
      case 'task_assigned':
        return 'Task Assignment';
      case 'task_reminder':
        return 'Task Reminders';
      case 'task_deadline':
        return 'Task Deadlines';
      default:
        return 'Task Assignment';
    }
  }

  /// Get channel description based on notification type
  static String _getChannelDescription(Map<String, dynamic> data) {
    final type = data['type'];
    switch (type) {
      case 'task_assigned':
        return 'Notifications for new task assignments';
      case 'task_reminder':
        return 'Notifications for task time reminders';
      case 'task_deadline':
        return 'Notifications for task deadlines';
      default:
        return 'Notifications for new task assignments';
    }
  }

  /// Get notification color based on type
  static Color _getNotificationColor(Map<String, dynamic> data) {
    final type = data['type'];
    switch (type) {
      case 'task_assigned':
        return Colors.blue;
      case 'task_reminder':
        return Colors.orange;
      case 'task_deadline':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  /// Schedule local notification for task reminder
  Future<void> scheduleTaskReminder({
    required int taskId,
    required String taskName,
    required DateTime deadline,
    required int reminderMinutes,
  }) async {
    final scheduledTime = tz.TZDateTime.from(
      deadline.subtract(Duration(minutes: reminderMinutes)),
      tz.local,
    );

    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
      print('Reminder time has already passed for task $taskId');
      return;
    }

    final notifId = taskId * 100 + reminderMinutes; // Unique ID

    await _localNotifications.zonedSchedule(
      notifId,
      'Task Reminder',
      'Task "$taskName" is due in ${reminderMinutes} minutes',
      scheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _taskReminderChannel,
          'Task Reminders',
          channelDescription: 'Notifications for task time reminders',
          icon: '@mipmap/ic_launcher',
          color: Colors.orange,
          priority: Priority.defaultPriority,
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: json.encode({
        'type': 'task_reminder',
        'task_id': taskId.toString(),
        'task_name': taskName,
        'reminder_minutes': reminderMinutes,
      }),
    );

    // Track this scheduled notification ID so we can cancel later
    await _trackNotificationId(taskId, notifId);

    print('Scheduled reminder for task $taskId in ${reminderMinutes} minutes');
  }

  /// Schedule local notification for task deadline
  Future<void> scheduleTaskDeadline({
    required int taskId,
    required String taskName,
    required DateTime deadline,
  }) async {
    final scheduledTime = tz.TZDateTime.from(deadline, tz.local);

    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
      print('Deadline has already passed for task $taskId');
      return;
    }

    final notifId = taskId * 1000; // Unique ID for deadline notification

    await _localNotifications.zonedSchedule(
      notifId,
      'Task Deadline',
      'Task "$taskName" deadline has passed. Your access has been cancelled.',
      scheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _taskDeadlineChannel,
          'Task Deadlines',
          channelDescription: 'Notifications for task deadlines',
          icon: '@mipmap/ic_launcher',
          color: Colors.red,
          priority: Priority.high,
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: json.encode({
        'type': 'task_deadline',
        'task_id': taskId.toString(),
        'task_name': taskName,
      }),
    );

    await _trackNotificationId(taskId, notifId);

    print('Scheduled deadline notification for task $taskId');
  }

  /// Cancel all notifications for a specific task
  Future<void> cancelTaskNotifications(int taskId) async {
    // Cancel all IDs tracked for this task (reminders + deadline)
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'notif_ids_task_${taskId.toString()}';
      final ids = prefs.getStringList(key) ?? <String>[];
      for (final idStr in ids) {
        final id = int.tryParse(idStr);
        if (id != null) {
          await _localNotifications.cancel(id);
        }
      }
      await prefs.remove(key);
      print('Cancelled all notifications for task $taskId');
    } catch (e) {
      print('Error cancelling notifications for task $taskId: $e');
    }
  }

  Future<void> _trackNotificationId(int taskId, int notifId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'notif_ids_task_${taskId.toString()}';
    final list = prefs.getStringList(key) ?? <String>[];
    if (!list.contains(notifId.toString())) {
      list.add(notifId.toString());
      await prefs.setStringList(key, list);
    }
  }

  /// Show immediate notification for task assignment
  Future<void> showTaskAssignmentNotification({
    required int taskId,
    required String taskName,
    required String projectName,
  }) async {
    await _localNotifications.show(
      taskId,
      'New Task Assigned',
      'Task "$taskName" has been assigned to you in project "$projectName"',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _taskAssignmentChannel,
          'Task Assignment',
          channelDescription: 'Notifications for new task assignments',
          icon: '@mipmap/ic_launcher',
          color: Colors.blue,
          priority: Priority.high,
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: json.encode({
        'type': 'task_assigned',
        'task_id': taskId.toString(),
        'task_name': taskName,
        'project_name': projectName,
      }),
    );

    print('Showed task assignment notification for task $taskId');
  }

  /// Dispose resources
  void dispose() {
    _messageSubscription?.cancel();
    _backgroundMessageSubscription?.cancel();
  }
}
