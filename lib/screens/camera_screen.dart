import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/liquid_glass.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isInitializing = true;
  
  final _noteController = TextEditingController();
  bool _isWritingNote = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _selectedCameraIndex = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
        if (_selectedCameraIndex == -1) _selectedCameraIndex = 0;
        await _setupCameraController();
      }
    } catch (e) {
      debugPrint("Error initializing camera: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _setupCameraController() async {
    if (_cameras.isEmpty) return;
    
    _controller = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );
    
    await _controller!.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  void _flipCamera() async {
    if (_cameras.length < 2) return;
    setState(() {
      _isInitializing = true;
    });
    
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _setupCameraController();
    
    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final XFile file = await _controller!.takePicture();
      if (!mounted) return;
      
      final note = _noteController.text.trim();
      final imagePath = file.path;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading Glimpse...')),
      );

      final uid = FirebaseAuth.instance.currentUser!.uid;

      try {
        final file = File(imagePath);
        if (!file.existsSync()) throw Exception("Camera file not found.");

        final storageRef = FirebaseStorage.instance.ref().child('glimpses').child(uid).child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        
        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask;
        
        if (snapshot.state != TaskState.success) {
          throw Exception('Upload failed. Check Firebase Storage rules.');
        }

        final downloadUrl = await snapshot.ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('glimpses').add({
          'senderId': uid,
          'imageUrl': downloadUrl,
          'note': note,
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Glimpse sent!')));
          setState(() {
            _isWritingNote = false;
            _noteController.clear();
          });
        }
      } catch (e) {
        if (mounted) {
          String errMsg = e.toString();
          if (errMsg.contains('object-not-found') || errMsg.contains('Object does not exist')) {
            errMsg = 'Firebase Storage is not enabled! Please click "Storage" in Firebase console and click "Get Started".';
          } else if (errMsg.contains('unauthorized')) {
            errMsg = 'Permission denied. Make sure Storage Rules are in Test Mode.';
          } else {
            errMsg = 'Failed to send Glimpse: ${errMsg.split('] ').last}';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errMsg), duration: const Duration(seconds: 5)),
          );
        }
      }
    } catch (e) {
      debugPrint("Error taking picture: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    if (_cameras.isEmpty || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text("No cameras found", style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [Color(0xFF2A2A2A), Colors.black],
                radius: 1.5,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 64.0, bottom: 120.0, left: 16, right: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(_controller!),
                    if (_isWritingNote || _noteController.text.isNotEmpty)
                      Center(
                        child: LiquidGlass(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: IntrinsicWidth(
                            child: TextField(
                              controller: _noteController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                hintText: 'Type a note...',
                                hintStyle: TextStyle(color: Colors.white54),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) {
                                setState(() {
                                  _isWritingNote = false;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.person, size: 32),
                      color: Colors.white,
                      onPressed: () => Navigator.pushNamed(context, '/settings'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.people, size: 32),
                      color: Colors.white,
                      onPressed: () => Navigator.pushNamed(context, '/friends'),
                    ),
                  ],
                ),
                LiquidGlass(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  borderRadius: 30,
                  child: const Text(
                    "Glimpse",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.history, size: 32),
                  color: Colors.white,
                  onPressed: () => Navigator.pushNamed(context, '/feed'),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.text_fields, size: 32, color: _isWritingNote ? Colors.amber : Colors.white),
                  onPressed: () {
                    setState(() {
                      _isWritingNote = !_isWritingNote;
                    });
                  },
                ),
                GestureDetector(
                  onTap: _takePicture,
                  child: LiquidGlass(
                    borderRadius: 100,
                    padding: const EdgeInsets.all(8),
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amber, width: 4),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.flip_camera_ios, size: 32),
                  color: Colors.white,
                  onPressed: _flipCamera,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
