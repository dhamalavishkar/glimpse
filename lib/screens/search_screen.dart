import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../theme/liquid_glass.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<UserModel> _results = [];
  bool _isSearching = false;

  void _performSearch(String query) async {
    final text = query.trim().toLowerCase();
    if (text.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    try {
      // Partial prefix match using \uf8ff trick
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: text)
          .where('username', isLessThanOrEqualTo: '$text\uf8ff')
          .limit(10)
          .get();

      final List<UserModel> found = [];
      for (var doc in snapshot.docs) {
        if (doc.id != currentUid) {
          found.add(UserModel.fromMap(doc.data(), doc.id));
        }
      }

      if (mounted) {
        setState(() {
          _results = found;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _addFriend(UserModel user) async {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    await DatabaseService.createOrUpdateFriendship(currentUid, user.uid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${user.username ?? user.email} as a friend!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Search Friends', style: TextStyle(fontWeight: FontWeight.bold)),
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                LiquidGlass(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  borderRadius: 30,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search by username...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search, color: Colors.amber),
                        onPressed: () => _performSearch(_searchController.text),
                      ),
                    ),
                    onSubmitted: _performSearch,
                  ),
                ),
                const SizedBox(height: 24),
                if (_isSearching)
                  const CircularProgressIndicator(color: Colors.amber)
                else if (_results.isEmpty && _searchController.text.isNotEmpty)
                  const Text('No users found.', style: TextStyle(color: Colors.white54))
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final user = _results[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: LiquidGlass(
                            padding: const EdgeInsets.all(12),
                            borderRadius: 16,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.amber,
                                backgroundImage: user.profilePicUrl != null ? NetworkImage(user.profilePicUrl!) : null,
                                child: user.profilePicUrl == null ? const Icon(Icons.person, color: Colors.black) : null,
                              ),
                              title: Text(
                                user.username ?? 'Unknown',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              subtitle: Text(
                                user.email,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.person_add, color: Colors.amber),
                                onPressed: () => _addFriend(user),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
