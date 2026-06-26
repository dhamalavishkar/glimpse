import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'widget_service.dart';

class MessagingService {
  static Future<void> init() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    }

    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleMessage(message);
    });
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<void> _handleMessage(RemoteMessage message) async {
    final String? imageUrl = message.data['image_url'];
    final String? senderName = message.data['sender_name'];
    
    if (imageUrl != null && senderName != null) {
      // In a real app, download the image to local storage first,
      // then pass the local path to updateWidget.
      // For now, we mock the path.
      await WidgetService.updateWidget(
        imagePath: imageUrl,
        senderName: senderName,
      );
    }
  }
}

// Must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await MessagingService._handleMessage(message);
}
