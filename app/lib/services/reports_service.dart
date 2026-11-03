import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../utils/token_storage.dart';
import '../utils/validators.dart';
import 'package:flutter/foundation.dart';

// report type
enum ReportType { LOST, FOUND, ABANDONED }

// label shown on the card
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

  //value to send to the API
  String get nameValue => name;
}

// Report status. Only OPEN appears in the public feed.
enum ReportStatus { OPEN, RESOLVED, CANCELLED }

// Template for an animal report.
class AnimalReport {
  final int? id;
  final int? userId;
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
    this.userId,
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

  //Converts latitude/longitude into a human-readable address
  Future<String> fetchAddress() async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1',
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': AppUserAgent.getUserAgent(),
          'Accept-Language': 'pt-BR', //portuguese preferred
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final address = data['address'];
        //filter street
        if (address != null && address is Map) {
          final road =
              address['road'] ??
              address['pedestrian'] ??
              address['suburb'] ??
              '';
          //filter neighborhood
          final neighbourhood =
              address['neighbourhood'] ?? address['suburb'] ?? '';
          //filter city
          final city =
              address['city'] ??
              address['town'] ??
              address['municipality'] ??
              '';

          //Assemble the text using only the parts that exist, without repetition.
          List<String> parts = [];
          if (road.toString().isNotEmpty) parts.add(road.toString());
          if (neighbourhood.toString().isNotEmpty && neighbourhood != road) {
            parts.add(neighbourhood.toString());
          }
          if (city.toString().isNotEmpty) parts.add(city.toString());

          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }
      }
    } catch (_) {}

    //four decimal places for latitude/longitude if no address is found
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  //Converts the API JSON into an [AnimalReport].
  factory AnimalReport.fromJson(Map<String, dynamic> json) {
    return AnimalReport(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      userName: json['userName'] as String?,
      userPhotoUrl: json['userProfileImgUrl'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: _parseType(json['type']),
      status: _parseStatus(json['status']),
      imageUrl: json['imageUrl'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.tryParse(
        json['createdAt']?.toString() ?? '',
      )?.toLocal(),
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

//Service that communicates with the API
class ReportService {
  final String baseUrl = 'https://acolhe-patinhas.duckdns.org/api';
  final ApiClient _client = ApiClient();

  //list all reports, including those that are not public (OPEN)
  Future<List<AnimalReport>> listAll() async {
    final token = await TokenStorage.getAuthToken();
    final uri = Uri.parse('$baseUrl/report');

    final headers = <String, String>{'Content-Type': 'application/json'};

    if (token != null && token.trim().isNotEmpty && token != 'null') {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _client.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(
        utf8.decode(response.bodyBytes),
      );
      debugPrint(
        const JsonEncoder.withIndent(
          '  ',
        ).convert(jsonList.isNotEmpty ? jsonList.first : {}),
      );
      return jsonList.map((json) => AnimalReport.fromJson(json)).toList();
    }

    throw Exception(
      'Erro ao carregar reportes. Código: ${response.statusCode}',
    );
  }

  // Creates a new report with the given data, including an optional image file.
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

    request.headers['User-Agent'] = AppUserAgent.getUserAgent();

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

  // Deletes a report by its ID.
  Future<void> deleteReport(int reportId) async {
    final token = await TokenStorage.getAuthToken();
    final uri = Uri.parse('$baseUrl/report/$reportId');

    final headers = <String, String>{'Content-Type': 'application/json'};

    if (token != null && token.trim().isNotEmpty && token != 'null') {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    final response = await _client.delete(uri, headers: headers);

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(
        'Erro ao deletar reporte (${response.statusCode}): ${response.body}',
      );
    }
  }

  // Updates the status of a report by its ID.
  Future<void> updateReportStatus({
    required int reportId,
    required String status,
  }) async {
    final token = await TokenStorage.getAuthToken();
    final uri = Uri.parse('$baseUrl/report/$reportId?reportId=$reportId');

    final headers = <String, String>{'Content-Type': 'application/json'};

    if (token != null && token.trim().isNotEmpty && token != 'null') {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    final body = jsonEncode({'status': status});

    final response = await _client.patch(uri, headers: headers, body: body);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Erro ao atualizar status (HTTP ${response.statusCode}): ${response.body}',
      );
    }
  }
}
