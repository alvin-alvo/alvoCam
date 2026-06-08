import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'ui/camera_screen.dart';
import 'core/settings_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsState.initialize();
  runApp(const AlvoCamApp());
}

class AlvoCamApp extends StatelessWidget {
  const AlvoCamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'alvocam',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.system,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightDynamic ?? ColorScheme.fromSeed(
              seedColor: Colors.amber, 
              brightness: Brightness.light
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkDynamic ?? ColorScheme.fromSeed(
              seedColor: Colors.amber, 
              brightness: Brightness.dark
            ),
          ),
          home: const CameraScreen(),
        );
      },
    );
  }
}