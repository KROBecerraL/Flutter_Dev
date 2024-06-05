import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FlutterFutureStorage {
  static final _storage = FlutterSecureStorage();

  static Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  static Future<void> write({required String key, required String value}) async {
    return await _storage.write(key: key, value: value);
  }

  static Future<void> delete({required String key}) async {
    return await _storage.delete(key: key);
  }

  static Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }

  static Future<void> deleteAll() async {
    return await _storage.deleteAll();
  }
}
