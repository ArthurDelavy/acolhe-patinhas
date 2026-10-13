import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/token_storage.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------
class FosterHome {
  final int? id;
  final String name;
  final int? capacity;
  final String? ownerName;
  final String? userName;
  final String? phoneNumber;
  final String? email;
  final double? latitude;
  final double? longitude;

  const FosterHome({
    this.id,
    required this.name,
    this.capacity,
    this.ownerName,
    this.userName,
    this.phoneNumber,
    this.email,
    this.latitude,
    this.longitude,
  });

  factory FosterHome.fromJson(Map<String, dynamic> json) => FosterHome(
    id: (json['id'] as num?)?.toInt(),
    name: (json['name'] ?? '') as String,
    capacity: (json['capacity'] as num?)?.toInt(),
    ownerName: json['ownerName'] as String?,
    userName: json['userName'] as String?,
    phoneNumber: json['phoneNumber'] as String?,
    email: json['email'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
  );

  bool get hasLocation => latitude != null && longitude != null;
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------
class FosterService {
  final String baseUrl = 'http://localhost:8080';

  static final Map<int, FosterHome> _detailsCache = {};
  static final Map<String, String> _cityCache = {};
  static Future<void> _cityQueue = Future.value();

  FosterService();

  // ---------- API ----------

  Future<List<FosterHome>> listFosterHomes() async {
    const action = 'listar lares temporários';
    final headers = await _authHeaders(action);

    final response = await http.get(
      Uri.parse('$baseUrl/foster-home'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      _detailsCache.clear(); // lista nova = detalhes novos
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data
          .map((e) => FosterHome.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw _errorFor(response.statusCode, action);
  }

  /// Dados completos de um lar (telefone, e-mail, responsável, coordenadas).
  Future<FosterHome> getFosterHome(int id) async {
    final cached = _detailsCache[id];
    if (cached != null) return cached;

    const action = 'carregar os dados do lar';
    final headers = await _authHeaders(action);

    final response = await http.get(
      Uri.parse('$baseUrl/foster-home/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return _detailsCache[id] = FosterHome.fromJson({...json, 'id': id});
    }

    throw _errorFor(response.statusCode, action);
  }

  Future<Map<String, dynamic>> createFosterHome({
    required String ownerEmail,
    required String name,
    required String phoneNumber,
    required String email,
    required double latitude,
    required double longitude,
    required int capacity,
  }) async {
    const action = 'cadastrar lar temporário';
    final headers = await _authHeaders(action);

    final response = await http.post(
      Uri.parse('$baseUrl/foster-home'),
      headers: headers,
      body: jsonEncode({
        'ownerEmail': ownerEmail,
        'name': name,
        'phoneNumber': phoneNumber,
        'email': email,
        // o backend aceita no máximo 8 casas decimais
        'latitude': double.parse(latitude.toStringAsFixed(6)),
        'longitude': double.parse(longitude.toStringAsFixed(6)),
        'capacity': capacity,
      }),
    );

    if (response.statusCode == 201) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    if (response.statusCode == 400) {
      throw Exception(_validationMessage(response.bodyBytes));
    }

    throw _errorFor(response.statusCode, action);
  }

  // ---------- Localização ----------

  /// Posição atual do dispositivo.
  Future<Position> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Ative a localização do dispositivo.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Permissão de localização negada.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// Converte latitude/longitude em "Cidade - Estado" (OpenStreetMap/Nominatim).
  /// Cache em memória + disco: cada lar só é consultado uma vez na vida do app.
  /// A espera de 1,1 s (limite do Nominatim) só acontece quando há requisição.
  Future<String> cityFromCoordinates(double lat, double lon) {
    final key = '${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}';
    final memory = _cityCache[key];
    if (memory != null) return Future.value(memory);

    final result = _cityQueue.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('city:$key');
      if (saved != null) {
        _cityCache[key] = saved;
        return saved; // sem requisição e sem espera
      }

      var label = 'Localização indisponível';
      try {
        final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
          'format': 'jsonv2',
          'lat': '$lat',
          'lon': '$lon',
          'zoom': '10',
          'accept-language': 'pt-BR',
        });

        final response = await http
            .get(uri, headers: {'User-Agent': 'AcolhePatinhasApp/1.0'})
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final json = jsonDecode(utf8.decode(response.bodyBytes));
          final address = (json['address'] ?? {}) as Map<String, dynamic>;

          final city =
              address['city'] ??
              address['town'] ??
              address['village'] ??
              address['municipality'] ??
              address['county'];

          final parts = [city, address['state']].whereType<String>().toList();
          if (parts.isNotEmpty) {
            label = parts.join(' - ');
            _cityCache[key] = label;
            await prefs.setString('city:$key', label); // só guarda sucesso
          }
        }
      } catch (_) {}

      await Future.delayed(const Duration(milliseconds: 1100));
      return label;
    });

    _cityQueue = result.then((_) {}, onError: (_) {});
    return result;
  }

  // ---------- Helpers ----------

  Future<Map<String, String>> _authHeaders(String action) async {
    final token = await TokenStorage.getAuthToken();

    if (token == null || token.isEmpty) {
      throw Exception('Você precisa estar autenticado para $action.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  String _validationMessage(List<int> bodyBytes) {
    try {
      final errors = jsonDecode(utf8.decode(bodyBytes))['errors'];
      if (errors is Map && errors.isNotEmpty) {
        return errors.entries.map((e) => '${e.key}: ${e.value}').join('\n');
      }
    } catch (_) {}

    return 'Dados inválidos. Confira os campos preenchidos.';
  }

  Exception _errorFor(int status, String action) {
    switch (status) {
      case 400:
        return Exception('Dados inválidos. Confira os campos preenchidos.');
      case 401:
        return Exception('Sua sessão expirou. Entre novamente.');
      case 403:
        return Exception('Você não tem permissão para $action.');
      case 404:
        return Exception('Lar ou usuário não encontrado.');
      case 409:
        return Exception('Este lar temporário já está cadastrado.');
      default:
        return Exception('Erro ao $action. Código: $status');
    }
  }
}
