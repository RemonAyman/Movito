import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:typed_data';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // 1. Request Permission
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // 2. Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification click logic here if needed
      },
    );

    // 3. Listen for Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(
        message.notification?.title ?? "New Message",
        message.notification?.body ?? "",
        message.data['chatId'] ?? "",
      );
    });

    // 4. Update Token
    _updateFCMToken();

    _initialized = true;
  }

  Future<void> _updateFCMToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _db.collection('users').doc(user.uid).update({'fcmToken': token});
      }
    }
  }

  Future<void> startFirestoreListener() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _db
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data()!;
              _showLocalNotification(
                data['title'] ?? 'New Message',
                data['body'] ?? '',
                data['chatId'] ?? '',
                senderAvatar: data['senderAvatar'] ?? '',
              );
              change.doc.reference.update({'read': true});
            }
          }
        });
  }

  Future<void> _showLocalNotification(
    String title,
    String body,
    String chatId, {
    String senderAvatar = "",
  }) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'chat_notifications',
          'Chat Messages',
          channelDescription: 'Notifications for chat messages',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          color: const Color(0xFF9B5DE5),
        );

    if (senderAvatar.isNotEmpty) {
      try {
        // In a real app, you'd decode Base64 to a bitmap for the large icon
        // For simplicity here, we keep it basic
      } catch (e) {
        print("Error decoding avatar for notification: $e");
      }
    }

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      chatId.hashCode,
      title,
      body,
      platformChannelSpecifics,
      payload: chatId,
    );
  }

  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required String chatId,
    bool isGroup = false,
    String senderAvatar = "",
  }) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'chatId': chatId,
      'isGroup': isGroup,
      'senderAvatar': senderAvatar,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }
}
