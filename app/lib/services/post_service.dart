import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../utils/token_storage.dart';
import '../utils/validators.dart';

class SocialPost {
  final int id;
  final int? userId;
  final String userName;
  final String description;
  final String? imageUrl;
  final DateTime createdAt;

  SocialPost({
    required this.id,
    this.userId,
    required this.userName,
    required this.description,
    this.imageUrl,
    required this.createdAt,
  });

  factory SocialPost.fromJson(Map<String, dynamic> json) {
    String extractedUserName = 'Usuário';
    if (json['user'] != null && json['user']['name'] != null) {
      extractedUserName = json['user']['name'];
    } else if (json['userName'] != null) {
      extractedUserName = json['userName'];
    }

    int? extractedUserId;
    if (json['userId'] != null) {
      extractedUserId = (json['userId'] as num).toInt();
    } else if (json['user'] != null && json['user']['id'] != null) {
      extractedUserId = (json['user']['id'] as num).toInt();
    }

    return SocialPost(
      id: (json['id'] as num).toInt(),
      userId: extractedUserId,
      userName: extractedUserName,
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] as String? ?? json['image'] as String?,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

class PostService {
  final String baseUrl = 'https://acolhe-patinhas.duckdns.org/api';
  final ApiClient _client = ApiClient();

  Future<List<SocialPost>> listAll({int page = 0, int size = 20}) async {
    final token = await TokenStorage.getAuthToken();
    final uri = Uri.parse('$baseUrl/post?order=desc&page=$page&size=$size');

    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.trim().isNotEmpty && token != 'null') {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _client.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic> jsonList = data is List
          ? data
          : (data['content'] ?? data['items'] ?? []);
      return jsonList.map((json) => SocialPost.fromJson(json)).toList();
    }
    return [];
  }

  Future<SocialPost> createPost({
    required String description,
    XFile? imageFile,
  }) async {
    final token = await TokenStorage.getAuthToken();
    final uri = Uri.parse('$baseUrl/post');
    final request = http.MultipartRequest('POST', uri);

    request.headers['User-Agent'] = AppUserAgent.getUserAgent();

    if (token != null && token.trim().isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['description'] = description;

    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      if (bytes.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: imageFile.name.isNotEmpty
                ? imageFile.name
                : 'post_image.jpg',
          ),
        );
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return SocialPost.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw Exception('Erro ao publicar. Código: ${response.statusCode}');
  }

  Future<void> deletePost(int postId) async {
    final token = await TokenStorage.getAuthToken();
    final uri = Uri.parse('$baseUrl/post/$postId');

    final headers = <String, String>{};
    if (token != null && token.trim().isNotEmpty && token != 'null') {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _client.delete(uri, headers: headers);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erro ao excluir post. Status: ${response.statusCode}');
    }
  }

  Future<SocialPost> updatePost({
    required int postId,
    required String description,
    XFile? imageFile,
  }) async {
    final token = await TokenStorage.getAuthToken();
    final uri = Uri.parse('$baseUrl/post/$postId');
    final request = http.MultipartRequest('PATCH', uri);

    request.headers['User-Agent'] = AppUserAgent.getUserAgent();

    if (token != null && token.trim().isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.fields['description'] = description;

    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      if (bytes.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: imageFile.name.isNotEmpty
                ? imageFile.name
                : 'post_image.jpg',
          ),
        );
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return SocialPost.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw Exception('Erro ao atualizar post. Status: ${response.statusCode}');
  }
}
