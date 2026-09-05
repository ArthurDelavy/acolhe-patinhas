import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class PetService {
  // Cole o seu JWT válido aqui enquanto estiver em ambiente dev
  static const String devToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJhY29saGVQYXRpbmhhcyIsInN1YiI6IkZlcm5hbmRhQGdtYWlsLmNvbSIsInJvbGVzIjpbImFuaW1hbDplZGl0IiwiYW5pbWFsUmVmZXJlbmNlOm1hbmFnZSIsImFuaW1hbDpyZWFkIiwiYW5pbWFsOnJlbW92ZSIsImFuaW1hbDpjcmVhdGUiLCJST0xFX0FETUlOIl0sImV4cCI6MTc4ODYzOTQyNX0.HmNKYrGg2YOSylK0j2Xr6482nHgWRVMyE2cXh4oKYSE';
  static const String baseUrl = 'http://localhost:8080';

  /// Garante a recuperação de um token válido (fallback para o devToken)
  static String _getEffectiveToken(String? token) {
    // Se for nulo ou se for apenas espaços/string vazia "", usa o devToken
    if (token == null || token.trim().isEmpty) {
      return devToken;
    }
    return token.trim();
  }

  /// Gera o mapa de headers HTTP padrão
  static Map<String, String> _getHeaders(String? token) {
    final authToken = _getEffectiveToken(token);
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authToken',
    };
  }

  /// Realiza requisições GET padrão e já devolve a resposta decodificada
  static Future<dynamic> _get(String path, [String? token]) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Falha ao buscar $path (${response.statusCode})');
  }

  static Future<Map<String, dynamic>> fetchReferences([String? token]) async {
    final data = await _get('/animal/reference', token);
    return data as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> fetchSpecies([
    String? token,
  ]) async {
    final data = await _get('/animal/reference/specie', token);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> fetchBreeds([String? token]) async {
    final data = await _get('/animal/reference/breed', token);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> fetchColors([String? token]) async {
    final data = await _get('/animal/reference/color', token);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<bool> registerAnimal(
    Map<String, dynamic> payload, [
    String? token,
  ]) async {
    final response = await http.post(
      Uri.parse('$baseUrl/animal'),
      headers: _getHeaders(token),
      body: jsonEncode(payload),
    );
    return response.statusCode == 201;
  }

  static Future<bool> uploadAnimalImage({
    required String animalId,
    required XFile imageFile,
    String? token,
  }) async {
    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse('$baseUrl/animal/$animalId/image'),
    );

    request.headers['Authorization'] = 'Bearer ${_getEffectiveToken(token)}';

    final bytes = await imageFile.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes('image', bytes, filename: imageFile.name),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Falha ao enviar imagem do animal (${response.statusCode})'
        '${response.body.isNotEmpty ? ': ${response.body}' : ''}',
      );
    }

    return true;
  }

  static Future<bool> registerAnimalWithImage({
    required Map<String, dynamic> payload,
    XFile? imageFile,
    String? token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/animal'),
      headers: _getHeaders(token),
      body: jsonEncode(payload),
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Falha ao cadastrar animal (${response.statusCode})'
        '${response.body.isNotEmpty ? ': ${response.body}' : ''}',
      );
    }

    if (imageFile == null) return true;

    // Tenta extrair o ID do header 'Location' ou do corpo da resposta
    String? animalId = response.headers['location']?.split('/').last;

    if ((animalId == null || animalId.isEmpty) && response.body.isNotEmpty) {
      try {
        final body = jsonDecode(response.body);
        animalId = body['id']?.toString();
      } catch (_) {}
    }

    if (animalId == null || animalId.isEmpty) {
      throw Exception(
        'Animal criado, mas ID não foi retornado para envio de imagem.',
      );
    }

    return await uploadAnimalImage(
      animalId: animalId,
      imageFile: imageFile,
      token: token,
    );
  }

  static Future<Map<String, dynamic>> registerBreed({
    required String name,
    required int specieId,
    String? token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/animal/reference/breed'),
      headers: _getHeaders(token),
      body: jsonEncode({'name': name, 'specieId': specieId}),
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Falha ao cadastrar raça (${response.statusCode})'
        '${response.body.isNotEmpty ? ': ${response.body}' : ''}',
      );
    }

    final breeds = await fetchBreeds(token);
    return breeds.firstWhere(
      (b) =>
          b['name'].toString().trim().toLowerCase() ==
          name.trim().toLowerCase(),
      orElse: () =>
          throw Exception('Raça criada, mas não encontrada na lista.'),
    );
  }

  static Future<Map<String, dynamic>> registerColor({
    required String name,
    String? token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/animal/reference/color'),
      headers: _getHeaders(token),
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Falha ao cadastrar cor (${response.statusCode})'
        '${response.body.isNotEmpty ? ': ${response.body}' : ''}',
      );
    }

    final colors = await fetchColors(token);
    return colors.firstWhere(
      (c) =>
          c['name'].toString().trim().toLowerCase() ==
          name.trim().toLowerCase(),
      orElse: () => throw Exception('Cor criada, mas não encontrada na lista.'),
    );
  }
}
