import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class DatabaseService {
  static final SupabaseClient _db = Supabase.instance.client;

  // ==== USER OPERATIONS ====

  static Future<void> createUser(UserModel user) async {
    await _db.from('users').upsert({
      'id': user.uid,
      'email': user.email,
      'username': user.username,
      'profile_pic_url': user.profilePicUrl,
      'pinned_friend_id': user.pinnedFriendId,
    });
  }

  static Future<UserModel?> getUser(String uid) async {
    final data = await _db.from('users').select().eq('id', uid).maybeSingle();
    if (data != null) {
      return UserModel(
        uid: data['id'],
        email: data['email'],
        username: data['username'],
        profilePicUrl: data['profile_pic_url'],
        pinnedFriendId: data['pinned_friend_id'],
      );
    }
    return null;
  }

  static Future<void> updatePinnedFriend(String uid, String? friendId) async {
    await _db.from('users').update({
      'pinned_friend_id': friendId,
    }).eq('id', uid);
  }

  // ==== USERNAME UNIQUENESS ====

  static Future<bool> isUsernameAvailable(String username) async {
    final cleanUsername = username.toLowerCase().trim();
    final data = await _db.from('users').select('id').eq('username', cleanUsername).maybeSingle();
    return data == null;
  }

  static Future<String?> claimUsername(String uid, String username, {String? oldUsername}) async {
    final cleanUsername = username.toLowerCase().trim();
    try {
      await _db.from('users').update({
        'username': cleanUsername,
      }).eq('id', uid);
      return null;
    } catch (e) {
      if (e.toString().contains('duplicate key value violates unique constraint') || e.toString().contains('users_username_key')) {
        return 'USERNAME_TAKEN';
      }
      return e.toString();
    }
  }

  // ==== FRIENDSHIP OPERATIONS ====

  static Future<void> createOrUpdateFriendship(String uid1, String uid2) async {
    final ids = [uid1, uid2]..sort();
    final friendshipId = '${ids[0]}_${ids[1]}';

    final existing = await _db.from('friendships').select().eq('id', friendshipId).maybeSingle();
    if (existing == null) {
      await _db.from('friendships').insert({
        'id': friendshipId,
        'users': [uid1, uid2],
        'nicknames': {},
        'streak_count': 0,
        'last_interaction_date': DateTime.now().toIso8601String(),
      });
    }
  }

  static Future<void> incrementStreak(String friendshipId) async {
    final data = await _db.from('friendships').select().eq('id', friendshipId).maybeSingle();
    if (data == null) return;
    
    DateTime lastInteraction = DateTime.parse(data['last_interaction_date']);
    int streak = data['streak_count'] ?? 0;
    
    final now = DateTime.now();
    final difference = now.difference(lastInteraction).inHours;
    
    if (difference > 48) {
      streak = 1;
    } else if (now.day != lastInteraction.day) {
      streak += 1;
    }
    
    await _db.from('friendships').update({
      'streak_count': streak,
      'last_interaction_date': DateTime.now().toIso8601String(),
    }).eq('id', friendshipId);
  }

  // ==== FRIEND REQUESTS ====

  static Future<void> sendFriendRequest(String fromUid, String toUid) async {
    // Check if request already exists
    final existing = await _db.from('friend_requests')
        .select()
        .eq('from_uid', fromUid)
        .eq('to_uid', toUid)
        .eq('status', 'pending')
        .maybeSingle();
        
    if (existing == null) {
      await _db.from('friend_requests').insert({
        'from_uid': fromUid,
        'to_uid': toUid,
        'status': 'pending',
      });
    }
  }

  static Future<void> acceptFriendRequest(String requestId, String fromUid, String toUid) async {
    await _db.from('friend_requests').delete().eq('id', requestId);
    await createOrUpdateFriendship(fromUid, toUid);
  }

  static Future<void> rejectFriendRequest(String requestId) async {
    await _db.from('friend_requests').delete().eq('id', requestId);
  }
}
