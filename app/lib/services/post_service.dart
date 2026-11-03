import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../utils/token_storage.dart';
import '../utils/validators.dart';

//publication template
class SocialPost {
  final int id;
  final int? userId;
  final String userName;
  final String? userPhotoUrl;
  final String description;
  final String? imageUrl;
  final DateTime createdAt;

  SocialPost({
    required this.id,
    this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.description,
    this.imageUrl,
    required this.createdAt,
  });

  //Converts the API JSON into a [SocialPost].
  factory SocialPost.fromJson(Map<String, dynamic> json) {
    return SocialPost(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      userName: json['userName'] as String? ?? 'Usuário',
      userPhotoUrl: json['userProfileImageUrl'] as String?,
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }
}

// Service that communicates with the posts API
class PostService {
  final String baseUrl = 'https://acolhe-patinhas.duckdns.org/api';
  final ApiClient _client = ApiClient();

  //Lists posts with pagination, from newest to oldest.
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
      final List<dynamic> jsonList = data['content'] ?? [];
      return jsonList.map((json) => SocialPost.fromJson(json)).toList();
    }
    return [];
  }

  // Creates a new post
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

  // Deletes a post by its ID
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

  // Updates a post by its ID
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
