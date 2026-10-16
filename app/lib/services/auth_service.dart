import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart'; //new import for shared_preferences, which is used for storing tokens and other data locally

class AuthService {
  final String baseUrl;

  AuthService({required this.baseUrl});

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      await TokenStorage.saveTokens(
        authToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return data;
    }

    if (response.statusCode == 403 ||
        (response.statusCode == 401 &&
            response.body.contains('not verified'))) {
      throw Exception('CONTA_NAO_VERIFICADA');
    }

    if (response.statusCode == 401) {
      throw Exception('E-mail ou senha incorretos');
    }

    if (response.statusCode == 400) {
      throw Exception('Dados inválidos');
    }
    throw Exception('Erro ao realizar login. Código: ${response.statusCode}');
  }

  //anonymous login
  Future<Map<String, dynamic>> loginAnonymous() async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/anonymous'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      await TokenStorage.saveTokens(
        authToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String? ?? '',
      );

      return data;
    }

    throw Exception(
      'Erro ao entrar como anônimo. Código: ${response.statusCode}',
    );
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required bool acceptTerms,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'acceptTerms': acceptTerms,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      } else {
        return {};
      }
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(
        errorBody['message'] ??
            'Erro ao criar conta. Verifique os dados e tente novamente.',
      );
    }
  }

  Future<void> verifyCode({required String email, required String code}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Código inválido ou expirado');
    }
  }

  Future<void> resendCode({required String email}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/resend-verification'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erro ao reenviar o código');
    }
  }

  Future<void> forgotPassword({required String email}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Não foi possível enviar o código. Tente novamente.');
    }
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'passwordChangeToken': code,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 204 ||
        response.statusCode == 403) {
      return;
    }

    if (response.statusCode == 401 || response.statusCode == 404) {
      throw Exception('Código inválido ou expirado');
    }
    if (response.statusCode == 409) {
      throw Exception('A nova senha não pode ser igual à antiga');
    }
    if (response.statusCode == 400) {
      throw Exception(
        'Verifique os dados informados. A senha aceita apenas letras, números e @\$!%*?&',
      );
    }
    throw Exception(
      'Erro ao redefinir a senha. Código: ${response.statusCode}',
    );
  }

  Future<String> fetchTermContent() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Busca primeiro a URL atual do termo no backend
    final response = await http.get(Uri.parse('$baseUrl/term'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final String url = data['url'] ?? '';

      if (url.isNotEmpty) {
        final String cacheKey = 'cached_term_${url.hashCode}';
        final cachedContent = prefs.getString(cacheKey);

        if (cachedContent != null && cachedContent.isNotEmpty) {
          return cachedContent;
        }

        final fileResponse = await http.get(Uri.parse(url));
        if (fileResponse.statusCode == 200) {
          final decodedContent = utf8.decode(fileResponse.bodyBytes);

          await prefs.setString(cacheKey, decodedContent);

          return decodedContent;
        }
      }
    }

    throw Exception('Não foi possível carregar o termo de compromisso.');
  }

  Future<void> acceptTerms() async {
    final token = await TokenStorage.getAuthToken();

    final response = await http.post(
      Uri.parse('$baseUrl/term/accept'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erro ao aceitar os termos.');
    }
  }
}
