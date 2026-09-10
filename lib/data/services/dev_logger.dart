import 'package:shared_preferences/shared_preferences.dart';

class DevLogger {
  static Future<void> log(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dev_log_$key', value);
    } catch (_) {}
  }
}
