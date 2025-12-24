import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class UserIdentity {
  static const _key = "user_key";
  static const _prefix = "u_";

  /// Ambil userKey permanen. Kalau belum ada, generate dan simpan.
  static Future<String> getUserKey() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null && existing.isNotEmpty) return existing;

    final id = const Uuid().v4(); // contoh: 13b23d34-be0d-46f9-8968-1b72476cc679
    final userKey = "$_prefix$id";

    await prefs.setString(_key, userKey);
    return userKey;
  }

  /// (Opsional) untuk debug/testing: reset identity
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
