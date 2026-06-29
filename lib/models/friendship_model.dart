class FriendshipModel {
  final String id;
  final List<String> users;
  final Map<String, String> nicknames;
  final int streakCount;
  final DateTime lastInteractionDate;

  FriendshipModel({
    required this.id,
    required this.users,
    required this.nicknames,
    this.streakCount = 0,
    required this.lastInteractionDate,
  });

  factory FriendshipModel.fromMap(Map<String, dynamic> data) {
    return FriendshipModel(
      id: data['id'],
      users: List<String>.from(data['users'] ?? []),
      nicknames: Map<String, String>.from(data['nicknames'] ?? {}),
      streakCount: data['streak_count'] ?? 0,
      lastInteractionDate: data['last_interaction_date'] != null 
          ? DateTime.parse(data['last_interaction_date']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'users': users,
      'nicknames': nicknames,
      'streak_count': streakCount,
      'last_interaction_date': lastInteractionDate.toIso8601String(),
    };
  }
}
