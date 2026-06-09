import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/settings_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _getResolutionLabel(int value) {
    switch (value) {
      case 0: return 'Lo-Fi';
      case 1: return 'Standard';
      case 2: return 'High';
      case 3: return 'Ultra';
      case 4: return 'Raw Sensor';
      default: return 'Raw Sensor';
    }
  }

  Future<void> _launchGitHub() async {
    final url = Uri.parse('https://github.com/alvin-alvo/alvoCam');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // Fallback if canLaunchUrl fails
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: SettingsState.saveGeolocation,
            builder: (context, saveGeo, child) {
              return SwitchListTile(
                title: Text(
                  'Geolocation',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                activeThumbColor: colorScheme.primary,
                activeTrackColor: colorScheme.primaryContainer,
                inactiveThumbColor: colorScheme.onSurfaceVariant,
                inactiveTrackColor: colorScheme.surfaceContainerHighest,
                value: saveGeo,
                onChanged: (bool value) {
                  SettingsState.saveGeolocation.value = value;
                },
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: SettingsState.showGridlines,
            builder: (context, showGrid, child) {
              return SwitchListTile(
                title: Text(
                  'Show Gridlines',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                activeThumbColor: colorScheme.primary,
                activeTrackColor: colorScheme.primaryContainer,
                inactiveThumbColor: colorScheme.onSurfaceVariant,
                inactiveTrackColor: colorScheme.surfaceContainerHighest,
                value: showGrid,
                onChanged: (bool value) {
                  SettingsState.showGridlines.value = value;
                },
              );
            },
          ),
          Divider(color: colorScheme.outlineVariant),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Camera Hardware',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ValueListenableBuilder<int>(
            valueListenable: SettingsState.resolutionPresetIndex,
            builder: (context, resolutionIndex, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Sensor Resolution', style: TextStyle(color: colorScheme.onSurface)),
                        Text(
                          _getResolutionLabel(resolutionIndex),
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Slider(
                    value: resolutionIndex.toDouble(),
                    min: 0,
                    max: 4,
                    divisions: 4,
                    activeColor: colorScheme.primary,
                    inactiveColor: colorScheme.surfaceContainerHighest,
                    onChanged: (double value) {
                      SettingsState.resolutionPresetIndex.value = value.toInt();
                    },
                  ),
                ],
              );
            },
          ),
          Divider(color: colorScheme.outlineVariant),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'About',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'A privacy-focused, minimalist camera module designed for raw optics and secure capture.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: InkWell(
              onTap: _launchGitHub,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Built by: alvoLabs',
                  style: TextStyle(
                    color: colorScheme.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
