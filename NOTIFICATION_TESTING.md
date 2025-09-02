# Testing Firebase Notifications

## Quick Test Guide

### 1. Test Task Assignment Notification

1. Run the app: `flutter run`
2. Login to the app
3. Create a new task with:
   - Task name: "Test Notification Task"
   - Description: "This is a test task for notifications"
   - Assign to current user
   - Set deadline to 1 hour from now
4. You should immediately see a notification: "New Task Assigned"

### 2. Test Reminder Notifications

1. Create a task with deadline set to 1 hour from now
2. Wait for the reminder notifications:
   - 30 minutes before deadline
   - 45 minutes before deadline
   - 55 minutes before deadline
3. Each notification should say: "Task 'Task Name' is due in X minutes"

### 3. Test Deadline Notification

1. Create a task with deadline set to 5 minutes from now
2. Wait for the deadline notification
3. Notification should say: "Task 'Task Name' deadline has passed. Your access has been cancelled."

### 4. Test Task Completion

1. Complete a task by changing its status to "Completed"
2. All scheduled notifications for that task should be cancelled
3. Check logs for: "Cancelled all notifications for completed task X"

## Debug Information

Check the console output for:

- FCM Token: `FCM Token: [token]`
- Notification scheduling: `Scheduled reminder for task X in Y minutes`
- Notification cancellation: `Cancelled all notifications for task X`

## Manual Testing with Firebase Console

1. Get FCM token from app logs
2. Go to Firebase Console > Cloud Messaging
3. Send test message with:
   ```json
   {
     "notification": {
       "title": "Test Notification",
       "body": "This is a test notification"
     },
     "data": {
       "type": "task_assigned",
       "task_id": "123",
       "task_name": "Test Task"
     }
   }
   ```

## Troubleshooting

### Notifications not showing:

1. Check notification permissions in app settings
2. Verify notification channels are created
3. Check if Do Not Disturb mode is enabled

### FCM token not generated:

1. Verify Firebase configuration
2. Check internet connection
3. Ensure Firebase project is properly set up

### Local notifications not working:

1. Check notification channels in Android settings
2. Verify timezone is properly initialized
3. Check if app has notification permissions
