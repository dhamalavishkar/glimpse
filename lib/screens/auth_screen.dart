import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/liquid_glass.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => LiquidGlass(
        child: AlertDialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('About Glimpse', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Glimpse allows you to instantly share photo updates to your friends\' home screens.\n\n'
            'Features:\n'
            '- Private Friend Groups\n'
            '- Liquid Glass Interface\n'
            '- Ghost Notes & Reactions\n'
            '- Pinned Widgets\n\n'
            'Glimpse is owned by LOOM INTELLIGENCE.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.amber)),
            )
          ],
        ),
      ),
    );
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Replaced heart icon with a placeholder logo box per instructions
                const Center(
                  child: Icon(Icons.lens_blur, size: 100, color: Colors.amber),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Glimpse',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Text(
                  'by LOOM INTELLIGENCE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 4,
                    color: Colors.amber,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                LiquidGlass(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      TextField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Email',
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 10,
                            shadowColor: Colors.amber.withValues(alpha: 0.5),
                          ),
                          child: _isLoading 
                              ? const SizedBox(
                                  height: 20, width: 20,
                                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                )
                              : Text(
                                  _isLogin ? 'Log In' : 'Sign Up',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                          });
                        },
                        child: Text(
                          _isLogin ? "Don't have an account? Sign up" : "Already have an account? Log in",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                TextButton(
                  onPressed: _showAboutDialog,
                  child: const Text('About & Terms', style: TextStyle(color: Colors.white54)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
