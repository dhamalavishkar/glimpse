import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../theme/liquid_glass.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _usernameController = TextEditingController();
  Timer? _debounce;
  bool _isChecking = false;
  bool? _isAvailable;
  bool _isInvalidFormat = false;
  bool _isSaving = false;
  bool _isUploadingPfp = false;
  String? _pfpUrl;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    
    if (pickedFile == null) return;

    setState(() {
      _isUploadingPfp = true;
    });

    try {
      final file = File(pickedFile.path);
      if (!file.existsSync()) throw Exception("Selected file does not exist.");

      final uid = FirebaseAuth.instance.currentUser!.uid;
      final storageRef = FirebaseStorage.instance.ref().child('users').child(uid).child('pfp.jpg');
      
      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask;
      
      if (snapshot.state != TaskState.success) {
        throw Exception('Upload failed. Check Firebase Storage rules.');
      }
      
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profilePicUrl': downloadUrl,
      });

      if (mounted) {
        setState(() {
          _pfpUrl = downloadUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated!')));
      }
    } catch (e) {
      if (mounted) {
        String errMsg = e.toString();
        if (errMsg.contains('object-not-found') || errMsg.contains('Object does not exist')) {
          errMsg = 'Firebase Storage is not enabled! Please click "Storage" in Firebase console and click "Get Started".';
        } else if (errMsg.contains('unauthorized')) {
          errMsg = 'Permission denied. Make sure Storage Rules are in Test Mode.';
        } else {
          errMsg = 'Upload failed: ${errMsg.split('] ').last}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errMsg), duration: const Duration(seconds: 5)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPfp = false;
        });
      }
    }
  }

  void _onUsernameChanged() {
    final text = _usernameController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _isAvailable = null;
        _isInvalidFormat = false;
        _isChecking = false;
      });
      return;
    }

    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(text)) {
      setState(() {
        _isAvailable = null;
        _isInvalidFormat = true;
        _isChecking = false;
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _isInvalidFormat = false;
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final available = await DatabaseService.isUsernameAvailable(text);
        if (mounted) {
          setState(() {
            _isAvailable = available;
            _isChecking = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isAvailable = null;
            _isChecking = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Database connecting, please try again in a moment.')),
          );
        }
      }
    });
  }

  Future<void> _saveProfile() async {
    if (_isAvailable != true) return;
    
    setState(() {
      _isSaving = true;
    });

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final username = _usernameController.text.trim();

    final result = await DatabaseService.claimUsername(uid, username);

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
      if (result == null) {
        // Pop or navigate to main screen if managed by AuthWrapper
        Navigator.of(context).pushReplacementNamed('/camera');
      } else if (result == 'USERNAME_TAKEN') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username was just taken! Try another.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error claiming username: $result')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF2A2A2A), Colors.black],
            radius: 1.5,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Set up your Profile',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 48),
                
                // PFP Upload
                GestureDetector(
                  onTap: _isUploadingPfp ? null : _pickAndUploadImage,
                  child: LiquidGlass(
                    borderRadius: 100,
                    padding: const EdgeInsets.all(8),
                    child: CircleAvatar(
                      radius: 64,
                      backgroundColor: Colors.black26,
                      backgroundImage: _pfpUrl != null ? NetworkImage(_pfpUrl!) : null,
                      child: _isUploadingPfp
                          ? const CircularProgressIndicator(color: Colors.amber)
                          : (_pfpUrl == null
                              ? const Icon(Icons.add_a_photo, size: 40, color: Colors.amber)
                              : null),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                
                LiquidGlass(
                  child: Column(
                    children: [
                      TextField(
                        controller: _usernameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Choose a username',
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: _isChecking
                              ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 16, height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
                                  ),
                                )
                              : _isAvailable == true
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : _isAvailable == false
                                      ? const Icon(Icons.error, color: Colors.red)
                                      : null,
                        ),
                      ),
                      if (_isChecking)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(color: Colors.amber, strokeWidth: 2),
                            ),
                          ),
                        if (_isInvalidFormat && _usernameController.text.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text('Only lowercase letters, numbers, and underscores allowed', style: TextStyle(color: Colors.red)),
                          ),
                        if (!_isChecking && _isAvailable == false && !_isInvalidFormat && _usernameController.text.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text('Username is taken', style: TextStyle(color: Colors.red)),
                          ),
                        if (!_isChecking && _isAvailable == true && !_isInvalidFormat && _usernameController.text.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text('Username available!', style: TextStyle(color: Colors.green)),
                          ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_isAvailable == true && !_isInvalidFormat && !_isSaving) ? _saveProfile : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            disabledBackgroundColor: Colors.amber.withValues(alpha: 0.3),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black))
                              : const Text('Continue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed('/camera');
                        },
                        child: const Text('Skip for now', style: TextStyle(color: Colors.white54)),
                      ),
                    ],
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
