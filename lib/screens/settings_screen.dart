import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../theme/liquid_glass.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserModel? _user;
  bool _isLoading = true;
  bool _isUploading = false;
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await DatabaseService.getUser(_uid);
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    
    if (pickedFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final storageRef = FirebaseStorage.instance.ref().child('users').child(_uid).child('pfp.jpg');
      await storageRef.putFile(File(pickedFile.path));
      final downloadUrl = await storageRef.getDownloadURL();
      
      await FirebaseFirestore.instance.collection('users').doc(_uid).update({
        'profilePicUrl': downloadUrl,
      });

      await _loadUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: ${e.toString().split('] ').last}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Profile & Settings', style: TextStyle(fontWeight: FontWeight.bold)),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.amber))
            : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(24.0),
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _isUploading ? null : _pickAndUploadImage,
                        child: LiquidGlass(
                          borderRadius: 100,
                          padding: const EdgeInsets.all(8),
                          child: CircleAvatar(
                            radius: 64,
                            backgroundColor: Colors.black26,
                            backgroundImage: _user?.profilePicUrl != null ? NetworkImage(_user!.profilePicUrl!) : null,
                            child: _isUploading
                                ? const CircularProgressIndicator(color: Colors.amber)
                                : (_user?.profilePicUrl == null
                                    ? const Icon(Icons.add_a_photo, size: 40, color: Colors.amber)
                                    : null),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    LiquidGlass(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.person, color: Colors.amber),
                            title: const Text('Username', style: TextStyle(color: Colors.white54)),
                            subtitle: Text(_user?.username ?? 'Not set', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          const Divider(color: Colors.white24),
                          ListTile(
                            leading: const Icon(Icons.email, color: Colors.amber),
                            title: const Text('Email', style: TextStyle(color: Colors.white54)),
                            subtitle: Text(_user?.email ?? '', style: const TextStyle(color: Colors.white, fontSize: 18)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    LiquidGlass(
                      child: Column(
                        children: [
                          const ListTile(
                            title: Text('About Glimpse', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              'Glimpse allows you to instantly share photo updates to your friends\' home screens.\n\n'
                              'Features:\n- Private Friend Groups\n- Liquid Glass Interface\n- Ghost Notes & Reactions\n- Pinned Widgets\n\n'
                              'Glimpse is owned by LOOM INTELLIGENCE.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                        foregroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _signOut,
                      child: const Text('Log Out', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
