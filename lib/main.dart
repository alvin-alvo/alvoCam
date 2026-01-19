import 'package:flutter/material.dart';
import 'core/alvo_theme.dart';
import 'ui/camera_screen.dart'; // Import the new screen

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AlvoCamApp());
}

class AlvoCamApp extends StatelessWidget {
  const AlvoCamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'alvocam',
      debugShowCheckedModeBanner: false,
      theme: AlvoTheme.theme,
      home: const CameraScreen(), // Switch to the camera view
    );
  }
}