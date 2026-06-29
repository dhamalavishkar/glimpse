import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/friendship_model.dart';
import '../models/friend_request_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../theme/liquid_glass.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final String _currentUid = Supabase.instance.client.auth.currentUser!.id;
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
                  final newNicknames = Map<String, String>.from(friendship.nicknames);
                  newNicknames[friendId] = controller.text.trim();
                  
                  await Supabase.instance.client.from('friendships').update({
                    'nicknames': newNicknames,
                  }).eq('id', friendship.id);
                  
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

  Widget _buildRequestsInbox() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Stream.periodic(const Duration(seconds: 3)).asyncMap((_) async {
        return await Supabase.instance.client
            .from('friend_requests')
            .select()
            .eq('to_uid', _currentUid)
            .eq('status', 'pending');
      }),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); // Hide if empty
        }

        final requests = snapshot.data!.map((data) => FriendRequestModel.fromMap(data)).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8.0, bottom: 8.0, top: 100),
              child: Text(
                'Friend Requests',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...requests.map((request) {
              return FutureBuilder<UserModel?>(
                future: DatabaseService.getUser(request.fromUid),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const SizedBox.shrink();
                  final sender = userSnap.data!;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: LiquidGlass(
                      padding: const EdgeInsets.all(12),
                      borderRadius: 16,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.amber,
                          backgroundImage: sender.profilePicUrl != null ? NetworkImage(sender.profilePicUrl!) : null,
                          child: sender.profilePicUrl == null ? const Icon(Icons.person, color: Colors.black) : null,
                        ),
                        title: Text(sender.username ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: const Text('wants to be your friend', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.redAccent),
                              onPressed: () => DatabaseService.rejectFriendRequest(request.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => DatabaseService.acceptFriendRequest(request.id, request.fromUid, request.toUid),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
            const Divider(color: Colors.white24, height: 32),
          ],
        );
      },
    );
  }

  Widget _buildFriendsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Stream.periodic(const Duration(seconds: 3)).asyncMap((_) async {
        return await Supabase.instance.client
            .from('friendships')
            .select()
            .contains('users', '{${_currentUid}}');
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.amber));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No friends yet.", style: TextStyle(color: Colors.white54)));
        }

        final friendships = snapshot.data!.map((data) => FriendshipModel.fromMap(data)).toList();

        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 32),
          itemCount: friendships.length,
          itemBuilder: (context, index) {
            final friendship = friendships[index];
            final friendId = friendship.users.firstWhere((id) => id != _currentUid);
            
            return FutureBuilder<UserModel?>(
              future: DatabaseService.getUser(friendId),
              builder: (context, userSnap) {
                if (!userSnap.hasData) return const SizedBox();
                final friend = userSnap.data!;
                
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: Column(
            children: [
              _buildRequestsInbox(),
              // Give some padding if inbox is empty to push list down past appbar
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: Stream.periodic(const Duration(seconds: 3)).asyncMap((_) async {
                  return await Supabase.instance.client
                      .from('friend_requests')
                      .select()
                      .eq('to_uid', _currentUid)
                      .eq('status', 'pending');
                }),
                builder: (context, snap) {
                  if (!snap.hasData || snap.data!.isEmpty) {
                    return const SizedBox(height: 100);
                  }
                  return const SizedBox.shrink();
                }
              ),
              _buildFriendsList(),
            ],
          ),
        ),
      ),
    );
  }
}
