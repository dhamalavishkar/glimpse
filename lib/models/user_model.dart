class UserModel {
  final String uid;
  final String email;
  final String? username;
  final String? profilePicUrl;
  final String? pinnedFriendId;

  UserModel({
    required this.uid,
    required this.email,
    this.username,
    this.profilePicUrl,
    this.pinnedFriendId,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['id'] ?? '',
      email: data['email'] ?? '',
      username: data['username'],
      profilePicUrl: data['profile_pic_url'] ?? data['profilePicUrl'],
      pinnedFriendId: data['pinned_friend_id'] ?? data['pinnedFriendId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': uid,
      'email': email,
      'username': username,
      'profile_pic_url': profilePicUrl,
      'pinned_friend_id': pinnedFriendId,
    };
  }
}
