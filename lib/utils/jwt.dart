import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class JwtUtil {
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<String> getJwtToken() async {
    String? token = await _storage.read(key: 'jwtToken');
    return token ?? ''; // Return empty string if token is null
  }

  static Future<void> setJwtToken(String token) async {
    await _storage.write(key: 'jwtToken', value: token);
  }

  static Future<void> setUserId(String userId) async {
    await _storage.write(key: 'userId', value: userId);
  }
}
