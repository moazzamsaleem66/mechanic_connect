import 'package:shared_preferences/shared_preferences.dart';

class AuthSessionStore {
  static const String _loggedInUsernameKey = 'logged_in_username';

  static Future<String?> getLoggedInUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_loggedInUsernameKey)?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  static Future<void> saveLoggedInUsername(String username) async {
    final normalized = username.trim();
    if (normalized.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loggedInUsernameKey, normalized);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInUsernameKey);
  }
}
