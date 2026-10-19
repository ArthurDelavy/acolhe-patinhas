import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../utils/token_storage.dart';

class FosterHome {
  final int? id;
  final String name;
  final int? capacity;
  final String? ownerName;
  final String? ownerEmail;
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
    this.ownerEmail,
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
    ownerEmail: json['ownerEmail'] as String?,
    userName: json['userName'] as String?,
    phoneNumber: json['phoneNumber'] as String?,
    email: json['email'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
  );

  bool get hasLocation => latitude != null && longitude != null;

  String? get formattedPhone {
    final phone = phoneNumber;
    if (phone == null) return null;

    final d = phone.replaceAll(RegExp(r'\D'), '');
    if (d.length != 11) return phone;
    return '(${d.substring(0, 2)}) ${d.substring(2, 7)}-${d.substring(7)}';
  }
}

class FosterService {
  final String baseUrl = 'http://localhost:8080';

  static final Map<String, String> _geoCache = {};
  static Future<void> _geoQueue = Future.value();
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  FosterService();

  Future<List<FosterHome>> listFosterHomes() async {
    const action = 'listar lares temporários';
    final headers = await _authHeaders(action);

    final response = await http.get(
      Uri.parse('$baseUrl/foster-home').replace(
        queryParameters: {
          '_': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      ),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data
          .map((e) => FosterHome.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw _errorFor(response.statusCode, action);
  }

  Future<FosterHome> getFosterHome(int id) async {
    const action = 'carregar os dados do lar';
    final headers = await _authHeaders(action);

    final response = await http.get(
      Uri.parse('$baseUrl/foster-home/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return FosterHome.fromJson({...json, 'id': id});
    }

    throw _errorFor(response.statusCode, action);
  }

  Future<void> saveFosterHome({
    int? id,
    required String ownerEmail,
    required String name,
    required String phoneNumber,
    required String email,
    required double latitude,
    required double longitude,
    required int capacity,
  }) async {
    final action = id == null
        ? 'cadastrar lar temporário'
        : 'atualizar lar temporário';
    final headers = await _authHeaders(action);

    final uri = Uri.parse(
      id == null ? '$baseUrl/foster-home' : '$baseUrl/foster-home/$id',
    );

    final body = jsonEncode({
      'ownerEmail': ownerEmail,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      // o backend aceita no máximo 8 casas decimais
      'latitude': double.parse(latitude.toStringAsFixed(6)),
      'longitude': double.parse(longitude.toStringAsFixed(6)),
      'capacity': capacity,
    });

    final response = id == null
        ? await http.post(uri, headers: headers, body: body)
        : await http.patch(uri, headers: headers, body: body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      changes.value++;
      return;
    }

    if (response.statusCode == 400) {
      throw Exception(_validationMessage(response.bodyBytes));
    }

    throw _errorFor(response.statusCode, action);
  }

  Future<void> deleteFosterHome(int id) async {
    const action = 'excluir lar temporário';
    final headers = await _authHeaders(action);

    final response = await http.delete(
      Uri.parse('$baseUrl/foster-home/$id'),
      headers: headers,
    );

    if (response.statusCode == 204 || response.statusCode == 200) {
      changes.value++;
      return;
    }

    if (response.statusCode == 409) {
      throw Exception(
        'Não foi possível excluir. O lar pode estar em uso por outros registros.',
      );
    }

    throw _errorFor(response.statusCode, action);
  }

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

  /// "Cidade - Estado"
  Future<String> cityFromCoordinates(double lat, double lon) =>
      _reverse(lat, lon, 10, 'Localização indisponível', (a) {
        final city =
            a['city'] ??
            a['town'] ??
            a['village'] ??
            a['municipality'] ??
            a['county'];
        return [city, a['state']].whereType<String>().join(' - ');
      });

  Future<String> streetFromCoordinates(double lat, double lon) => _reverse(
    lat,
    lon,
    16,
    'Endereço indisponível',
    (a) {
      // Prioritizes the main street before considering other routes
      final road = a['road'] ?? a['pedestrian'] ?? a['street'] ?? a['highway'];
      final number = a['house_number'];
      final district =
          a['suburb'] ?? a['neighbourhood'] ?? a['quarter'] ?? a['residential'];

      if (road == null) return '';

      return [
        if (road is String) (number is String ? '$road, $number' : road),
        if (district is String) district,
      ].join(' - ');
    },
  );

  Future<String> _reverse(
    double lat,
    double lon,
    int zoom,
    String fallback,
    String Function(Map<String, dynamic> address) format,
  ) {
    final key = 'geo:$zoom:${lat.toStringAsFixed(5)},${lon.toStringAsFixed(5)}';
    final memory = _geoCache[key];
    if (memory != null) return Future.value(memory);

    final result = _geoQueue.then((_) async {
      final cached = _geoCache[key];
      if (cached != null) return cached;

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(key);
      if (saved != null) {
        _geoCache[key] = saved;
        return saved;
      }

      var label = fallback;
      try {
        final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
          'format': 'jsonv2',
          'lat': '$lat',
          'lon': '$lon',
          'zoom': '$zoom',
          'addressdetails': '1', // Ensures the complete address structure
          'accept-language': 'pt-BR',
        });

        final response = await http
            .get(uri, headers: {'User-Agent': 'AcolhePatinhasApp/1.0'})
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final json = jsonDecode(utf8.decode(response.bodyBytes));
          final address = (json['address'] ?? {}) as Map<String, dynamic>;
          final text = format(address);

          if (text.isNotEmpty) {
            label = text;
            _geoCache[key] = label;
            await prefs.setString(key, label);
          }
        }
      } catch (_) {}

      await Future.delayed(const Duration(milliseconds: 1100));
      return label;
    });

    _geoQueue = result.then((_) {}, onError: (_) {});
    return result;
  }

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
