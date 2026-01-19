import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/alvo_theme.dart';
import 'package:gal/gal.dart'; // New import for saving

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // 1. Request Permissions
    var status = await Permission.camera.request();
    if (status.isDenied) return; // We will handle this later

    // 2. Get Cameras
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // 3. Select the first camera (Back Camera)
    _controller = CameraController(
      cameras[0],
      ResolutionPreset.max, // Highest quality possible
      enableAudio: false, // Crucial for photo-only apps
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // 4. Turn it on
    try {
      await _controller!.initialize();
      setState(() => _isCameraInitialized = true);
    } catch (e) {
      print("camera error: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: AlvoTheme.black,
        body: Center(child: Text("initializing...", style: TextStyle(color: AlvoTheme.amber))),
      );
    }

    return Scaffold(
      backgroundColor: AlvoTheme.black,
      body: Stack(
        fit: StackFit.expand, // 1. Forces the camera to fill the screen
        children: [
          // Layer 1: The Raw Camera Feed
          CameraPreview(_controller!),

          // Layer 2: The "Rule of Thirds" Grid
          CustomPaint(painter: GridPainter()),

          // Layer 3: Top Bar (Pinned to Top)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("system: active", style: AlvoTheme.mono),
                    const Icon(Icons.settings, color: AlvoTheme.green),
                  ],
                ),
              ),
            ),
          ),

          // Layer 4: Shutter Button (Pinned to Bottom)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center( // Centers the button horizontally
              child: GestureDetector(
                onTap: () async {
                  if (!_controller!.value.isInitialized) return;
                  try {
                    // Capture
                    final image = await _controller!.takePicture();
                    // Save
                    await Gal.putImage(image.path);
                    // Notify
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("image secured in gallery"),
                          backgroundColor: AlvoTheme.green,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  } catch (e) {
                    print("Error saving: $e");
                  }
                },
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AlvoTheme.amber, width: 3),
                    color: Colors.black.withOpacity(0.3),
                  ),
                  child: Center(
                    child: Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        color: AlvoTheme.amber.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// The "Cyber Grid" Painter
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 1;

    // Draw Vertical Lines
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(2 * size.width / 3, 0),
      Offset(2 * size.width / 3, size.height),
      paint,
    );

    // Draw Horizontal Lines
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(0, 2 * size.height / 3),
      Offset(size.width, 2 * size.height / 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
