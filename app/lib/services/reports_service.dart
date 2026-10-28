import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../utils/token_storage.dart';

enum ReportType { LOST, FOUND, ABANDONED }

extension ReportTypeExtension on ReportType {
  String get label {
    switch (this) {
      case ReportType.LOST:
        return 'Perdido';
      case ReportType.FOUND:
        return 'Encontrado';
      case ReportType.ABANDONED:
        return 'Abandonado / Em Risco';
    }
  }

  String get nameValue => name;
}

enum ReportStatus { OPEN, RESOLVED, CANCELLED }

class AnimalReport {
  final int? id;
  final String title;
  final String description;
  final ReportType type;
  final ReportStatus status;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  final String? userName;
  final String? userPhotoUrl;
  final DateTime? createdAt;

  const AnimalReport({
    this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    this.imageUrl,
    required this.latitude,
    required this.longitude,
    this.userName,
    this.userPhotoUrl,
    this.createdAt,
  });

  /// Busca o endereço completo (Rua, Bairro e Cidade) via OpenStreetMap Nominatim
  Future<String> fetchAddress() async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1',
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'AcolhePatinhasApp/1.0',
          'Accept-Language': 'pt-BR',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final address = data['address'];

        if (address != null && address is Map) {
          final road =
              address['road'] ??
              address['pedestrian'] ??
              address['suburb'] ??
              '';
          final neighbourhood =
              address['neighbourhood'] ?? address['suburb'] ?? '';
          final city =
              address['city'] ??
              address['town'] ??
              address['municipality'] ??
              '';

          List<String> parts = [];
          if (road.toString().isNotEmpty) parts.add(road.toString());
          if (neighbourhood.toString().isNotEmpty && neighbourhood != road)
            parts.add(neighbourhood.toString());
          if (city.toString().isNotEmpty) parts.add(city.toString());

          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }
      }
    } catch (_) {}

    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  factory AnimalReport.fromJson(Map<String, dynamic> json) {
    return AnimalReport(
      id: (json['id'] as num?)?.toInt(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: _parseType(json['type']),
      status: _parseStatus(json['status']),
      imageUrl: json['imageUrl'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      userName: json['userName'] as String?,
      userPhotoUrl: json['userPhotoUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  static ReportType _parseType(dynamic value) {
    if (value == 'FOUND') return ReportType.FOUND;
    if (value == 'ABANDONED') return ReportType.ABANDONED;
    return ReportType.LOST;
  }

  static ReportStatus _parseStatus(dynamic value) {
    if (value == 'RESOLVED') return ReportStatus.RESOLVED;
    if (value == 'CANCELLED') return ReportStatus.CANCELLED;
    return ReportStatus.OPEN;
  }
}

class ReportService {
  final String baseUrl = 'http://localhost:8080';

  Future<List<AnimalReport>> listAll() async {
    final token = await TokenStorage.getAuthToken();
    final uri = Uri.parse('$baseUrl/report');

    final headers = <String, String>{'Content-Type': 'application/json'};

    // Apenas adiciona se o token for válido e não-vazio
    if (token != null && token.trim().isNotEmpty && token != 'null') {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(
        utf8.decode(response.bodyBytes),
      );
      return jsonList.map((json) => AnimalReport.fromJson(json)).toList();
    }

    throw Exception(
      'Erro ao carregar reportes. Código: ${response.statusCode}',
    );
  }

  Future<AnimalReport> createReport({
    required String title,
    required String description,
    required ReportType type,
    required double latitude,
    required double longitude,
    XFile? imageFile,
  }) async {
    final token = await TokenStorage.getAuthToken();
    final uri = Uri.parse('$baseUrl/report');
    final request = http.MultipartRequest('POST', uri);

    // Se houver token, envia a autenticação do usuário logado
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['type'] = type.nameValue;
    request.fields['latitude'] = latitude.toStringAsFixed(6);
    request.fields['longitude'] = longitude.toStringAsFixed(6);

    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      if (bytes.isNotEmpty) {
        final multipartFile = http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: imageFile.name.isNotEmpty
              ? imageFile.name
              : 'report_pet.jpg',
        );
        request.files.add(multipartFile);
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return AnimalReport.fromJson(json);
    }

    if (response.statusCode == 400) {
      throw Exception(_validationMessage(response.bodyBytes));
    }

    throw Exception(
      'Erro ao cadastrar reporte. Código: ${response.statusCode}',
    );
  }

  String _validationMessage(List<int> bodyBytes) {
    try {
      final errors = jsonDecode(utf8.decode(bodyBytes))['errors'];
      if (errors is Map && errors.isNotEmpty) {
        return errors.entries.map((e) => '${e.key}: ${e.value}').join('\n');
      }
    } catch (_) {}
    return 'Verifique os dados preenchidos no formulário.';
  }
}
