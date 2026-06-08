import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  static final ValueNotifier<bool> saveGeolocation = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> showGridlines = ValueNotifier<bool>(true);
  static final ValueNotifier<int> resolutionPresetIndex = ValueNotifier<int>(4);

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load saved values, or default if missing
    saveGeolocation.value = prefs.getBool('saveGeolocation') ?? false;
    showGridlines.value = prefs.getBool('showGridlines') ?? true;
    resolutionPresetIndex.value = prefs.getInt('resolutionPresetIndex') ?? 4;

    // Attach listeners to automatically persist changes
    saveGeolocation.addListener(() {
      prefs.setBool('saveGeolocation', saveGeolocation.value);
    });
    showGridlines.addListener(() {
      prefs.setBool('showGridlines', showGridlines.value);
    });
    resolutionPresetIndex.addListener(() {
      prefs.setInt('resolutionPresetIndex', resolutionPresetIndex.value);
    });
  }
}
