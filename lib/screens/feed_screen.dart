import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/liquid_glass.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with TickerProviderStateMixin {
  final List<_EmojiParticle> _particles = [];

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
            ListView.builder(
              padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 32),
              itemCount: 5, // Mock data
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: LiquidGlass(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 400,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Colors.black26,
                          ),
                          child: const Center(
                            child: Icon(Icons.image, size: 64, color: Colors.white24),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.amber,
                                    child: Icon(Icons.person, size: 16, color: Colors.black),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Friend ${index + 1}',
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
