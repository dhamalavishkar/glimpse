import 'package:flutter/material.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.amber),
            onPressed: () {
              // Show add friend dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Add Friend"),
                  content: const TextField(
                    decoration: InputDecoration(hintText: "Enter friend's email"),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text("Add"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3, // Mock data
        itemBuilder: (context, index) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            leading: const CircleAvatar(
              radius: 24,
              backgroundColor: Colors.amber,
              child: Icon(Icons.person, color: Colors.black),
            ),
            title: Text(
              'Close Friend ${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: const Text('Added 2 days ago'),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.white38),
              onPressed: () {},
            ),
          );
        },
      ),
    );
  }
}
