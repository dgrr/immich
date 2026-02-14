# Push Notifications Setup

Immich supports weekly push notifications for memories (photos from this week in previous years).

## Server Setup

1. Create a Firebase project at https://console.firebase.google.com
2. Go to Project Settings > Service Accounts
3. Click "Generate new private key" to download the credentials JSON
4. Set the environment variable on your Immich server:
   ```
   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
   ```
5. Restart the Immich server

## Mobile App Setup (for self-builds)

### Android

1. In Firebase Console, add an Android app with package name `app.alextran.immich`
2. Download `google-services.json`
3. Place it in `mobile/android/app/google-services.json`

### iOS

1. In Firebase Console, add an iOS app with bundle ID `app.alextran.immich`
2. Download `GoogleService-Info.plist`
3. Place it in `mobile/ios/Runner/GoogleService-Info.plist`
4. Enable Push Notifications capability in Xcode

## User Settings

Users can enable/disable push notifications in the mobile app:
Settings > Notifications > Push Notifications

Options:
- Enable push notifications (master toggle)
- Memories notifications (weekly reminder about photos from this week in previous years)

## How It Works

1. When a user logs in, the mobile app registers its FCM token with the server
2. Every Sunday at 10:00 AM, the server checks which users have memories available
3. For users with memories and push notifications enabled, a notification is sent
4. Tapping the notification opens the Immich app
