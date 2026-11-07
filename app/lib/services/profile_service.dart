import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../utils/token_storage.dart';
import '../utils/validators.dart';

class UserProfile {
  final int id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final String role; //admin, verified, user
  final bool isVerified;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    required this.role,
    required this.isVerified,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final roleStr = (json['role'] ?? 'USER').toString().toUpperCase();
    return UserProfile(
      id: json['id'] ?? json['userId'] ?? 0,
      name: json['name'] ?? json['username'] ?? '',
      email: json['email'] ?? '',
      profileImageUrl:
          json['profileImageUrl'] ?? json['userPhotoUrl'] ?? json['photoUrl'],
      role: roleStr,
      isVerified:
          json['verified'] ?? (roleStr == 'VERIFIED' || roleStr == 'ADMIN'),
    );
  }
}

class ProfileService {
  final String baseUrl;
  final ApiClient _client = ApiClient();

  ProfileService({required this.baseUrl});

  Future<UserProfile> getProfile() async {
    final token = await TokenStorage.getAuthToken();

    final response = await _client.get(
      Uri.parse('$baseUrl/user/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(response.body));
    }

    if (response.statusCode == 422) {
      throw Exception('Acessos anônimos não possuem perfil.');
    }

    throw Exception('Erro ao carregar dados do perfil.');
  }

  Future<UserProfile> updateName(String newName) async {
    final token = await TokenStorage.getAuthToken();

    final response = await _client.patch(
      Uri.parse('$baseUrl/user/me/name'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': newName}),
    );

    if (response.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(response.body));
    }

    throw Exception('Erro ao atualizar o nome.');
  }

  Future<void> requestEmailChange(String newEmail) async {
    final token = await TokenStorage.getAuthToken();

    final response = await _client.post(
      Uri.parse('$baseUrl/user/me/email'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'newEmail': newEmail}),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['message'] ?? 'Erro ao solicitar troca de e-mail.',
      );
    }
  }

  Future<void> confirmEmailChange(String code) async {
    final token = await TokenStorage.getAuthToken();
    final currentRefreshToken = await TokenStorage.getRefreshToken();

    final response = await _client.post(
      Uri.parse('$baseUrl/user/me/email/confirm'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'code': code}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final newToken = data['token'] ?? data['accessToken'];
      final newRefreshToken = data['refreshToken'] ?? currentRefreshToken ?? '';

      if (newToken != null && newRefreshToken.isNotEmpty) {
        await TokenStorage.saveTokens(
          authToken: newToken,
          refreshToken: newRefreshToken,
        );
      }
    } else {
      throw Exception('Código de verificação inválido ou expirado.');
    }
  }

  Future<UserProfile> updateProfilePhoto(
    List<int> bytes,
    String filename,
  ) async {
    final token = await TokenStorage.getAuthToken();
    final uri = Uri.parse('$baseUrl/user/me/photo');

    final request = http.MultipartRequest('PATCH', uri);
    request.headers['User-Agent'] = AppUserAgent.getUserAgent();
    request.headers['Authorization'] = 'Bearer $token';

    final extension = filename.split('.').last.toLowerCase();
    String subType = 'jpeg';
    if (extension == 'png') subType = 'png';
    if (extension == 'webp') subType = 'webp';

    final multipartFile = http.MultipartFile.fromBytes(
      'image',
      bytes,
      filename: filename.isNotEmpty ? filename : 'profile_photo.$extension',
      contentType: MediaType('image', subType),
    );

    request.files.add(multipartFile);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(response.body));
    }

    throw Exception(
      'Erro ao atualizar a foto de perfil (Status ${response.statusCode}).',
    );
  }

  Future<UserProfile> getUserById(int userId) async {
    final token = await TokenStorage.getAuthToken();

    final response = await _client.get(
      Uri.parse('$baseUrl/user/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(response.body));
    }

    if (response.statusCode == 403) {
      throw Exception(
        'Sem permissão para visualizar o perfil deste utilizador.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception('Utilizador não encontrado.');
    }

    throw Exception('Erro ao carregar os dados do utilizador.');
  }

  Future<List<UserProfile>> listAllUsers() async {
    final token = await TokenStorage.getAuthToken();

    final response = await _client.get(
      Uri.parse('$baseUrl/user'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((json) => UserProfile.fromJson(json)).toList();
    }

    if (response.statusCode == 403) {
      throw Exception('Sem permissão para listar utilizadores.');
    }

    throw Exception('Erro ao listar os utilizadores.');
  }

  Future<bool> toggleUserVerification(int userId) async {
    final token = await TokenStorage.getAuthToken();

    final response = await _client.patch(
      Uri.parse('$baseUrl/user/$userId/toggle-verified'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return true;
    }

    if (response.statusCode == 403) {
      throw Exception('Sem permissão para verificar utilizadores.');
    }

    if (response.statusCode == 422) {
      throw Exception(
        'Administradores e acessos anónimos não podem ter o status de verificado alternado.',
      );
    }

    return false;
  }
}
