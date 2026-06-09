import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

import 'settings_screen.dart';
import '../core/settings_state.dart';

// Top-level isolate function for non-destructive background image compositing
Future<Uint8List> _compositeImageIsolate(Map<String, dynamic> params) async {
  final Uint8List rawBytes = params['rawBytes'];
  final Uint8List watermarkBytes = params['watermarkBytes'];

  // Decode the raw camera frame and the UI watermark layer
  img.Image? rawImage = img.decodeImage(rawBytes);
  img.Image? watermark = img.decodeImage(watermarkBytes);

  if (rawImage == null) throw Exception("Failed to decode raw high-res image");
  
  if (watermark != null) {
    const int masterWidth = 1080;

    // Scale raw image to masterWidth
    if (rawImage.width < masterWidth) {
      // Scale up low-res using nearest neighbor to preserve retro pixels
      rawImage = img.copyResize(rawImage, width: masterWidth, interpolation: img.Interpolation.nearest);
    } else if (rawImage.width > masterWidth) {
      // Scale down high-res
      rawImage = img.copyResize(rawImage, width: masterWidth, interpolation: img.Interpolation.linear);
    }

    // Scale watermark strip to exactly match masterWidth
    watermark = img.copyResize(watermark, width: masterWidth, interpolation: img.Interpolation.linear);

    // Create the master canvas: camera image + watermark strip below it
    int masterHeight = rawImage.height + watermark.height;
    img.Image canvas = img.Image(width: masterWidth, height: masterHeight);

    // Paste the raw image at the top (0, 0)
    img.compositeImage(canvas, rawImage, dstX: 0, dstY: 0);
    // Paste the solid white watermark strip at the bottom
    img.compositeImage(canvas, watermark, dstX: 0, dstY: rawImage.height);

    return Uint8List.fromList(img.encodeJpg(canvas, quality: 100));
  }

  // Re-encode and return the pristine JPG bytes
  return Uint8List.fromList(img.encodeJpg(rawImage, quality: 100));
}

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
  
  // Guard flags
  bool _isCapturing = false;
  bool _isSwitching = false;
  int _currentResolutionIndex = 4;

  late AnimationController _shutterAnimationController;
  late Animation<double> _shutterScaleAnimation;

  // Geolocation Data
  Position? _currentPosition;
  Placemark? _currentPlacemark;
  Timer? _locationTimer;
  final GlobalKey _watermarkKey = GlobalKey();

  // Background Processing Queue
  final List<Map<String, dynamic>> _processingQueue = [];
  bool _isQueueProcessing = false;

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

    _currentResolutionIndex = SettingsState.resolutionPresetIndex.value;
    
    // Listen to geolocation toggle to actively start/stop fetching location
    SettingsState.saveGeolocation.addListener(_handleLocationServiceState);
    _handleLocationServiceState();
    
    _initializeCamera();
  }

  void _handleLocationServiceState() {
    if (SettingsState.saveGeolocation.value) {
      _fetchLocation();
      _locationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        _fetchLocation();
      });
    } else {
      _locationTimer?.cancel();
      if (mounted) {
        setState(() {
          _currentPosition = null;
          _currentPlacemark = null;
        });
      }
    }
  }

  Future<void> _fetchLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    try {
      Position position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      if (mounted) {
        setState(() {
          _currentPosition = position;
          if (placemarks.isNotEmpty) {
            _currentPlacemark = placemarks[0];
          }
        });
      }
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  ResolutionPreset _getResolutionPreset(int index) {
    switch (index) {
      case 0: return ResolutionPreset.low; // 240p - Lo-Fi
      case 1: return ResolutionPreset.medium; // 480p
      case 2: return ResolutionPreset.high; // 720p
      case 3: return ResolutionPreset.veryHigh; // 1080p
      case 4: return ResolutionPreset.max; // Max Raw Sensor
      default: return ResolutionPreset.max;
    }
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
    if (_controller != null) {
      await _controller?.dispose();
      _controller = null;
    }

    final preset = _getResolutionPreset(_currentResolutionIndex);

    final newController = CameraController(
      cameraDescription,
      preset,
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
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final CameraController? cameraController = _controller;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (cameraController != null) {
        await cameraController.dispose();
        _controller = null;
        if (mounted) {
          setState(() {
            _isCameraInitialized = false;
          });
        }
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_cameras.isNotEmpty) {
        await _initCameraController(_cameras[_selectedCameraIndex]);
        if (mounted) {
          setState(() {}); 
        }
      }
    }
  }

  Future<Uint8List?> _captureWatermarkBytes() async {
    try {
      final RenderRepaintBoundary boundary =
          _watermarkKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      // Capture at a high pixel ratio for maximum clarity before scaling down in isolate
      final ui.Image image = await boundary.toImage(pixelRatio: 4.0); 
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Error capturing watermark: $e");
      return null;
    }
  }

  void _enqueueCapture(Uint8List rawBytes, Uint8List? watermarkBytes) {
    _processingQueue.add({
      'rawBytes': rawBytes,
      'watermarkBytes': watermarkBytes,
    });
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isQueueProcessing || _processingQueue.isEmpty) return;

    _isQueueProcessing = true;

    while (_processingQueue.isNotEmpty) {
      final task = _processingQueue.first;
      final Uint8List rawBytes = task['rawBytes'];
      final Uint8List? watermarkBytes = task['watermarkBytes'];

      Uint8List finalBytes = rawBytes;

      try {
        if (watermarkBytes != null) {
          // Offload the heavy scaling and compositing to a background Isolate
          finalBytes = await compute(_compositeImageIsolate, {
            'rawBytes': rawBytes,
            'watermarkBytes': watermarkBytes,
          });
        }

        // Save the finalized bytes to the device Gallery
        await Gal.putImageBytes(finalBytes, name: 'alvoCam_${DateTime.now().millisecondsSinceEpoch}');

        if (mounted) {
          final colorScheme = Theme.of(context).colorScheme;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Image saved to gallery", style: TextStyle(color: colorScheme.onInverseSurface)),
              backgroundColor: colorScheme.inverseSurface,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } catch (e) {
        debugPrint("Error processing background image task: $e");
      } finally {
        // Remove task from queue when finished
        _processingQueue.removeAt(0);
      }
    }

    _isQueueProcessing = false;
  }

  Future<void> _takePicture() async {
    if (_isCapturing || _controller == null || !_controller!.value.isInitialized) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      await _shutterAnimationController.forward();
      _shutterAnimationController.reverse();

      // 1. Immediately capture the raw high-res hardware image
      final XFile rawImageFile = await _controller!.takePicture();
      final Uint8List rawBytes = await rawImageFile.readAsBytes();
      
      // 2. If Geolocation is ON, capture ONLY the watermark card as bytes
      Uint8List? watermarkBytes;
      if (SettingsState.saveGeolocation.value && _currentPosition != null) {
        watermarkBytes = await _captureWatermarkBytes();
      }

      // 3. Queue the task for background compositing
      _enqueueCapture(rawBytes, watermarkBytes);

    } catch (e) {
      debugPrint("Error capturing image: $e");
    } finally {
      // 4. Fire-and-Forget: Release the shutter lock immediately.
      // This unblocks the UI and allows the user to take rapid photos.
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isCapturing || _isSwitching) return;
    
    HapticFeedback.mediumImpact();
    
    setState(() {
      _isSwitching = true;
      _isCameraInitialized = false;
    });
    
    try {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
      await _initCameraController(_cameras[_selectedCameraIndex]);
    } finally {
      if (mounted) {
        setState(() {
          _isSwitching = false;
        });
      }
    }
  }

  Future<void> _openSettings() async {
    HapticFeedback.mediumImpact();
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );

    if (_currentResolutionIndex != SettingsState.resolutionPresetIndex.value) {
      _currentResolutionIndex = SettingsState.resolutionPresetIndex.value;
      if (_cameras.isNotEmpty) {
        setState(() {
          _isCameraInitialized = false;
        });
        
        await _controller?.dispose();
        _controller = null;
        
        await _initCameraController(_cameras[_selectedCameraIndex]);
      }
    }
  }

  @override
  void dispose() {
    SettingsState.saveGeolocation.removeListener(_handleLocationServiceState);
    _locationTimer?.cancel();
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

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Viewfinder
            Expanded(
              child: Center(
                child: _isCameraInitialized && _controller != null
                    ? AspectRatio(
                        aspectRatio: 1 / _controller!.value.aspectRatio,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Geolocation Overlay Target (Hidden behind preview for clean capture)
                            if (SettingsState.saveGeolocation.value && _currentPosition != null)
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: RepaintBoundary(
                                  key: _watermarkKey,
                                  child: _buildWatermarkOverlay(),
                                ),
                              ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                color: Colors.black, // Block watermark from bleeding through corners
                                child: CameraPreview(_controller!),
                              ),
                            ),
                            ValueListenableBuilder<bool>(
                              valueListenable: SettingsState.showGridlines,
                              builder: (context, showGrid, child) {
                                if (!showGrid) return const SizedBox.shrink();
                                return IgnorePointer(
                                  child: CustomPaint(
                                    painter: GridPainter(color: Colors.white.withValues(alpha: 0.5)),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      )
                    : CircularProgressIndicator(color: colorScheme.primary),
              ),
            ),

            // Controls
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 32,
                    icon: Icon(Icons.settings, color: colorScheme.onSurface),
                    onPressed: _openSettings,
                  ),

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
                                color: _isCapturing 
                                    ? colorScheme.onSurface.withValues(alpha: 0.38) 
                                    : colorScheme.onSurface, 
                                width: 4
                              ),
                              color: Colors.transparent,
                            ),
                            child: Center(
                              child: _isCapturing 
                                ? CircularProgressIndicator(color: colorScheme.surface)
                                : Container(
                                    height: 64,
                                    width: 64,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  IconButton(
                    iconSize: 32,
                    icon: Icon(Icons.flip_camera_ios, color: colorScheme.onSurface),
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

  Widget _buildWatermarkOverlay() {
    final String address = _currentPlacemark != null 
      ? "${_currentPlacemark!.subLocality}, ${_currentPlacemark!.locality}" 
      : "Acquiring satellites...";
    final lat = _currentPosition?.latitude ?? 0.0;
    final lon = _currentPosition?.longitude ?? 0.0;
    final String dateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    final mapUrl = "https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lon&zoom=15&size=200x200&key=YOUR_API_KEY_HERE";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      color: Colors.white,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _currentPosition != null 
                ? Image.network(
                    mapUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 72,
                        height: 72,
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 72,
                        height: 72,
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: Text(
                            "Map\nUnavailable",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    width: 72,
                    height: 72,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.satellite_alt, color: Colors.black54, size: 36),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  address,
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'sans-serif'),
                ),
                const SizedBox(height: 4),
                Text(
                  "LAT: $lat",
                  style: const TextStyle(color: Colors.black54, fontSize: 13, fontFamily: 'sans-serif', fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  "LON: $lon",
                  style: const TextStyle(color: Colors.black54, fontSize: 13, fontFamily: 'sans-serif', fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  dateTime,
                  style: const TextStyle(color: Colors.black38, fontSize: 12, fontFamily: 'sans-serif', fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionScreen() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, size: 64, color: colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                "Camera Access Required",
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "alvoCam needs access to your camera to take photos. Please grant permission in your device settings.",
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
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

class GridPainter extends CustomPainter {
  final Color color;

  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;

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
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
