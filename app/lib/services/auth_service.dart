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

    if (response.statusCode == 401) {
      throw Exception('E-mail ou senha incorretos');
    }

    if (response.statusCode == 400) {
      throw Exception('Dados inválidos');
    }
    throw Exception('Erro ao realizar login. Código: ${response.statusCode}');
  }

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

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    if (response.statusCode == 409) {
      throw Exception('E-mail já cadastrado');
    }

    if (response.statusCode == 400) {
      throw Exception('Dados inválidos');
    }

    throw Exception(
      'Erro ao cadastrar usuário. Código: ${response.statusCode}',
    );
  }
}
