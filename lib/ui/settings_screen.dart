import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Mock states for settings
  bool _saveGeolocation = false;
  bool _showGridlines = true;

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
          SwitchListTile(
            title: const Text(
              'Save Geolocation',
              style: TextStyle(color: Colors.white),
            ),
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.grey.shade700,
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.shade900,
            value: _saveGeolocation,
            onChanged: (bool value) {
              setState(() {
                _saveGeolocation = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text(
              'Show Gridlines',
              style: TextStyle(color: Colors.white),
            ),
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.grey.shade700,
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.shade900,
            value: _showGridlines,
            onChanged: (bool value) {
              setState(() {
                _showGridlines = value;
              });
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
            trailing: const Icon(Icons.code, color: Colors.white), // Standard Material Icon as placeholder for GitHub
            onTap: () {
              // Open GitHub link functionality here
            },
          ),
        ],
      ),
    );
  }
}
