class FriendRequestModel {
  final String id;
  final String fromUid;
  final String toUid;
  final String status;
  final DateTime createdAt;

  FriendRequestModel({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequestModel.fromMap(Map<String, dynamic> data) {
    return FriendRequestModel(
      id: data['id'],
      fromUid: data['from_uid'],
      toUid: data['to_uid'],
      status: data['status'] ?? 'pending',
      createdAt: data['created_at'] != null 
          ? DateTime.parse(data['created_at']) 
          : DateTime.now(),
    );
  }
}
