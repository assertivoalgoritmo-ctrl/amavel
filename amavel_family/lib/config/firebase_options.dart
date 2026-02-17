import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'dart:io' show Platform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (Platform.isAndroid) {
      return android;
    }
    if (Platform.isIOS) {
      return ios;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: '1:YOUR_PROJECT_NUMBER:android:YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_PROJECT_NUMBER',
    projectId: 'amavel-senior',
    storageBucket: 'amavel-senior.appspot.com',
    databaseURL: 'https://amavel-senior-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: '1:YOUR_PROJECT_NUMBER:ios:YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_PROJECT_NUMBER',
    projectId: 'amavel-senior',
    storageBucket: 'amavel-senior.appspot.com',
    databaseURL: 'https://amavel-senior-default-rtdb.firebaseio.com',
    iosBundleId: 'com.example.amavelFamily',
  );
}
