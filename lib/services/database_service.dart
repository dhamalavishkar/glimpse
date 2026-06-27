import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class DatabaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==== USER OPERATIONS ====

  static Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  static Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!, uid);
    }
    return null;
  }

  static Future<void> updatePinnedFriend(String uid, String? friendId) async {
    await _db.collection('users').doc(uid).update({
      'pinnedFriendId': friendId,
    });
  }

  // ==== USERNAME UNIQUENESS ====

  static Future<bool> isUsernameAvailable(String username) async {
    final cleanUsername = username.toLowerCase().trim();
    final doc = await _db.collection('usernames').doc(cleanUsername).get();
    return !doc.exists;
  }

  static Future<bool> claimUsername(String uid, String username) async {
    final cleanUsername = username.toLowerCase().trim();
    
    DocumentReference usernameRef = _db.collection('usernames').doc(cleanUsername);
    DocumentReference userRef = _db.collection('users').doc(uid);

    try {
      // Transaction would be safer in highly concurrent environments, 
      // but batch is usually sufficient for simple user flows.
      // Let's use a transaction to be completely safe against race conditions.
      bool success = await _db.runTransaction((transaction) async {
        final usernameDoc = await transaction.get(usernameRef);
        if (usernameDoc.exists) {
          return false; // Taken
        }

        transaction.set(usernameRef, {'uid': uid});
        transaction.update(userRef, {'username': cleanUsername});
        return true;
      });
      return success;
    } catch (e) {
      return false;
    }
  }

  // ==== FRIENDSHIP OPERATIONS ====

  static Future<void> createOrUpdateFriendship(String uid1, String uid2) async {
    // Generate a consistent ID regardless of who initiates
    final ids = [uid1, uid2]..sort();
    final friendshipId = '${ids[0]}_${ids[1]}';

    final docRef = _db.collection('friendships').doc(friendshipId);
    
    await _db.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) {
        transaction.set(docRef, {
          'users': [uid1, uid2],
          'nicknames': {},
          'streakCount': 0,
          'lastInteractionDate': Timestamp.now(),
        });
      }
    });
  }

  static Future<void> incrementStreak(String friendshipId) async {
    final docRef = _db.collection('friendships').doc(friendshipId);
    
    await _db.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) return;
      
      final data = doc.data()!;
      Timestamp lastInteraction = data['lastInteractionDate'] ?? Timestamp.now();
      int streak = data['streakCount'] ?? 0;
      
      final now = DateTime.now();
      final lastDate = lastInteraction.toDate();
      final difference = now.difference(lastDate).inHours;
      
      if (difference > 48) {
        streak = 1;
      } else if (now.day != lastDate.day) {
        streak += 1;
      }
      
      transaction.update(docRef, {
        'streakCount': streak,
        'lastInteractionDate': Timestamp.now(),
      });
    });
  }
}
