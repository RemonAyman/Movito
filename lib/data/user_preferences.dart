import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserPreferences {
  static const String _keyName = "user_name";
  static const String _keyEmail = "user_email";
  static const String _keyAvatar = "user_avatar";

  static Future<void> saveUserData(
    String name,
    String email,
    String avatar,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyAvatar, avatar);
  }

  static Future<void> updateProfile({
    String? name,
    String? email,
    String? avatar,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null) await prefs.setString(_keyName, name);
    if (email != null) await prefs.setString(_keyEmail, email);
    if (avatar != null) await prefs.setString(_keyAvatar, avatar);
  }

  static Future<Map<String, String>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "name": prefs.getString(_keyName) ?? "",
      "email": prefs.getString(_keyEmail) ?? "",
      "avatar": prefs.getString(_keyAvatar) ?? "",
    };
  }

  static Future<void> refreshFromFirebase(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        await saveUserData(
          data['username'] ?? '',
          data['email'] ?? '',
          data['avatarBase64'] ?? '',
        );
      }
    } catch (e) {
      print("Error refreshing preferences: $e");
    }
  }

  static Future<void> clearData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<bool> isProfileComplete() async {
    final data = await getUserData();
    return data['name']!.isNotEmpty && data['email']!.isNotEmpty;
  }
}
