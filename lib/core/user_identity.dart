import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class UserIdentity {
  static const _key = "teman_aman_user_id";
  static const _uuid = Uuid();

  static Future<String> getOrCreateUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);

    if (existing != null && existing.trim().isNotEmpty) {
      return existing;
    }

    // Prefix biar gampang dibaca di backend logs
    final newId = "u_${_uuid.v4()}";
    await prefs.setString(_key, newId);
    return newId;
  }

  static Future<void> resetUserIdForDebug() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
