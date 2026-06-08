import 'package:flutter/foundation.dart';

class SettingsState {
  static final ValueNotifier<bool> saveGeolocation = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> showGridlines = ValueNotifier<bool>(true);
}
