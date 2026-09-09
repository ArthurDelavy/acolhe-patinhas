import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../utils/token_storage.dart';

class PetService {
  static const String baseUrl = 'http://192.168.0.40:8080';

  static Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getAuthToken();
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static Future<dynamic> _get(String path) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Falha ao buscar $path (${response.statusCode})');
  }

  static Future<Map<String, dynamic>> fetchReferences() async {
    final data = await _get('/animal/reference');
    return data as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> fetchSpecies() async {
    final data = await _get('/animal/reference/specie');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> fetchBreeds() async {
    final data = await _get('/animal/reference/breed');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> fetchColors() async {
    final data = await _get('/animal/reference/color');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> fetchDischargeReasons() async {
    final data = await _get('/animal/reference/dischargeReason');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> fetchAnimals() async {
    final data = await _get('/animal');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<Map<String, dynamic>> fetchAnimalDetail(dynamic id) async {
    final data = await _get('/animal/$id');
    return data as Map<String, dynamic>;
  }

  static Future<bool> registerAnimal(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$baseUrl/animal'),
      headers: await _getHeaders(),
      body: jsonEncode(payload),
    );
    return response.statusCode == 201;
  }

  static Future<bool> uploadAnimalImage({
    required String animalId,
    required XFile imageFile,
  }) async {
    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse('$baseUrl/animal/$animalId/image'),
    );

    final token = await TokenStorage.getAuthToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

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
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/animal'),
      headers: await _getHeaders(),
      body: jsonEncode(payload),
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Falha ao cadastrar animal (${response.statusCode})'
        '${response.body.isNotEmpty ? ': ${response.body}' : ''}',
      );
    }

    if (imageFile == null) {
      return true;
    }

    final animals = await fetchAnimals();

    final matches = animals.where((a) {
      final matchesName =
          a['name']?.toString().trim().toLowerCase() ==
          payload['name']?.toString().trim().toLowerCase();
      final matchesGender =
          a['gender']?.toString() == payload['gender']?.toString();
      final matchesAdoption = a['toAdoption'] == payload['toAdoption'];
      final hasNoImage = a['imageUrl'] == null;
      return matchesName && matchesGender && matchesAdoption && hasNoImage;
    }).toList();

    if (matches.isEmpty) {
      throw Exception(
        'Animal criado, mas não foi possível localizá-lo na lista para envio da imagem.',
      );
    }

    matches.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
    final animalId = matches.last['id'].toString();

    return await uploadAnimalImage(animalId: animalId, imageFile: imageFile);
  }

  static Future<bool> updateAnimalWithImage({
    required dynamic id,
    required Map<String, dynamic> payload,
    XFile? imageFile,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/animal/$id'),
      headers: await _getHeaders(),
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Falha ao atualizar animal (${response.statusCode})'
        '${response.body.isNotEmpty ? ': ${response.body}' : ''}',
      );
    }

    if (imageFile != null) {
      await uploadAnimalImage(animalId: id.toString(), imageFile: imageFile);
    }

    return true;
  }

  static Future<void> dischargeAnimal({
    required int id,
    required int dischargeReasonId,
    required String dischargeDate,
    required int breedId,
    required int colorId,
    required Map<String, dynamic> existingPetData,
  }) async {
    final Map<String, dynamic> body = {
      "name": existingPetData['name'],
      "microchipNumber": existingPetData['microchipNumber'],
      "breedId": breedId,
      "colorId": colorId,
      "gender": existingPetData['gender'],
      "birthDate": existingPetData['birthDate'],
      "intakeDate": existingPetData['intakeDate'],
      "dischargeDate": dischargeDate,
      "dischargeReasonId": dischargeReasonId,
      "toAdoption": false,
    };

    final response = await http.patch(
      Uri.parse('$baseUrl/animal/$id'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        "Falha ao dar baixa no animal "
        "(${response.statusCode}): ${response.body}",
      );
    }
  }

  static Future<bool> deleteAnimal(dynamic id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/animal/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Falha ao excluir animal (${response.statusCode})'
        '${response.body.isNotEmpty ? ': ${response.body}' : ''}',
      );
    }

    return true;
  }

  static Future<Map<String, dynamic>> registerBreed({
    required String name,
    required int specieId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/animal/reference/breed'),
      headers: await _getHeaders(),
      body: jsonEncode({'name': name, 'specieId': specieId}),
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Falha ao cadastrar raça (${response.statusCode})'
        '${response.body.isNotEmpty ? ': ${response.body}' : ''}',
      );
    }

    final breeds = await fetchBreeds();
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
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/animal/reference/color'),
      headers: await _getHeaders(),
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Falha ao cadastrar cor (${response.statusCode})'
        '${response.body.isNotEmpty ? ': ${response.body}' : ''}',
      );
    }

    final colors = await fetchColors();
    return colors.firstWhere(
      (c) =>
          c['name'].toString().trim().toLowerCase() ==
          name.trim().toLowerCase(),
      orElse: () => throw Exception('Cor criada, mas não encontrada na lista.'),
    );
  }

  static Future<Map<String, dynamic>> registerSpecies({
    required String name,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/animal/reference/specie'),
      headers: await _getHeaders(),
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Falha ao cadastrar espécie (${response.statusCode})'
        '${response.body.isNotEmpty ? ': ${response.body}' : ''}',
      );
    }

    final species = await fetchSpecies();
    return species.firstWhere(
      (s) =>
          s['name'].toString().trim().toLowerCase() ==
          name.trim().toLowerCase(),
      orElse: () =>
          throw Exception('Espécie criada, mas não encontrada na lista.'),
    );
  }

  static Future<Map<String, dynamic>> registerDischargeReason({
    required String name,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/animal/reference/discharge-reason'),
      headers: await _getHeaders(),
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Falha ao cadastrar motivo de baixa (${response.statusCode})'
        '${response.body.isNotEmpty ? ': ${response.body}' : ''}',
      );
    }

    final reasons = await fetchDischargeReasons();
    return reasons.firstWhere(
      (r) =>
          r['name'].toString().trim().toLowerCase() ==
          name.trim().toLowerCase(),
      orElse: () =>
          throw Exception('Motivo criado, mas não encontrado na lista.'),
    );
  }
}
