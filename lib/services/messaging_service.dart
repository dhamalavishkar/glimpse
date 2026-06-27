import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'widget_service.dart';
import 'database_service.dart';

class MessagingService {
  static Future<void> init() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleMessage(message);
    });
    
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<void> _handleMessage(RemoteMessage message) async {
    final String? imageUrl = message.data['image_url'];
    final String? senderId = message.data['sender_id'];
    final String? senderName = message.data['sender_name'];
    final int streakCount = int.tryParse(message.data['streak_count']?.toString() ?? '0') ?? 0;
    
    if (imageUrl != null && senderName != null && senderId != null) {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid != null) {
        final user = await DatabaseService.getUser(currentUid);
        final pinnedFriendId = user?.pinnedFriendId;
        
        // PHASE 5: Pinned Widget Filtering Logic
        if (pinnedFriendId == null || pinnedFriendId == senderId) {
          await WidgetService.updateWidget(
            imagePath: imageUrl,
            senderName: senderName,
            streak: streakCount,
          );
        } else {
          // Silently drops widget update, relies on Firestore to update feed UI
          debugPrint("Silent save triggered: sender $senderId is not the pinned friend.");
        }
      }
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await MessagingService._handleMessage(message);
}
