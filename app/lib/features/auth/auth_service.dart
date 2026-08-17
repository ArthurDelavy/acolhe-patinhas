import 'dart:convert';
import 'package:http/http.dart' as http; //flutter pub add http terminal

class AuthService {
  static const String baseUrl =
      'http://10.0.2.2:8080/api/user'; //url para teste em android

  Future<bool> login(String name, String email, String password) async {
    //método de login
    final url = Uri.parse('$baseUrl/register'); //dispara um POST para a API
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    //retorna true = cod 200
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> loginAnonymous() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/anonymous'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
