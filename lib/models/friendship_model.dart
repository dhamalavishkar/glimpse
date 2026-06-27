import 'package:cloud_firestore/cloud_firestore.dart';

class FriendshipModel {
  final String id;
  final List<String> users;
  final Map<String, String> nicknames;
  final int streakCount;
  final Timestamp lastInteractionDate;

  FriendshipModel({
    required this.id,
    required this.users,
    required this.nicknames,
    this.streakCount = 0,
    required this.lastInteractionDate,
  });

  factory FriendshipModel.fromMap(Map<String, dynamic> data, String id) {
    return FriendshipModel(
      id: id,
      users: List<String>.from(data['users'] ?? []),
      nicknames: Map<String, String>.from(data['nicknames'] ?? {}),
      streakCount: data['streakCount'] ?? 0,
      lastInteractionDate: data['lastInteractionDate'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'users': users,
      'nicknames': nicknames,
      'streakCount': streakCount,
      'lastInteractionDate': lastInteractionDate,
    };
  }
}
