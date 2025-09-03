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
  static const String _deadlineReminderChannel = 'deadline_reminder';

  /// Initialize Firebase and local notifications
  Future<void> initialize() async {
    try {
      // Initialize timezone
      tz.initializeTimeZones();
      // Force app to use India Standard Time (Asia/Kolkata)
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } catch (_) {
        // Fallback silently if location not found
      }
      print('✅ Timezone initialized');
      print('Current timezone: ${tz.local.name}');
      print('Current TZ time: ${tz.TZDateTime.now(tz.local)}');
      print('Current local time: ${DateTime.now()}');

      // Initialize Firebase with proper options
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Request permission for notifications
      await _requestNotificationPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Ensure Android-specific permissions (POST_NOTIFICATIONS, EXACT_ALARMS)
      await _ensureAndroidPermissions();

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

    print('Notification permission status: ${settings.authorizationStatus}');
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted notification permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('⚠️ User granted provisional notification permission');
    } else {
      print('❌ User declined or has not accepted notification permission');
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
    print('✅ Local notifications initialized successfully');

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  /// Android permissions that impact scheduled notifications
  Future<void> _ensureAndroidPermissions() async {
    try {
      // flutter_local_notifications v19.4.1 does not expose
      // requestPermission/areExactAlarmsPermitted on Android.
      // We rely on manifest (SCHEDULE_EXACT_ALARM) + user settings.
      debugPrint(
        'Android exact alarms: relying on manifest + user settings (no runtime API in this version)',
      );
    } catch (e) {
      print('Error ensuring Android permissions: $e');
    }
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

    const androidDeadlineReminderChannelSettings = AndroidNotificationChannel(
      _deadlineReminderChannel,
      'Deadline Reminders',
      description: 'Notifications for deadline reminders',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final androidImpl = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(androidChannelSettings);
      print('✅ Task assignment channel created');

      await androidImpl.createNotificationChannel(
        androidReminderChannelSettings,
      );
      print('✅ Task reminder channel created');

      await androidImpl.createNotificationChannel(
        androidDeadlineChannelSettings,
      );
      print('✅ Task deadline channel created');

      await androidImpl.createNotificationChannel(
        androidDeadlineReminderChannelSettings,
      );
      print('✅ Deadline reminder notification channel created successfully');
    } else {
      print(
        '❌ Could not create notification channels - Android implementation not available',
      );
    }
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
          // If payload provided only a date (no time), schedule at end-of-day local
          final isDateOnly =
              !deadlineStr.contains('T') && !deadlineStr.contains(' ');
          if (isDateOnly && deadline != null) {
            deadline = DateTime(
              deadline.year,
              deadline.month,
              deadline.day,
              23,
              59,
            );
          }
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
        // Schedule 10-minute reminder before deadline
        await scheduleDeadlineReminder(
          taskId: taskId ?? message.hashCode,
          taskName: taskName,
          deadline: endTime,
        );
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
        // Schedule 10-minute reminder before deadline
        await scheduleDeadlineReminder(
          taskId: taskId ?? message.hashCode,
          taskName: taskName,
          deadline: deadline,
        );
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

  /// Handle notification tap and scheduled notification events
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        final type = data['type'];

        if (type == 'deadline_reminder') {
          // This is a scheduled deadline reminder notification
          final taskId = int.tryParse(data['task_id']?.toString() ?? '');
          final taskName = data['task_name']?.toString() ?? 'Task';
          final deadlineStr = data['deadline']?.toString();

          if (taskId != null && deadlineStr != null) {
            try {
              final deadline = DateTime.parse(deadlineStr);
              handleScheduledDeadlineReminder(
                taskId: taskId,
                taskName: taskName,
                deadline: deadline,
              );
            } catch (e) {
              print('❌ Error parsing deadline from notification: $e');
            }
          }
        } else {
          // Handle other notification types normally
          _handleNotificationTap(data);
        }
      } catch (e) {
        print('❌ Error handling notification response: $e');
        // Fallback to normal handling
        if (response.payload != null) {
          final data = json.decode(response.payload!);
          _handleNotificationTap(data);
        }
      }
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
      case 'deadline_reminder':
        // Navigate to task details
        _navigateToTask(taskId);
        break;
      default:
        print('Unknown notification type: $type');
    }
  }

  /// Handle scheduled deadline reminder notification
  Future<void> handleScheduledDeadlineReminder({
    required int taskId,
    required String taskName,
    required DateTime deadline,
  }) async {
    try {
      final deadlineLocal = tz.TZDateTime.from(deadline, tz.local);
      final deadlineStr =
          '${deadlineLocal.year}-${deadlineLocal.month.toString().padLeft(2, '0')}-${deadlineLocal.day.toString().padLeft(2, '0')} ${deadlineLocal.hour.toString().padLeft(2, '0')}:${deadlineLocal.minute.toString().padLeft(2, '0')}';

      // Emit event to refresh dashboard
      _emitEvent({
        'type': 'deadline_reminder',
        'task_id': taskId,
        'task_name': taskName,
        'deadline': deadlineStr,
      });

      // Show the deadline reminder notification
      await _localNotifications.show(
        taskId * 1000 + 1,
        '⚠️ Deadline Reminder',
        'Task "$taskName" is due in 5 minutes (Deadline: $deadlineStr)',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _deadlineReminderChannel,
            'Deadline Reminders',
            channelDescription: 'Notifications for deadline reminders',
            icon: '@mipmap/ic_launcher',
            color: Colors.orange,
            priority: Priority.high,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: json.encode({
          'type': 'deadline_reminder',
          'task_id': taskId.toString(),
          'task_name': taskName,
        }),
      );

      print('✅ Deadline reminder notification sent for task $taskId');
    } catch (e) {
      print('❌ Error handling scheduled deadline reminder: $e');
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

    try {
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
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('exact_alarms_not_permitted')) {
        // Fallback to inexact scheduling so user still gets reminder
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
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: json.encode({
            'type': 'task_reminder',
            'task_id': taskId.toString(),
            'task_name': taskName,
            'reminder_minutes': reminderMinutes,
          }),
        );
        print(
          '⚠️ Exact alarms not permitted. Scheduled inexact reminder for task $taskId.',
        );
      } else {
        rethrow;
      }
    }

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

  /// Schedule notification 5 minutes before deadline with custom sound
  Future<void> scheduleDeadlineReminder({
    required int taskId,
    required String taskName,
    required DateTime deadline,
  }) async {
    print('=== DEBUG: scheduleDeadlineReminder called ===');
    print('Task ID: $taskId, Task Name: $taskName');
    print('Deadline: ${deadline.toString()}');
    print('Current time: ${DateTime.now().toString()}');

    // Schedule notification 5 minutes before deadline
    final reminderTime = deadline.subtract(const Duration(minutes: 5));
    final scheduledTime = tz.TZDateTime.from(reminderTime, tz.local);

    final notifId = taskId * 1000 + 1; // Unique ID for deadline reminder
    final deadlineLocal = tz.TZDateTime.from(deadline, tz.local);
    final deadlineStr =
        '${deadlineLocal.year}-${deadlineLocal.month.toString().padLeft(2, '0')}-${deadlineLocal.day.toString().padLeft(2, '0')} ${deadlineLocal.hour.toString().padLeft(2, '0')}:${deadlineLocal.minute.toString().padLeft(2, '0')}';

    print('Reminder time (5 min before): ${reminderTime.toString()}');
    print('Scheduled time (TZ): ${scheduledTime.toString()}');
    print('Current TZ time: ${tz.TZDateTime.now(tz.local).toString()}');

    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
      print('Deadline reminder time has already passed for task $taskId');
      print('Scheduled time: $scheduledTime');
      print('Current TZ time: ${tz.TZDateTime.now(tz.local)}');
      // If we are within the final 5-minute window, show immediately; otherwise skip to prevent early fire
      final nowTz = tz.TZDateTime.now(tz.local);
      final windowStart = tz.TZDateTime.from(
        deadline,
        tz.local,
      ).subtract(const Duration(minutes: 5));
      if (nowTz.isAfter(windowStart)) {
        // Emit event to refresh dashboard
        _emitEvent({
          'type': 'deadline_reminder',
          'task_id': taskId,
          'task_name': taskName,
          'deadline': deadlineStr,
        });

        await _localNotifications.show(
          notifId,
          '⚠️ Deadline Reminder',
          'Task "$taskName" is due soon (Deadline: $deadlineStr)',
          NotificationDetails(
            android: AndroidNotificationDetails(
              _deadlineReminderChannel,
              'Deadline Reminders',
              channelDescription: 'Notifications for deadline reminders',
              icon: '@mipmap/ic_launcher',
              color: Colors.orange,
              priority: Priority.high,
              importance: Importance.high,
              playSound: true,
              enableVibration: true,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: json.encode({
            'type': 'deadline_reminder',
            'task_id': taskId.toString(),
            'task_name': taskName,
          }),
        );
        await _trackNotificationId(taskId, notifId);
        print('✅ Shown immediate deadline reminder (inside 5-min window)');
      } else {
        print('⏭️ Outside 5-min window; not showing immediate reminder');
      }
      return;
    }

    print('Attempting to schedule notification with ID: $notifId');
    print('Notification channel: $_deadlineReminderChannel');

    try {
      await _localNotifications.zonedSchedule(
        notifId,
        '⚠️ Deadline Reminder',
        'Task "$taskName" is due in 5 minutes (Deadline: $deadlineStr)',
        scheduledTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _deadlineReminderChannel,
            'Deadline Reminders',
            channelDescription: 'Notifications for deadline reminders',
            icon: '@mipmap/ic_launcher',
            color: Colors.orange,
            priority: Priority.high,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: json.encode({
          'type': 'deadline_reminder',
          'task_id': taskId.toString(),
          'task_name': taskName,
          'deadline': deadline.toIso8601String(),
        }),
      );
      print('✅ Notification scheduled successfully!');
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('exact_alarms_not_permitted')) {
        await _localNotifications.zonedSchedule(
          notifId,
          '⚠️ Deadline Reminder',
          'Task "$taskName" is due in 5 minutes (Deadline: $deadlineStr)',
          scheduledTime,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _deadlineReminderChannel,
              'Deadline Reminders',
              channelDescription: 'Notifications for deadline reminders',
              icon: '@mipmap/ic_launcher',
              color: Colors.orange,
              priority: Priority.high,
              importance: Importance.high,
              playSound: true,
              enableVibration: true,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: json.encode({
            'type': 'deadline_reminder',
            'task_id': taskId.toString(),
            'task_name': taskName,
            'deadline': deadline.toIso8601String(),
          }),
        );
        print(
          '⚠️ Exact alarms not permitted. Scheduled inexact 5-min deadline reminder for task $taskId.',
        );
      } else {
        print('❌ Error scheduling notification: $e');
        rethrow;
      }
    }

    await _trackNotificationId(taskId, notifId);

    print(
      'Scheduled deadline reminder notification for task $taskId at ${scheduledTime.toString()}',
    );
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

  /// Check currently scheduled notifications
  Future<void> checkScheduledNotifications() async {
    try {
      final pendingNotifications = await _localNotifications
          .pendingNotificationRequests();
      print(
        '📋 Currently scheduled notifications: ${pendingNotifications.length}',
      );

      for (final notification in pendingNotifications) {
        print('  - ID: ${notification.id}, Title: ${notification.title}');
      }
    } catch (e) {
      print('❌ Error checking scheduled notifications: $e');
    }
  }

  /// Test function to manually test deadline reminder notification
  Future<void> testDeadlineReminder() async {
    print('🧪 Testing deadline reminder notification...');

    // Schedule a test notification for 1 minute from now
    final testTime = DateTime.now().add(const Duration(minutes: 1));
    final scheduledTime = tz.TZDateTime.from(testTime, tz.local);

    print('Test notification scheduled for: ${scheduledTime.toString()}');

    try {
      await _localNotifications.zonedSchedule(
        999999, // Unique test ID
        '🧪 Test Deadline Reminder',
        'This is a test notification for deadline reminder!',
        scheduledTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _deadlineReminderChannel,
            'Deadline Reminders',
            channelDescription: 'Notifications for deadline reminders',
            icon: '@mipmap/ic_launcher',
            color: Colors.orange,
            priority: Priority.high,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: json.encode({
          'type': 'test_deadline_reminder',
          'task_id': '999999',
          'task_name': 'Test Task',
        }),
      );
      print('✅ Test notification scheduled successfully!');
      print('Check your device in 1 minute for the test notification.');
    } catch (e) {
      // If exact alarms are not permitted, guide the user
      final msg = e.toString();
      if (msg.contains('exact_alarms_not_permitted')) {
        print(
          '❌ Exact alarms not permitted. Please enable "Allow exact alarms" in App settings.',
        );
      }
      print('❌ Error scheduling test notification: $e');
    }
  }

  /// Test function to manually test deadline reminder notification with custom time
  Future<void> testDeadlineReminderWithTime(int minutesFromNow) async {
    print(
      '🧪 Testing deadline reminder notification for $minutesFromNow minutes from now...',
    );

    // Schedule a test notification for specified minutes from now
    final testTime = DateTime.now().add(Duration(minutes: minutesFromNow));
    final scheduledTime = tz.TZDateTime.from(testTime, tz.local);

    print('Test notification scheduled for: ${scheduledTime.toString()}');

    try {
      await _localNotifications.zonedSchedule(
        999998, // Unique test ID
        '🧪 Test Deadline Reminder',
        'This is a test notification for deadline reminder in $minutesFromNow minutes!',
        scheduledTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _deadlineReminderChannel,
            'Deadline Reminders',
            channelDescription: 'Notifications for deadline reminders',
            icon: '@mipmap/ic_launcher',
            color: Colors.orange,
            priority: Priority.high,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: json.encode({
          'type': 'test_deadline_reminder',
          'task_id': '999998',
          'task_name': 'Test Task',
        }),
      );
      print(
        '✅ Test notification scheduled successfully for $minutesFromNow minutes from now!',
      );
      print(
        'Check your device in $minutesFromNow minutes for the test notification.',
      );
    } catch (e) {
      // If exact alarms are not permitted, guide the user
      final msg = e.toString();
      if (msg.contains('exact_alarms_not_permitted')) {
        print(
          '❌ Exact alarms not permitted. Please enable "Allow exact alarms" in App settings.',
        );
      }
      print('❌ Error scheduling test notification: $e');
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

  /// Public method to run debug tests
  Future<void> runDebugTests() async {
    print('🔍 Running notification service debug tests...');

    // Check scheduled notifications
    await checkScheduledNotifications();

    // Test deadline reminder
    await testDeadlineReminder();

    print('🔍 Debug tests completed. Check logs above for results.');
  }

  /// Check if a specific task has deadline reminders scheduled
  Future<bool> hasDeadlineReminderScheduled(int taskId) async {
    try {
      final pendingNotifications = await _localNotifications
          .pendingNotificationRequests();

      // Check if any notification with payload contains this task ID
      for (final notification in pendingNotifications) {
        if (notification.payload != null) {
          try {
            final payload = json.decode(notification.payload!);
            if (payload['task_id'] == taskId.toString() &&
                payload['type'] == 'deadline_reminder') {
              return true;
            }
          } catch (e) {
            // Skip invalid payloads
            continue;
          }
        }
      }
      return false;
    } catch (e) {
      print('Error checking if deadline reminder is scheduled: $e');
      return false;
    }
  }

  /// Get all scheduled deadline reminders for a specific task
  Future<List<Map<String, dynamic>>> getTaskDeadlineReminders(
    int taskId,
  ) async {
    try {
      final pendingNotifications = await _localNotifications
          .pendingNotificationRequests();
      final reminders = <Map<String, dynamic>>[];

      for (final notification in pendingNotifications) {
        if (notification.payload != null) {
          try {
            final payload = json.decode(notification.payload!);
            if (payload['task_id'] == taskId.toString() &&
                payload['type'] == 'deadline_reminder') {
              reminders.add({
                'id': notification.id,
                'title': notification.title,
                'body': notification.body,
                'payload': payload,
              });
            }
          } catch (e) {
            // Skip invalid payloads
            continue;
          }
        }
      }
      return reminders;
    } catch (e) {
      print('Error getting task deadline reminders: $e');
      return [];
    }
  }
}
