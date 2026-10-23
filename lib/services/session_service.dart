import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  SessionService._();

  static const String _sessionKey = 'masticare_logged_in_user_id';

  static final SessionService instance = SessionService._();

  Future<void> saveSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionKey, userId);
  }

  Future<int?> getSessionUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_sessionKey);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
