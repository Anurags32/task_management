# Firebase Notification Setup for Task Management App

This document explains how to set up Firebase Cloud Messaging (FCM) for the task management app to enable push notifications.

## Prerequisites

1. A Firebase project
2. Android app configured in Firebase
3. Firebase configuration files

## Setup Steps

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select an existing one
3. Enable Cloud Messaging in the project settings

### 2. Add Android App to Firebase

1. In Firebase Console, click "Add app" and select Android
2. Enter your package name: `com.example.task_management`
3. Download the `google-services.json` file
4. Place it in `android/app/google-services.json`

### 3. Configure Android Build Files

Add the following to `android/build.gradle.kts`:

```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

Add the following to `android/app/build.gradle.kts`:

```kotlin
plugins {
    id("com.google.gms.google-services")
}

dependencies {
    implementation("com.google.firebase:firebase-messaging:23.4.0")
}
```

### 4. Configure iOS (if needed)

1. Add iOS app to Firebase project
2. Download `GoogleService-Info.plist`
3. Add it to your iOS project
4. Configure iOS capabilities for push notifications

## Notification Flow

The app implements the following notification flow:

### 1. Task Assignment Notification

- **When**: A new task is assigned to a user
- **Notification**: Immediate notification showing task name and project
- **Action**: Tap to view task details

### 2. Task Reminder Notifications

- **When**: 30, 45, and 55 minutes before task deadline
- **Notification**: Reminder that task is due soon
- **Action**: Tap to view task details

### 3. Task Deadline Notification

- **When**: When task deadline has passed
- **Notification**: Deadline passed, access cancelled
- **Action**: Tap to view task details

## Testing Notifications

### Local Testing

1. Run the app
2. Create a task with a deadline
3. Wait for reminder notifications (or adjust system time)
4. Check notification channels in Android settings

### Firebase Testing

1. Use Firebase Console to send test messages
2. Use FCM token from app logs
3. Test different notification types

## Troubleshooting

### Common Issues

1. **Notifications not showing**: Check notification permissions
2. **FCM token not generated**: Verify Firebase configuration
3. **Local notifications not working**: Check notification channels
4. **Background notifications**: Ensure service is properly configured

### Debug Information

The app logs FCM tokens and notification events. Check console output for:

- FCM token generation
- Notification scheduling
- Notification delivery

## Security Considerations

1. Store FCM tokens securely
2. Validate notification payloads
3. Implement proper authentication
4. Use Firebase App Check for additional security

## Additional Features

The notification system supports:

- Custom notification sounds
- Different notification channels
- Rich notifications with images
- Deep linking to specific tasks
- Notification history

For more information, refer to the Firebase documentation and Flutter Firebase plugins.
