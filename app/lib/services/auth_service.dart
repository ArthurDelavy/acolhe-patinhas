import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl;

  AuthService({required this.baseUrl});

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    print('========== LOGIN ==========');
    print('AuthService: iniciou login');
    print('Base URL: $baseUrl');
    print('Email: $email');
    print('Enviando requisição para: $baseUrl/auth/login');

    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    print('AuthService: resposta recebida');
    print('Status Code: ${response.statusCode}');
    print('Resposta: ${response.body}');

    if (response.statusCode == 200) {
      print('LOGIN REALIZADO COM SUCESSO!');
      print('===========================');

      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    if (response.statusCode == 401) {
      print('LOGIN NEGADO: email ou senha incorretos');
      print('===========================');

      throw Exception('E-mail ou senha incorretos');
    }

    if (response.statusCode == 400) {
      print('LOGIN NEGADO: dados inválidos');
      print('===========================');

      throw Exception('Dados inválidos');
    }

    print('ERRO INESPERADO NO LOGIN');
    print('Status: ${response.statusCode}');
    print('===========================');

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
