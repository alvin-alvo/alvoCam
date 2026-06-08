import 'package:flutter/material.dart';
import '../core/settings_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: SettingsState.saveGeolocation,
            builder: (context, saveGeo, child) {
              return SwitchListTile(
                title: const Text(
                  'Save Geolocation',
                  style: TextStyle(color: Colors.white),
                ),
                activeThumbColor: Colors.white,
                activeTrackColor: Colors.grey.shade700,
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.grey.shade900,
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
                title: const Text(
                  'Show Gridlines',
                  style: TextStyle(color: Colors.white),
                ),
                activeThumbColor: Colors.white,
                activeTrackColor: Colors.grey.shade700,
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.grey.shade900,
                value: showGrid,
                onChanged: (bool value) {
                  SettingsState.showGridlines.value = value;
                },
              );
            },
          ),
          const Divider(color: Colors.white24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'About',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            title: const Text(
              'Built by : alvoLabs',
              style: TextStyle(color: Colors.white),
            ),
            trailing: const Icon(Icons.code, color: Colors.white),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
