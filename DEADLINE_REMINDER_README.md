# Deadline Reminder System

## Overview

This system automatically shows reminder notifications 5 minutes before task deadlines. When a task is created or updated with a deadline, the system schedules a local notification that will appear 5 minutes before the deadline. **NEW**: The system now also automatically refreshes the user dashboard when deadline reminders are triggered.

## How It Works

### 1. Task Creation

When a task is created with a deadline:

- The system automatically schedules a deadline reminder notification
- The notification is set to appear exactly 5 minutes before the deadline
- Uses the device's local notification system for reliable delivery

### 2. Task Updates

When a task deadline is updated:

- Old deadline reminders are automatically cancelled
- New deadline reminders are scheduled for the new deadline
- Ensures no duplicate or outdated notifications

### 3. App Startup

When the app starts:

- The system checks all existing tasks with deadlines
- Schedules reminders for tasks with future deadlines
- Shows immediate reminders for tasks due within 5 minutes

### 4. **NEW: Auto-Refresh Dashboard**

When a deadline reminder is triggered (5 minutes before deadline):

- **Automatic Dashboard Refresh**: The user dashboard automatically refreshes to show the latest task information
- **Visual Indicator**: A notification banner appears showing that the dashboard was auto-refreshed
- **Real-time Updates**: Users see the most current task status and deadline information
- **Seamless Experience**: No manual refresh required - everything happens automatically

## Features

### Automatic Scheduling

- ✅ Reminders are scheduled automatically when tasks are created
- ✅ Reminders are updated when deadlines change
- ✅ Reminders are cancelled when tasks are completed or cancelled
- ✅ Works for both user-created and admin-created tasks

### Notification Details

- 🕐 Shows exactly 5 minutes before deadline
- 📱 Uses high-priority notifications with sound and vibration
- 🎯 Includes task name and deadline information
- 🔄 Automatically handles timezone differences

### **NEW: Dashboard Auto-Refresh**

- 🔄 **Automatic Refresh**: Dashboard refreshes automatically when deadline reminders fire
- 📱 **Visual Feedback**: Clear indication when auto-refresh occurs
- ⚡ **Real-time Updates**: Always shows the latest task information
- 🎯 **Smart Timing**: Refreshes exactly when needed (5 minutes before deadline)

## Technical Implementation

### Key Components

1. **NotificationService**: Handles local notification scheduling and event emission
2. **TaskNotificationManager**: Manages task-specific notification logic
3. **TaskService**: Integrates with task creation/update operations
4. **ViewModels**: Automatically schedule reminders when tasks are created
5. **UserDashboardViewModel**: Listens for deadline reminder events and auto-refreshes

### Event Flow

```
Task Created/Updated → Schedule Deadline Reminder →
5 min before deadline → Notification fires →
Emit 'deadline_reminder' event →
UserDashboardViewModel receives event →
Auto-refresh dashboard → Show visual indicator
```

### Debug Tools

Navigate to `/debug_notifications` to access:

- Test deadline reminders
- Check scheduled notifications
- Refresh all task reminders
- **NEW**: Test deadline reminder with dashboard refresh
- View debug logs

## Usage

### For Users

1. Create a task with a deadline
2. The system automatically schedules a reminder
3. **NEW**: 5 minutes before deadline, dashboard automatically refreshes
4. Receive notification about the deadline
5. See visual indicator that dashboard was refreshed
6. No additional setup required

### For Developers

1. The system works automatically
2. Use debug tools to test functionality
3. Check logs for troubleshooting
4. Monitor scheduled notifications
5. **NEW**: Test auto-refresh functionality with debug tools

## Testing the Auto-Refresh System

### Quick Test

1. Navigate to `/debug_notifications`
2. Click "🧪 Test Deadline Reminder with Dashboard Refresh (2 min)"
3. Wait 2 minutes
4. Dashboard will automatically refresh
5. Visual indicator will show the auto-refresh reason

### What Happens During Test

1. **Scheduling**: Deadline reminder scheduled for 2 minutes from now
2. **Waiting**: System waits for the scheduled time
3. **Trigger**: Reminder fires automatically
4. **Event**: 'deadline_reminder' event is emitted
5. **Refresh**: Dashboard automatically refreshes
6. **Visual**: Orange banner shows "Dashboard auto-refreshed: Deadline reminder for: [Task Name]"

## Benefits

### For Users

- **Always Current**: Dashboard always shows the latest information
- **No Manual Work**: No need to manually refresh before important deadlines
- **Clear Feedback**: Visual indication when auto-refresh occurs
- **Better Planning**: Real-time task status for better time management

### For System

- **Consistent Data**: Dashboard data is always synchronized with backend
- **Efficient**: Only refreshes when necessary (deadline reminders)
- **Reliable**: Uses local notification system for guaranteed delivery
- **Scalable**: Works for any number of tasks and users

## Troubleshooting

### Common Issues

1. **Dashboard not auto-refreshing**: Check if deadline reminders are scheduled
2. **No visual indicator**: Verify notification permissions are granted
3. **Reminders not firing**: Check device notification settings

### Debug Steps

1. Use debug notification tools to test functionality
2. Check logs for event emission and reception
3. Verify notification permissions
4. Test with different deadline times

## Future Enhancements

- [ ] Customizable auto-refresh intervals
- [ ] Multiple reminder notifications with different refresh times
- [ ] Email/SMS reminders with dashboard refresh
- [ ] Calendar integration with auto-refresh
- [ ] Team-wide deadline notifications with dashboard updates
