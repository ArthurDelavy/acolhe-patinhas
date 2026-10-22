import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
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

  String get nameValue => name; // "LOST", "FOUND", "ABANDONED"
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

  Future<AnimalReport> createReport({
    required String title,
    required String description,
    required ReportType type,
    required double latitude,
    required double longitude,
    File? imageFile,
  }) async {
    final token = await TokenStorage.getAuthToken();
    if (token == null || token.isEmpty) {
      throw Exception(
        'Você precisa estar autenticado para realizar um reporte.',
      );
    }

    final uri = Uri.parse('$baseUrl/report');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';

    // Campos do DTO NewReportRequest
    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['type'] = type.nameValue;
    request.fields['latitude'] = latitude.toStringAsFixed(6);
    request.fields['longitude'] = longitude.toStringAsFixed(6);

    // Imagem do animal (opcional)
    if (imageFile != null) {
      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      );
      request.files.add(multipartFile);
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
