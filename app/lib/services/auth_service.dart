import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/token_storage.dart';

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

  // Mantivemos o register original
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 409) {
      throw Exception('E-mail já cadastrado');
    }
    throw Exception(
      'Erro ao cadastrar usuário. Código: ${response.statusCode}',
    );
  }

  // NOVO: Rota para validar o código de 6 dígitos
  Future<void> verifyCode({required String email, required String code}) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/auth/verify-email',
      ), // Ajuste para a rota real do seu backend
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Código inválido ou expirado');
    }
  }

  Future<void> resendCode({required String email}) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/auth/resend-verification', // CORRIGIDO AQUI!
      ), // Ajuste para a rota real do seu backend
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erro ao reenviar o código');
    }
  }

  // New methods for forgot password and reset password
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

    // 200 = senha alterada.
    // 403 = senha alterada, mas a conta não está verificada e não pode
    //       entrar ainda. Para o reset isso conta como sucesso; o login
    //       cuida da verificação depois.
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
}
