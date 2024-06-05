import 'package:shared_preferences/shared_preferences.dart';

class MySharedPreferences {
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<void> saveSecret(String secret) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('secret', secret);
  }

  static Future<String?> getSecret() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('secret');
  }

  static Future<void> clearSecret() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('secret');
  }
}
