class UserModel {
  final String uid;
  final String email;
  final String? username; // Strictly lowercase alphanumeric
  final String? profilePicUrl;
  final String? pinnedFriendId;

  UserModel({
    required this.uid,
    required this.email,
    this.username,
    this.profilePicUrl,
    this.pinnedFriendId,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      username: data['username'],
      profilePicUrl: data['profilePicUrl'],
      pinnedFriendId: data['pinnedFriendId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'profilePicUrl': profilePicUrl,
      'pinnedFriendId': pinnedFriendId,
    };
  }
}
