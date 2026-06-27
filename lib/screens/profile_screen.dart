import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  bool _isSaving = false;

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

  void _onUsernameChanged() {
    final text = _usernameController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _isAvailable = null;
        _isChecking = false;
      });
      return;
    }

    // Must be lowercase alphanumeric
    if (!RegExp(r'^[a-z0-9]+$').hasMatch(text)) {
      setState(() {
        _isAvailable = false;
        _isChecking = false;
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _isAvailable = null;
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
            _isAvailable = false;
            _isChecking = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error checking username: ${e.toString().split('] ').last}')),
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

    final success = await DatabaseService.claimUsername(uid, username);

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
      if (success) {
        // Pop or navigate to main screen if managed by AuthWrapper
        Navigator.of(context).pushReplacementNamed('/camera');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username was just taken! Try another.')),
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
                
                // PFP Upload Placeholder
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Image upload stub')),
                    );
                  },
                  child: LiquidGlass(
                    borderRadius: 100,
                    padding: const EdgeInsets.all(32),
                    child: const Icon(Icons.add_a_photo, size: 64, color: Colors.amber),
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
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_isAvailable == true && !_isSaving) ? _saveProfile : null,
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
