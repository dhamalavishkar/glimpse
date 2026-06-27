import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../theme/liquid_glass.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with TickerProviderStateMixin {
  final List<_EmojiParticle> _particles = [];
  final Map<String, UserModel> _userCache = {};

  void _triggerReaction(String emoji, Offset position) {
    final random = Random();
    for (int i = 0; i < 20; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1000 + random.nextInt(1000)),
      );
      
      final particle = _EmojiParticle(
        emoji: emoji,
        startPos: position,
        endPos: Offset(
          position.dx + (random.nextDouble() * 200 - 100),
          position.dy + 300 + random.nextDouble() * 200,
        ),
        controller: controller,
      );
      
      setState(() {
        _particles.add(particle);
      });
      
      controller.forward().then((_) {
        if (mounted) {
          setState(() {
            _particles.remove(particle);
          });
          controller.dispose();
        }
      });
    }
  }

  Future<UserModel?> _getUser(String uid) async {
    if (_userCache.containsKey(uid)) return _userCache[uid];
    final user = await DatabaseService.getUser(uid);
    if (user != null) {
      _userCache[uid] = user;
    }
    return user;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('History', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF2A2A2A), Colors.black],
            radius: 1.5,
          ),
        ),
        child: Stack(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('glimpses')
                  .orderBy('timestamp', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.amber));
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No glimpses yet. Be the first to share!", style: TextStyle(color: Colors.white54)));
                }

                final glimpses = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 32),
                  itemCount: glimpses.length,
                  itemBuilder: (context, index) {
                    final data = glimpses[index].data() as Map<String, dynamic>;
                    final senderId = data['senderId'] as String;
                    final imageUrl = data['imageUrl'] as String;
                    final note = data['note'] as String?;

                    return FutureBuilder<UserModel?>(
                      future: _getUser(senderId),
                      builder: (context, userSnap) {
                        final user = userSnap.data;
                        final username = user?.username ?? user?.email ?? 'Unknown Friend';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          child: LiquidGlass(
                            padding: EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      height: 400,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.black26,
                                        image: DecorationImage(
                                          image: NetworkImage(imageUrl),
                                          fit: BoxFit.cover,
                                        )
                                      ),
                                    ),
                                    if (note != null && note.isNotEmpty)
                                      Positioned.fill(
                                        child: Center(
                                          child: Text(
                                            note, 
                                            style: const TextStyle(
                                              fontSize: 28, 
                                              fontWeight: FontWeight.bold, 
                                              color: Colors.white,
                                              shadows: [Shadow(color: Colors.black, blurRadius: 10)]
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: Colors.amber,
                                            backgroundImage: user?.profilePicUrl != null ? NetworkImage(user!.profilePicUrl!) : null,
                                            child: user?.profilePicUrl == null ? const Icon(Icons.person, size: 16, color: Colors.black) : null,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            username,
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          _buildReactionEmoji('❤️'),
                                          const SizedBox(width: 8),
                                          _buildReactionEmoji('😂'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              }
            ),
            
            // Particles overlay
            ..._particles.map((p) => AnimatedBuilder(
              animation: p.controller,
              builder: (context, child) {
                return Positioned(
                  left: Tween<double>(begin: p.startPos.dx, end: p.endPos.dx)
                      .transform(Curves.easeOutQuad.transform(p.controller.value)),
                  top: Tween<double>(begin: p.startPos.dy, end: p.endPos.dy)
                      .transform(Curves.easeInQuad.transform(p.controller.value)),
                  child: Opacity(
                    opacity: 1.0 - p.controller.value,
                    child: Text(p.emoji, style: const TextStyle(fontSize: 24)),
                  ),
                );
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionEmoji(String emoji) {
    return Builder(
      builder: (ctx) {
        return GestureDetector(
          onTap: () {
            final box = ctx.findRenderObject() as RenderBox;
            final position = box.localToGlobal(Offset.zero);
            _triggerReaction(emoji, position);
          },
          child: LiquidGlass(
            borderRadius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(emoji, style: const TextStyle(fontSize: 16)),
          ),
        );
      }
    );
  }
}

class _EmojiParticle {
  final String emoji;
  final Offset startPos;
  final Offset endPos;
  final AnimationController controller;

  _EmojiParticle({
    required this.emoji,
    required this.startPos,
    required this.endPos,
    required this.controller,
  });
}
