import 'dart:convert';
import 'package:http/http.dart' as http;

// --- SERVIÇO DE COMUNICAÇÃO COM A API ---
class PetService {
  static const String devToken = 'patinhasByUnivas';
  static const String baseUrl = 'http://localhost:8080';

  // Função auxiliar para garantir que o token 'patinhasByUnivas' seja usado se o token da tela vier vazio
  static String _getEffectiveToken(String? token) {
    if (token != null && token.trim().isNotEmpty) {
      return token.trim();
    }
    return devToken;
  }

  static Future<List<Map<String, dynamic>>> fetchBreeds([String? token]) async {
    final authToken = _getEffectiveToken(token);

    final response = await http.get(
      Uri.parse('$baseUrl/animal/reference/breed'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Falha ao carregar raças (${response.statusCode})');
  }

  static Future<List<Map<String, dynamic>>> fetchColors([String? token]) async {
    final authToken = _getEffectiveToken(token);

    final response = await http.get(
      Uri.parse('$baseUrl/animal/reference/color'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Falha ao carregar cores (${response.statusCode})');
  }

  static Future<bool> registerAnimal(
    Map<String, dynamic> payload, [
    String? token,
  ]) async {
    final authToken = _getEffectiveToken(token);

    final response = await http.post(
      Uri.parse('$baseUrl/animal'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(payload),
    );
    return response.statusCode == 201;
  }
}
