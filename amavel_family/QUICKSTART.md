# AMAVEL Family App - Quick Start Guide

## 5-Minute Setup

### 1. Prerequisites Check
```bash
# Verify Flutter installation
flutter --version
# Should output: Flutter 3.10.0 or higher

# Verify Dart
dart --version
# Should output: Dart 3.0.0 or higher
```

### 2. Clone & Setup
```bash
cd amavel_family
flutter pub get
```

### 3. Firebase Configuration

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project named "amavel-senior"
3. Enable these services:
   - Authentication (Email/Password)
   - Cloud Firestore
   - Cloud Storage
   - Cloud Messaging

4. Update `lib/config/firebase_options.dart`:
```dart
// Replace with your Firebase credentials
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  appId: '1:YOUR_PROJECT_NUMBER:android:YOUR_APP_ID',
  messagingSenderId: 'YOUR_PROJECT_NUMBER',
  projectId: 'amavel-senior',
  storageBucket: 'amavel-senior.appspot.com',
  databaseURL: 'https://amavel-senior-default-rtdb.firebaseio.com',
);
```

### 4. Run the App
```bash
flutter run
```

## First Time Login

1. **Register**: Click "Não tem conta? Cadastre-se"
2. **Enter Details**:
   - Email: your-email@example.com
   - Name: Your Name
   - Password: (8+ characters)
   - Invitation Code: (get from senior's app)
3. **Login**: You're in!

## Testing Without Invitation Code

For testing purposes, you can modify `lib/pages/login_page.dart` to allow registration without a valid invitation code:

```dart
// In _handleRegister(), comment out this check:
// if (linkedSeniorId == null) {
//   setState(() => _error = 'Código de convite inválido');
//   return;
// }

// And hardcode a test senior ID:
final linkedSeniorId = 'test-senior-id-12345';
```

## Project Structure Navigation

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry point |
| `lib/app.dart` | App configuration & routing |
| `lib/pages/login_page.dart` | Login/Register screen |
| `lib/pages/dashboard_page.dart` | Main dashboard |
| `lib/pages/messages_page.dart` | Voice/text messaging |
| `lib/pages/alerts_page.dart` | Alert management |
| `lib/pages/settings_page.dart` | Settings & preferences |
| `lib/services/` | Core business logic |
| `lib/providers/` | State management |
| `lib/models/` | Data models |

## Common Tasks

### Add a New Page

1. Create `lib/pages/new_page.dart`:
```dart
import 'package:flutter/material.dart';

class NewPage extends StatelessWidget {
  const NewPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Page')),
      body: const Center(child: Text('Hello')),
    );
  }
}
```

2. Add route in `lib/app.dart`:
```dart
routes: {
  '/new-page': (context) => const NewPage(),
}
```

3. Navigate from another page:
```dart
Navigator.pushNamed(context, '/new-page');
```

### Add a New Service

1. Create `lib/services/new_service.dart`
2. Add provider in `lib/providers/family_providers.dart`:
```dart
final newServiceProvider = Provider((ref) => NewService());
```

3. Use in a page:
```dart
final newService = ref.watch(newServiceProvider);
```

### Add Firestore Collection

1. Create collection in Firebase Console
2. Update models as needed
3. Add queries in service files
4. Add providers in `family_providers.dart`

## Code Formatting

```bash
# Format all Dart files
dart format lib/

# Analyze code quality
flutter analyze

# Fix analysis issues
dart fix --apply
```

## Build & Deploy

### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (Play Store)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS (requires macOS)
```bash
flutter build ios --release
```

## Environment Variables

Create `.env` file (copy from `.env.example`):
```
FIREBASE_PROJECT_ID=amavel-senior
FIREBASE_API_KEY=your-key-here
API_BASE_URL=https://api.amavelapp.com
LOG_LEVEL=debug
```

## Troubleshooting

### "flutter not found"
```bash
# Add Flutter to PATH
export PATH="$PATH:/path/to/flutter/bin"
```

### Gradle errors
```bash
flutter clean
flutter pub get
cd android && ./gradlew clean && cd ..
```

### Pod errors (iOS)
```bash
cd ios
pod repo update
pod install
cd ..
```

### Firebase credentials error
1. Double-check `firebase_options.dart`
2. Verify project ID matches Firebase Console
3. Ensure Firebase services are enabled

### Microphone permission denied
- Android: Grant in device Settings > Apps > AMAVEL Family > Permissions
- iOS: Check Info.plist NSMicrophoneUsageDescription

## Performance Tips

1. **Use const constructors**: `const Widget()`
2. **Rebuild only what's needed**: Use Riverpod wisely
3. **Stream instead of FutureProviders**: For real-time data
4. **Image optimization**: Compress before uploading
5. **Lazy loading**: Load data as user scrolls

## Security Best Practices

1. Never commit Firebase credentials
2. Use environment variables for sensitive data
3. Validate all user input
4. Enable Firestore security rules
5. Use Firebase Authentication
6. Implement rate limiting
7. Never store passwords locally
8. Use HTTPS for API calls

## Useful Commands

```bash
# Check Flutter info
flutter doctor -v

# Update dependencies
flutter pub upgrade

# Run tests
flutter test

# Generate coverage
flutter test --coverage

# Clean build
flutter clean

# Get dependencies
flutter pub get

# Analyze code
flutter analyze

# Format code
dart format lib/
```

## Resources

- **Flutter Docs**: https://flutter.dev/docs
- **Firebase Docs**: https://firebase.google.com/docs
- **Riverpod Guide**: https://riverpod.dev
- **Dart Conventions**: https://dart.dev/guides/language/effective-dart

## Getting Help

1. Check Flutter documentation
2. Search existing issues on GitHub
3. Ask in Flutter community
4. Check Firebase documentation
5. Review Riverpod examples

## Next Steps

1. Configure Firebase with real credentials
2. Add app icons and splash screen
3. Implement custom themes
4. Add unit tests
5. Set up CI/CD with GitHub Actions
6. Configure App Store/Play Store
7. Add analytics
8. Implement error tracking

## Performance Checklist

- [ ] Images are optimized
- [ ] Unnecessary rebuilds minimized
- [ ] Large lists use lazy loading
- [ ] Async operations properly handled
- [ ] No memory leaks in streams
- [ ] API calls are cached
- [ ] Database indexes are set up
- [ ] Security rules are configured

Good luck! 🚀
