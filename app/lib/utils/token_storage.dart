import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _authKey = 'auth_token';
  static const _refreshKey = 'refresh_token';

  static Future<void> saveTokens({
    required String authToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authKey, authToken);
    await prefs.setString(_refreshKey, refreshToken);
  }

  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authKey);
    await prefs.remove(_refreshKey);
  }

  static Future<bool> hasToken() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }

  /// Verifica se o usuário possui determinada permissão dentro da claim 'roles'
  static Future<bool> hasPermission(String permission) async {
    final token = await getAuthToken();
    if (token == null || token.isEmpty) return false;

    final payload = _decodeJwtPayload(token);
    if (payload == null) return false;

    // Checa expiração do token (exp está em segundos)
    if (payload.containsKey('exp')) {
      final exp = payload['exp'] as int;
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (currentTime >= exp) return false; // Token expirado
    }

    // O backend Spring Boot salva as permissões na claim "roles"
    final rolesAndPermissions = payload['roles'];
    if (rolesAndPermissions is List) {
      return rolesAndPermissions.contains(permission);
    }

    return false;
  }

  /// Decodifica o payload (2ª parte) do JWT usando Base64
  static Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      String payload = parts[1];
      // Normaliza o padding do Base64
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }

      final String decodedString = utf8.decode(base64Url.decode(payload));
      return json.decode(decodedString) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
