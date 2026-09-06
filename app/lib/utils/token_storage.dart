import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _authKey = 'auth_token';
  static const _refreshKey = 'refresh_token';

  /// Salva o token de autenticação e o token de refresh
  static Future<void> saveTokens({
    required String authToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authKey, authToken);
    await prefs.setString(_refreshKey, refreshToken);
  }

  /// Retorna o token de autenticação salvo (ou null, se não houver)
  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authKey);
  }

  /// Retorna o refresh token salvo (ou null, se não houver)
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey);
  }

  /// Remove os dois tokens (usado no logout, por exemplo)
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authKey);
    await prefs.remove(_refreshKey);
  }

  /// Verifica se existe um token de autenticação salvo
  static Future<bool> hasToken() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }
}
