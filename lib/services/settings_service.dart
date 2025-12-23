import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _autoFocusKey = 'auto_focus';
  static const _vibrateKey = 'vibrate_on_scan';
  static const _beepKey = 'beep_on_scan';
  static const _autoCopyKey = 'auto_copy';
  static const _saveHistoryKey = 'save_history';
  static const _defaultCameraKey = 'default_camera';
  static const _flashlightModeKey = 'flashlight_mode';

  static Future<Map<String, bool>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'autoFocus': prefs.getBool(_autoFocusKey) ?? true,
      'vibrate': prefs.getBool(_vibrateKey) ?? true,
      'beep': prefs.getBool(_beepKey) ?? false,
      'autoCopy': prefs.getBool(_autoCopyKey) ?? true,
      'saveHistory': prefs.getBool(_saveHistoryKey) ?? true,
    };
  }

  static Future<Map<String, String>> loadCameraSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'defaultCamera': prefs.getString(_defaultCameraKey) ?? 'Rear',
      'flashlightMode': prefs.getString(_flashlightModeKey) ?? 'Manual',
    };
  }

  static Future<void> saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    switch (key) {
      case 'autoFocus':
        await prefs.setBool(_autoFocusKey, value);
        break;
      case 'vibrate':
        await prefs.setBool(_vibrateKey, value);
        break;
      case 'beep':
        await prefs.setBool(_beepKey, value);
        break;
      case 'autoCopy':
        await prefs.setBool(_autoCopyKey, value);
        break;
      case 'saveHistory':
        await prefs.setBool(_saveHistoryKey, value);
        break;
    }
  }

  static Future<void> saveCameraSetting(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    switch (key) {
      case 'defaultCamera':
        await prefs.setString(_defaultCameraKey, value);
        break;
      case 'flashlightMode':
        await prefs.setString(_flashlightModeKey, value);
        break;
    }
  }
}
