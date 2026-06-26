import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

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
      setState(() {
        _isInitializing = false;
      });
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
    
    setState(() {
      _isInitializing = false;
    });
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final XFile file = await _controller!.takePicture();
      // TODO: Navigate to preview and send screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Picture taken! (Upload not implemented yet)')),
      );
    } catch (e) {
      debugPrint("Error taking picture: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    if (_cameras.isEmpty || _controller == null) {
      return const Scaffold(
        body: Center(child: Text("No cameras found")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview inside a rounded rectangle
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 64.0, bottom: 120.0, left: 16, right: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: CameraPreview(_controller!),
              ),
            ),
          ),
          
          // Top Navigation
          Positioned(
            top: 60,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.people, size: 32),
                  color: Colors.white,
                  onPressed: () => Navigator.pushNamed(context, '/friends'),
                ),
                const Text(
                  "Glimpse",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
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
          
          // Bottom Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const SizedBox(width: 48), // Balance spacing
                
                // Shutter Button
                GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber, width: 6),
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
                
                // Flip Camera Button
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
