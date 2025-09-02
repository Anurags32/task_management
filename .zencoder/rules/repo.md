# Task Management App - Repo Overview

- Tech: Flutter, Dart, Firebase (FCM + flutter_local_notifications), Odoo RPC via HTTP
- App entry: lib/main.dart
- Key features: Task/project CRUD with Odoo backend, push + local notifications for tasks

## Important Paths

- lib/main.dart: App start, Firebase init, TaskNotificationManager init, routes
- lib/services/odoo_client.dart: Odoo HTTP client, session/cookies, create/update/searchRead
- lib/services/task_service.dart: High-level API for tasks/projects (uses OdooClient); notification trigger on create/update
- lib/services/notification_service.dart: FCM + local notifications init and scheduling
- lib/services/task_notification_manager.dart: Orchestration of assignment/reminders/deadline scheduling
- lib/viewmodels/add_task_viewmodel.dart: Form state + submit for creating tasks
- lib/views/add_task_page.dart: UI for creating task, including Allocated Time

## Notifications Flow

- On task create: show immediate "New Task Assigned" local notification
- Reminders: Based on Allocated Time (e.g., 60 min → notifications at 30/45/55 minutes after start)
- Deadline: At allocation end or task deadline, a final alert is shown

## Notes

- Odoo create returns { success, id, message } (not data)
- Routes for pages registered in main.dart
- Ensure Firebase setup via firebase_options.dart and platform configs
