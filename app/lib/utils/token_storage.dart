import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  // Mesma URL usada no AuthService / SplashScreen
  static const String _baseUrl = 'https://acolhe-patinhas.duckdns.org/api';

  static const _authKey = 'auth_token';
  static const _refreshKey = 'refresh_token';

  // Evita renovar duas vezes ao mesmo tempo
  static Future<String?>? _refreshing;

  static Future<void> saveAuthToken(String authToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authKey, authToken);
  }

  static Future<void> saveTokens({
    required String authToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authKey, authToken);
    await prefs.setString(_refreshKey, refreshToken);
  }

  /// Devolve SEMPRE um token válido: se o salvo estiver vencido, renova
  /// automaticamente antes de devolver. Retorna null se não há sessão.
  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_authKey);

    if (token == null || token.isEmpty) return null;
    if (!_isExpired(token)) return token;

    // Token vencido: tenta renovar
    final result = await _refreshOnce();

    if (result == null) return token; // sem internet: devolve o antigo
    if (result.isEmpty) {
      // servidor recusou: a sessão acabou
      await clear();
      return null;
    }
    return result; // token novo
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey);
  }

  /// Força uma renovação. true = renovou.
  static Future<bool> refresh() async {
    final result = await _refreshOnce();
    return result != null && result.isNotEmpty;
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

  static Future<bool> hasPermission(String permission) async {
    final token = await getAuthToken();
    if (token == null || token.isEmpty) return false;

    final payload = _decodeJwtPayload(token);
    if (payload == null) return false;

    if (payload.containsKey('exp')) {
      final exp = payload['exp'] as int;
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (currentTime >= exp) return false; // Token expirado
    }

    final rolesAndPermissions = payload['roles'];
    if (rolesAndPermissions is List) {
      return rolesAndPermissions.contains(permission);
    }

    return false;
  }

  // ---------------- renovação ----------------

  static Future<String?> _refreshOnce() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  // Retorna: token novo | '' (recusado pelo servidor) | null (erro de rede)
  static Future<String?> _doRefresh() async {
    try {
      final refreshToken = await getRefreshToken() ?? '';

      // Sem refresh token = sessão anônima: pega uma nova sessão anônima
      if (refreshToken.isEmpty) {
        final r = await http
            .post(
              Uri.parse('$_baseUrl/auth/anonymous'),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(const Duration(seconds: 15));

        if (r.statusCode == 200 || r.statusCode == 201) {
          final data = jsonDecode(r.body) as Map<String, dynamic>;
          final access = data['accessToken'] as String;
          await saveTokens(
            authToken: access,
            refreshToken: data['refreshToken'] as String? ?? '',
          );
          return access;
        }
        return r.statusCode >= 500 ? null : '';
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            // confirme com o backend se o campo é mesmo "code"
            body: jsonEncode({'code': refreshToken}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final access = (data['accessToken'] ?? data['authToken']) as String;
        await saveTokens(
          authToken: access,
          refreshToken: (data['refreshToken'] ?? refreshToken) as String,
        );
        return access;
      }

      return response.statusCode >= 500 ? null : '';
    } catch (_) {
      return null;
    }
  }

  static bool _isExpired(String token, {int leewaySeconds = 30}) {
    final payload = _decodeJwtPayload(token);
    if (payload == null) return true;
    final exp = payload['exp'];
    if (exp is! num) return false; // sem "exp": deixa o servidor decidir
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= exp.toInt() - leewaySeconds;
  }

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
