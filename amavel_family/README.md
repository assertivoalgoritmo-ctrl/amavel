# AMAVEL Family Companion App

A Flutter-based mobile application for family members to monitor and communicate with their senior loved ones. Built for both Android and iOS platforms.

## Features

- **Wellness Dashboard**: View real-time status of your senior loved one including last active time, online status, and wellness indicators
- **Voice & Text Messaging**: Exchange voice messages and text messages with your senior
- **Alert Management**: Receive and manage alerts with severity levels, acknowledge alerts, and track resolutions
- **Notification Preferences**: Customize notification settings by severity level
- **Account Management**: Secure authentication and account settings

## Prerequisites

- Flutter 3.10.0 or higher
- Dart 3.0.0 or higher
- Android SDK (for Android development)
- Xcode (for iOS development)
- Firebase project configured

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/amavel_family.git
cd amavel_family
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Update `lib/config/firebase_options.dart` with your Firebase credentials
3. Download `google-services.json` (for Android) and place it in `android/app/`
4. Download `GoogleService-Info.plist` (for iOS) and add it to the Xcode project

### 4. Enable Firebase Services

In the Firebase Console, enable:
- Authentication (Email/Password)
- Cloud Firestore
- Cloud Storage
- Cloud Messaging (FCM)

### 5. Run the app

```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # App configuration and routes
├── config/
│   └── firebase_options.dart # Firebase configuration
├── models/
│   ├── senior_profile.dart   # Senior user model
│   ├── message.dart          # Message model
│   └── alert.dart            # Alert model
├── services/
│   ├── auth_service.dart     # Authentication service
│   ├── messaging_service.dart # Messaging service
│   ├── alert_service.dart    # Alert service
│   └── fcm_service.dart      # Firebase Cloud Messaging service
├── providers/
│   └── family_providers.dart # Riverpod state management
└── pages/
    ├── login_page.dart       # Login/Registration page
    ├── dashboard_page.dart   # Main dashboard
    ├── messages_page.dart    # Messages page
    ├── alerts_page.dart      # Alerts management
    └── settings_page.dart    # Settings page
```

## Dependencies

### Core
- **firebase_core**: Firebase initialization
- **firebase_auth**: Authentication
- **cloud_firestore**: Database
- **firebase_messaging**: Push notifications
- **firebase_storage**: File storage

### State Management
- **flutter_riverpod**: State management

### Audio
- **just_audio**: Audio playback
- **record**: Audio recording
- **permission_handler**: Permission handling

### Utilities
- **intl**: Internationalization
- **uuid**: UUID generation
- **path_provider**: File system paths
- **shared_preferences**: Local storage
- **http**: HTTP requests

## Building

### Android APK

```bash
flutter build apk --release
```

### iOS App

```bash
flutter build ios --release
```

### Android App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

## Firebase Firestore Schema

### Users Collection
```
users/{userId}
  ├── uid: string
  ├── email: string
  ├── name: string
  ├── userType: "family" | "senior"
  ├── linkedSeniorId: string
  ├── fcmToken: string
  └── createdAt: timestamp
```

### Conversations Collection
```
conversations/{conversationId}/messages/{messageId}
  ├── senderId: string
  ├── senderName: string
  ├── recipientId: string
  ├── content: string
  ├── type: "text" | "voice"
  ├── audioUrl: string
  ├── transcript: string
  ├── timestamp: timestamp
  └── isRead: boolean
```

### Alerts Collection
```
users/{userId}/alerts/{alertId}
  ├── seniorId: string
  ├── title: string
  ├── description: string
  ├── severity: "low" | "medium" | "high" | "critical"
  ├── timestamp: timestamp
  ├── acknowledged: boolean
  ├── resolved: boolean
  ├── resolvedNotes: string
  └── notifiedFamilyMembers: array
```

## Troubleshooting

### Build Issues

1. **Flutter SDK not found**: Ensure Flutter is installed and added to PATH
2. **Gradle errors**: Run `flutter clean` and try again
3. **Pod issues (iOS)**: Run `cd ios && pod update && cd ..`

### Firebase Issues

1. **Firebase initialization error**: Check `firebase_options.dart` configuration
2. **Authentication errors**: Verify Firebase Authentication is enabled
3. **Firestore errors**: Check Firestore rules and security settings

### Audio Issues

1. **Recording permission denied**: Check app permissions in device settings
2. **Microphone not working**: Test microphone with native app first

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, email support@amavelapp.com or open an issue on GitHub.

## Roadmap

- [ ] Video calling integration
- [ ] Advanced health metrics dashboard
- [ ] Medication reminders
- [ ] Emergency SOS button
- [ ] Integration with wearable devices
- [ ] AI-powered health insights
- [ ] Multi-language support
