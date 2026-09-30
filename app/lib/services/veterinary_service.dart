import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/veterinary_form_data.dart';
import '../utils/token_storage.dart';
import 'pet_service.dart';

/// Rotas veterinárias, conforme os controllers do backend.
class VetRoutes {
  // Catálogos (GET lista / POST cria)
  static const String vaccineCatalog = '/veterinary/vaccine';
  static const String surgeryCatalog = '/veterinary/surgeries/types';
  static const String preventiveCatalog = '/veterinary/preventive/types';
  static const String labTestCatalog = '/veterinary/lab-test/types';
  static const String diseaseCatalog = '/veterinary/disease';
  static const String medicines = '/veterinary/medicine';

  static String _withParam(String path, int animalId) =>
      '/animal/$animalId/$path?animalId=$animalId';

  static String vaccinations(int animalId) =>
      _withParam('vaccination', animalId);
  static String surgeries(int animalId) => _withParam('surgery', animalId);
  static String preventives(int animalId) => _withParam('preventive', animalId);
  static String labTests(int animalId) => _withParam('lab-test', animalId);
  static String diagnoses(int animalId) => _withParam('diagnosis', animalId);
  static String treatments(int animalId) => _withParam('treatment', animalId);

  // Registros veterinários individuais.
  static String vaccination(int id) => '/veterinary/vaccination/$id';
  static String surgery(int id) => '/veterinary/surgery/$id';
  static String preventive(int id) => '/veterinary/preventive/$id';
  static String labTest(int id) => '/veterinary/lab-test/$id';
  static String diagnosis(int id) => '/veterinary/diagnosis/$id';
  static String treatment(int id) => '/veterinary/treatment/$id';

  static const bool posologyEnabled = true;

  static String posology(int treatmentId) =>
      '/veterinary/treatment/$treatmentId/posology?treatmentId=$treatmentId';
}

class VeterinaryService {
  static Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getAuthToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static String _errorText(http.Response r) {
    try {
      final d = jsonDecode(r.body);
      if (d is Map) {
        final msg = d['message'] ?? d['detail'] ?? d['error'];
        final path = d['path'];
        if (msg != null) return '$msg${path != null ? ' [$path]' : ''}';
      }
    } catch (_) {}
    return r.body;
  }

  static Future<List<Map<String, dynamic>>> _getList(String path) async {
    final response = await http.get(
      Uri.parse('${PetService.baseUrl}$path'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao buscar $path (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return <Map<String, dynamic>>[];
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<Map<String, dynamic>> _getOne(String path) async {
    final response = await http.get(
      Uri.parse('${PetService.baseUrl}$path'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao buscar $path (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw Exception('Resposta inválida ao buscar $path');
    }
    return Map<String, dynamic>.from(decoded);
  }

  static Future<dynamic> _getAny(String path) async {
    final response = await http.get(
      Uri.parse('${PetService.baseUrl}$path'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao buscar $path (${response.statusCode})');
    }
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  static Future<http.Response> _post(
    String path,
    Map<String, dynamic> body,
    String label,
  ) async {
    final response = await http.post(
      Uri.parse('${PetService.baseUrl}$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 204) {
      throw Exception(
        'Falha ao cadastrar $label (${response.statusCode})'
        '${response.body.isNotEmpty ? ': ${_errorText(response)}' : ''}',
      );
    }
    return response;
  }

  static Future<void> _delete(String path, String label) async {
    final response = await http.delete(
      Uri.parse('${PetService.baseUrl}$path'),
      headers: await _headers(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Falha ao excluir $label (${response.statusCode})'
        '${response.body.isNotEmpty ? ': ${_errorText(response)}' : ''}',
      );
    }
  }

  static Future<Map<String, dynamic>> _createCatalogItem(
    String path,
    Map<String, dynamic> body,
    String label,
  ) async {
    final response = await _post(path, body, label);
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['id'] != null) {
        return decoded;
      }
    } catch (_) {}
    final items = await _getList(path);
    final name = body['name'].toString().trim().toLowerCase();
    return items.firstWhere(
      (i) => i['name'].toString().trim().toLowerCase() == name,
      orElse: () =>
          throw Exception('$label criado, mas não encontrado na lista.'),
    );
  }

  // -------------------------------------------------------------- catálogos
  static Future<List<Map<String, dynamic>>> fetchVaccines() =>
      _getList(VetRoutes.vaccineCatalog);
  static Future<List<Map<String, dynamic>>> fetchSurgicalProcedures() =>
      _getList(VetRoutes.surgeryCatalog);
  static Future<List<Map<String, dynamic>>> fetchPreventiveProcedures() =>
      _getList(VetRoutes.preventiveCatalog);
  static Future<List<Map<String, dynamic>>> fetchLabTests() =>
      _getList(VetRoutes.labTestCatalog);
  static Future<List<Map<String, dynamic>>> fetchDiseases() =>
      _getList(VetRoutes.diseaseCatalog);
  static Future<List<Map<String, dynamic>>> fetchMedicines() =>
      _getList(VetRoutes.medicines);

  static Future<Map<String, dynamic>> registerVaccine(String name) =>
      _createCatalogItem(VetRoutes.vaccineCatalog, {'name': name}, 'vacina');
  static Future<Map<String, dynamic>> registerSurgicalProcedure(String name) =>
      _createCatalogItem(VetRoutes.surgeryCatalog, {
        'name': name,
      }, 'procedimento cirúrgico');
  static Future<Map<String, dynamic>> registerPreventiveProcedure({
    required String name,
    required int defaultFrequencyDays,
  }) => _createCatalogItem(VetRoutes.preventiveCatalog, {
    'name': name,
    'defaultFrequencyDays': defaultFrequencyDays,
  }, 'procedimento preventivo');
  static Future<Map<String, dynamic>> registerLabTest(String name) =>
      _createCatalogItem(VetRoutes.labTestCatalog, {
        'name': name,
      }, 'tipo de exame');
  static Future<Map<String, dynamic>> registerDisease(String name) =>
      _createCatalogItem(VetRoutes.diseaseCatalog, {'name': name}, 'doença');
  static Future<Map<String, dynamic>> registerMedicine(String name) =>
      _createCatalogItem(VetRoutes.medicines, {'name': name}, 'medicamento');

  // ---------------------------------------------------------- registros animal
  static Future<List<Map<String, dynamic>>> fetchAnimalVaccinations(
    int animalId,
  ) => _getList(VetRoutes.vaccinations(animalId));
  static Future<List<Map<String, dynamic>>> fetchAnimalSurgeries(
    int animalId,
  ) => _getList(VetRoutes.surgeries(animalId));
  static Future<List<Map<String, dynamic>>> fetchAnimalPreventives(
    int animalId,
  ) => _getList(VetRoutes.preventives(animalId));
  static Future<List<Map<String, dynamic>>> fetchAnimalLabTests(int animalId) =>
      _getList(VetRoutes.labTests(animalId));
  static Future<List<Map<String, dynamic>>> fetchAnimalDiagnoses(
    int animalId,
  ) => _getList(VetRoutes.diagnoses(animalId));
  static Future<List<Map<String, dynamic>>> fetchAnimalTreatments(
    int animalId,
  ) => _getList(VetRoutes.treatments(animalId));

  // ---------------------------------------------------------- registros únicos
  static Future<Map<String, dynamic>> fetchVaccination(int id) =>
      _getOne(VetRoutes.vaccination(id));
  static Future<Map<String, dynamic>> fetchSurgery(int id) =>
      _getOne(VetRoutes.surgery(id));
  static Future<Map<String, dynamic>> fetchPreventive(int id) =>
      _getOne(VetRoutes.preventive(id));
  static Future<Map<String, dynamic>> fetchLabTest(int id) =>
      _getOne(VetRoutes.labTest(id));
  static Future<Map<String, dynamic>> fetchDiagnosis(int id) =>
      _getOne(VetRoutes.diagnosis(id));
  static Future<Map<String, dynamic>> fetchTreatment(int id) =>
      _getOne(VetRoutes.treatment(id));

  static Future<dynamic> fetchTreatmentPosology(int id) =>
      _getAny(VetRoutes.posology(id));

  // ---------------------------------------------------------- exclusões
  static Future<void> deleteVaccination(int id) =>
      _delete(VetRoutes.vaccination(id), 'vacinação');
  static Future<void> deleteSurgery(int id) =>
      _delete(VetRoutes.surgery(id), 'cirurgia');
  static Future<void> deleteLabTest(int id) =>
      _delete(VetRoutes.labTest(id), 'exame');
  static Future<void> deleteDiagnosis(int id) =>
      _delete(VetRoutes.diagnosis(id), 'diagnóstico');
  static Future<void> deleteTreatment(int id) =>
      _delete(VetRoutes.treatment(id), 'tratamento');

  // ---------------------------------------------------------- cadastro
  static Future<void> saveAll(int animalId, VeterinaryFormData data) async {
    await _flush(data.vaccinations, VetRoutes.vaccinations(animalId), 'vacina');
    await _flush(data.surgeries, VetRoutes.surgeries(animalId), 'cirurgia');
    await _flush(
      data.preventives,
      VetRoutes.preventives(animalId),
      'cuidado preventivo',
    );
    await _flush(data.labTests, VetRoutes.labTests(animalId), 'exame');
    await _saveDiagnoses(animalId, data);
    await _saveTreatments(animalId, data);
  }

  static Future<void> _flush(
    List<VetEntry> entries,
    String path,
    String label,
  ) async {
    while (entries.isNotEmpty) {
      await _post(path, entries.first.payload, label);
      entries.removeAt(0);
    }
  }

  static Future<void> _saveDiagnoses(
    int animalId,
    VeterinaryFormData data,
  ) async {
    while (data.diagnoses.isNotEmpty) {
      final entry = data.diagnoses.first;
      if (entry.meta['posted'] != true) {
        await _post(
          VetRoutes.diagnoses(animalId),
          entry.payload,
          'diagnóstico',
        );
        entry.meta['posted'] = true;
      }
      final localId = entry.meta['localId'] as int;
      final referenced = data.treatments.any(
        (t) => t.meta['diagnosisLocalId'] == localId,
      );
      if (referenced) {
        data.savedDiagnosisIds[localId] = await _findDiagnosisId(
          animalId,
          entry,
          data.savedDiagnosisIds.values.toSet(),
        );
      }
      data.diagnoses.removeAt(0);
    }
  }

  static Future<int> _findDiagnosisId(
    int animalId,
    VetEntry entry,
    Set<int> alreadyUsed,
  ) async {
    final list = await _getList(VetRoutes.diagnoses(animalId));
    final matches = list
        .where(
          (d) =>
              d['diseaseName'] == entry.meta['diseaseName'] &&
              d['status'] == entry.meta['status'] &&
              d['diagnosedAt']?.toString() == entry.meta['diagnosedAt'] &&
              !alreadyUsed.contains(d['id']),
        )
        .toList();
    if (matches.isEmpty) {
      throw Exception(
        'Diagnóstico salvo, mas não foi possível localizá-lo para ligar ao tratamento.',
      );
    }
    matches.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
    return matches.first['id'] as int;
  }

  static Future<void> _saveTreatments(
    int animalId,
    VeterinaryFormData data,
  ) async {
    while (data.treatments.isNotEmpty) {
      final entry = data.treatments.first;
      if (entry.meta['createdId'] == null) {
        final body = Map<String, dynamic>.from(entry.payload);
        final localDiagnosis = entry.meta['diagnosisLocalId'];
        if (localDiagnosis != null) {
          final realId = data.savedDiagnosisIds[localDiagnosis];
          if (realId == null)
            throw Exception(
              'O diagnóstico ligado ao tratamento não foi salvo.',
            );
          body['diagnosisId'] = realId;
        }
        final response = await _post(
          VetRoutes.treatments(animalId),
          body,
          'tratamento',
        );
        int? createdId;
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['id'] is int)
            createdId = decoded['id'] as int;
        } catch (_) {}
        if (createdId == null) {
          throw Exception(
            'Tratamento salvo, mas a resposta não trouxe o id (necessário para gravar os medicamentos).',
          );
        }
        entry.meta['createdId'] = createdId;
      }
      final treatmentId = entry.meta['createdId'] as int;
      final medicines = entry.meta['medicines'] as List<Map<String, dynamic>>;
      while (medicines.isNotEmpty) {
        await _post(VetRoutes.posology(treatmentId), {
          ...medicines.first,
          'treatmentId': treatmentId,
        }, 'medicamento do tratamento');
        medicines.removeAt(0);
      }
      data.treatments.removeAt(0);
    }
  }
}
