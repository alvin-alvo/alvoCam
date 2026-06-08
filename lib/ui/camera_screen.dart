import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';
import 'settings_screen.dart';
import '../core/settings_state.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isPermissionDenied = false;
  int _selectedCameraIndex = 0;
  
  // Guard flag for rapid captures
  bool _isCapturing = false;

  late AnimationController _shutterAnimationController;
  late Animation<double> _shutterScaleAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _shutterAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _shutterScaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(
        parent: _shutterAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        setState(() {
          _isPermissionDenied = true;
          _isCameraInitialized = false;
        });
      }
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      await _initCameraController(_cameras[_selectedCameraIndex]);
    } catch (e) {
      debugPrint("Camera error: $e");
    }
  }

  Future<void> _initCameraController(CameraDescription cameraDescription) async {
    // 1. Sequential Switching: Fully unawait and dispose of the existing controller
    if (_controller != null) {
      await _controller?.dispose();
      _controller = null;
    }

    // 2. Initialize the new controller
    final newController = CameraController(
      cameraDescription,
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await newController.initialize();
      _controller = newController;
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isPermissionDenied = false;
        });
      }
    } on CameraException catch (e) {
      debugPrint("Camera Error: ${e.description}");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // Free up memory and hardware locks when the camera is not active
      cameraController.dispose();
      _controller = null;
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize the camera carefully
      _initCameraController(cameraController.description);
    }
  }

  Future<void> _takePicture() async {
    // Shutter Lock: Prevent multiple rapid taps
    if (_isCapturing || _controller == null || !_controller!.value.isInitialized) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      // Trigger Shutter Animation
      await _shutterAnimationController.forward();
      _shutterAnimationController.reverse();

      final image = await _controller!.takePicture();
      await Gal.putImage(image.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Image saved to gallery"),
            backgroundColor: Colors.white24,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error saving image: $e");
    } finally {
      // Always unlock the shutter, even if capture fails
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isCapturing) return;
    
    HapticFeedback.lightImpact();
    
    setState(() {
      _isCameraInitialized = false; // Show loading indicator during switch
    });
    
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initCameraController(_cameras[_selectedCameraIndex]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _shutterAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isPermissionDenied) {
      return _buildPermissionScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Viewfinder (3:4 aspect ratio)
            Expanded(
              child: Center(
                child: _isCameraInitialized && _controller != null
                    ? AspectRatio(
                        aspectRatio: 3 / 4,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CameraPreview(_controller!),
                            ),
                            // Settings Integration: Dynamically show/hide gridlines
                            ValueListenableBuilder<bool>(
                              valueListenable: SettingsState.showGridlines,
                              builder: (context, showGrid, child) {
                                if (!showGrid) return const SizedBox.shrink();
                                return CustomPaint(
                                  painter: GridPainter(),
                                );
                              },
                            ),
                          ],
                        ),
                      )
                    : const CircularProgressIndicator(color: Colors.white),
              ),
            ),

            // Bottom Controls Area
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Settings Button
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),

                  // Shutter Button
                  GestureDetector(
                    onTap: _takePicture,
                    child: AnimatedBuilder(
                      animation: _shutterScaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _shutterScaleAnimation.value,
                          child: Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isCapturing ? Colors.white38 : Colors.white, 
                                width: 4
                              ),
                              color: Colors.transparent,
                            ),
                            child: Center(
                              child: Container(
                                height: 64,
                                width: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isCapturing ? Colors.white38 : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Switch Camera Button
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                    onPressed: _cameras.length > 1 ? _switchCamera : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 64, color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                "Camera Access Required",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "alvoCam needs access to your camera to take photos. Please grant permission in your device settings.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () async {
                  await openAppSettings();
                },
                child: const Text("Open Settings"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Painter for the Rule of Thirds Grid
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
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
