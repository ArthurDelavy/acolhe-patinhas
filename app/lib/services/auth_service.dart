import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl;

  AuthService({required this.baseUrl});

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
