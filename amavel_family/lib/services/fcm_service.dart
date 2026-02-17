import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> initialize() async {
    // Request permissions for iOS
    if (Platform.isIOS) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carryForward: true,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );
    } else {
      await _firebaseMessaging.requestPermission();
    }

    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleMessage(message);
    });

    // Handle messages when app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message);
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Get and update FCM token
    await _updateFCMToken();

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      await _saveFCMToken(newToken);
    });
  }

  static Future<void> _updateFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveFCMToken(token);
      }
    } catch (e) {
      print('Erro ao obter FCM token: $e');
    }
  }

  static Future<void> _saveFCMToken(String token) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'updatedAt': DateTime.now(),
        });
      }
    } catch (e) {
      print('Erro ao salvar FCM token: $e');
    }
  }

  static void _handleMessage(RemoteMessage message) {
    print('Mensagem FCM recebida: ${message.notification?.title}');

    if (message.notification != null) {
      print('Título: ${message.notification!.title}');
      print('Corpo: ${message.notification!.body}');
    }

    if (message.data.isNotEmpty) {
      print('Dados da mensagem: ${message.data}');
    }
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    print('Mensagem FCM em background: ${message.notification?.title}');
  }

  static Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
    } catch (e) {
      print('Erro ao desinscrever do tópico: $e');
    }
  }

  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
    } catch (e) {
      print('Erro ao inscrever no tópico: $e');
    }
  }
}
