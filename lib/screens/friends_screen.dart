import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/friendship_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../theme/liquid_glass.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final String _currentUid = FirebaseAuth.instance.currentUser!.uid;
  String? _pinnedFriendId;

  @override
  void initState() {
    super.initState();
    _loadPinnedFriend();
  }

  void _loadPinnedFriend() async {
    final user = await DatabaseService.getUser(_currentUid);
    if (mounted) {
      setState(() {
        _pinnedFriendId = user?.pinnedFriendId;
      });
    }
  }

  void _togglePin(String friendId) async {
    final newPin = (_pinnedFriendId == friendId) ? null : friendId;
    await DatabaseService.updatePinnedFriend(_currentUid, newPin);
    setState(() {
      _pinnedFriendId = newPin;
    });
  }

  void _editNickname(FriendshipModel friendship, String friendId, String currentName) {
    final controller = TextEditingController(text: currentName);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => LiquidGlass(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24, left: 24, right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Set Nickname", style: TextStyle(color: Colors.white, fontSize: 20)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nickname',
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('friendships').doc(friendship.id).update({
                    'nicknames.$friendId': controller.text.trim(),
                  });
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Friends', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.amber),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF2A2A2A), Colors.black],
            radius: 1.5,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('friendships')
              .where('users', arrayContains: _currentUid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.amber));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No friends yet.", style: TextStyle(color: Colors.white54)));
            }

            final friendships = snapshot.data!.docs.map((doc) => 
                FriendshipModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

            return ListView.builder(
              padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 32),
              itemCount: friendships.length,
              itemBuilder: (context, index) {
                final friendship = friendships[index];
                final friendId = friendship.users.firstWhere((id) => id != _currentUid);
                
                return FutureBuilder<UserModel?>(
                  future: DatabaseService.getUser(friendId),
                  builder: (context, userSnap) {
                    if (!userSnap.hasData) return const SizedBox();
                    final friend = userSnap.data!;
                    
                    // Display nickname if exists, else username
                    final displayName = friendship.nicknames[friendId] ?? friend.username ?? friend.email;
                    final isPinned = _pinnedFriendId == friendId;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onLongPress: () => _editNickname(friendship, friendId, displayName),
                        child: LiquidGlass(
                          padding: const EdgeInsets.all(12),
                          borderRadius: 16,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.amber,
                              backgroundImage: friend.profilePicUrl != null ? NetworkImage(friend.profilePicUrl!) : null,
                              child: friend.profilePicUrl == null ? const Icon(Icons.person, color: Colors.black) : null,
                            ),
                            title: Row(
                              children: [
                                Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                if (friendship.streakCount > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text('🔥 ${friendship.streakCount}'),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                                color: isPinned ? Colors.amber : Colors.white38,
                              ),
                              onPressed: () => _togglePin(friendId),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
