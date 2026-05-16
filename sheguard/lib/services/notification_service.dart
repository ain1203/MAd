import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, // default icon
      [
        NotificationChannel(
          channelKey: 'emergency_alerts',
          channelName: 'Emergency Alerts',
          channelDescription: 'Notifications for SOS alerts from your circle',
          defaultColor: const Color(0xFF9D50BB),
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          channelShowBadge: true,
          locked: true,
          defaultRingtoneType: DefaultRingtoneType.Alarm,
        ),
        NotificationChannel(
          channelKey: 'chat_messages',
          channelName: 'Chat Messages',
          channelDescription: 'Notifications for new chat messages',
          defaultColor: const Color(0xFF6A1B9A),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
        ),
      ],
    );

    // Request permissions
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  /// Start listening for new alerts and messages
  static void startListening(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return;

    _listenForAlerts(user.uid);
    _listenForMessages(user.uid);
  }

  static void _listenForAlerts(String currentUid) {
    // 1. Get circle members first
    _db.collection('circles').doc(currentUid).collection('contacts').snapshots().listen((contactSnapshot) {
      final List<String> contactUids = contactSnapshot.docs
          .map((doc) => doc.data()['uid'] as String)
          .toList();

      if (contactUids.isEmpty) return;

      // 2. Listen for alerts from these UIDs
      // Note: We use a timestamp check to only notify for NEW alerts after the app started
      final startTime = Timestamp.now();

      _db.collection('alerts')
          .where('userId', whereIn: contactUids.take(10).toList()) // Firestore limit 10
          .where('timestamp', isGreaterThan: startTime)
          .snapshots()
          .listen((alertSnapshot) {
        for (var change in alertSnapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data() as Map<String, dynamic>;
            _showEmergencyNotification(
              title: "🚨 SOS ALERT: ${data['userName']}",
              body: "Emergency detected! Tap to view location.",
              payload: {"type": "alert", "lat": "${data['lat']}", "lng": "${data['lng']}"},
            );
          }
        }
      });
    });
  }

  static void _listenForMessages(String currentUid) {
    final startTime = Timestamp.now();

    _db.collection('messages')
        .where('receiverId', isEqualTo: currentUid)
        .where('timestamp', isGreaterThan: startTime)
        .snapshots()
        .listen((msgSnapshot) {
      for (var change in msgSnapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          _showChatNotification(
            title: "New Message",
            body: data['text'] ?? "Sent a message",
            payload: {"type": "chat", "senderId": "${data['senderId']}"},
          );
        }
      }
    });
  }

  static void _showEmergencyNotification({
    required String title,
    required String body,
    Map<String, String>? payload,
  }) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'emergency_alerts',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        payload: payload,
        category: NotificationCategory.Alarm,
        criticalAlert: true,
      ),
    );
  }

  static void _showChatNotification({
    required String title,
    required String body,
    Map<String, String>? payload,
  }) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'chat_messages',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        payload: payload,
        category: NotificationCategory.Message,
      ),
    );
  }
}
