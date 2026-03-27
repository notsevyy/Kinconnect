import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _messaging = FirebaseMessaging.instance;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> initialize() async {
    // Request permissions
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }
    } catch (_) {
      return;
    }

    // Get FCM token
    try {
      await _messaging.getToken();
    } catch (_) {}

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background tap (app was in background, user tapped notification)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a terminated state via notification
    try {
      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        _handleNotificationTap(initial);
      }
    } catch (_) {}
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final title = message.notification?.title ?? _titleFromType(message.data);
    final body = message.notification?.body ?? '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (body.isNotEmpty)
              Text(body, style: const TextStyle(fontSize: 13)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        backgroundColor: _colorFromType(message.data),
      ),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type'] as String?;
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    int tabIndex;
    switch (type) {
      case 'emergency_alert':
        tabIndex = 2; // Safety tab
        break;
      case 'medication_reminder':
        tabIndex = 0; // Home tab
        break;
      case 'node_offline':
        tabIndex = 3; // Devices tab
        break;
      default:
        tabIndex = 0;
    }

    // Navigate to MainShell and switch to the correct tab
    navigator.pushNamedAndRemoveUntil('/', (_) => false,
        arguments: tabIndex);
  }

  String _titleFromType(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'emergency_alert':
        return 'Emergency Alert';
      case 'medication_reminder':
        return 'Medication Reminder';
      case 'node_offline':
        return 'Node Offline Warning';
      default:
        return 'KinConnect';
    }
  }

  Color _colorFromType(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'emergency_alert':
        return const Color(0xFFB22222);
      case 'medication_reminder':
        return const Color(0xFF3A7BD5);
      case 'node_offline':
        return const Color(0xFFD4920A);
      default:
        return const Color(0xFF2A2A2A);
    }
  }
}
