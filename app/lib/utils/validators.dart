import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/token_storage.dart';

class Validators {
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  static bool isValidPassword(String password) {
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecialCharacter = RegExp(r'[@$!%*?&]').hasMatch(password);

    return password.length >= 8 &&
        hasLowercase &&
        hasUppercase &&
        hasNumber &&
        hasSpecialCharacter;
  }

  static bool isValidPetName(String name) {
    final trimmed = name.trim();
    return trimmed.isNotEmpty && trimmed.length <= 45;
  }

  static bool isValidMicrochip(String? microchip) {
    if (microchip == null || microchip.trim().isEmpty) {
      return true;
    }
    return microchip.trim().length <= 15;
  }

  static bool isValidSpecies(int? speciesId) {
    return speciesId != null;
  }

  static bool isValidBreed(int? breedId) {
    return breedId != null;
  }

  static bool isValidColor(int? colorId) {
    return colorId != null;
  }

  static bool isValidGender(String? gender) {
    return gender == 'M' || gender == 'F';
  }

  static bool isValidLength(String? value, int min, int max) {
    final length = (value ?? '').trim().length;
    return length >= min && length <= max;
  }

  static bool isValidCellPhone(String? phone) {
    final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    return RegExp(r'^[1-9]{2}9[0-9]{8}$').hasMatch(digits);
  }

  static double? parseNumber(String? value) =>
      double.tryParse((value ?? '').trim().replaceAll(',', '.'));

  static bool isValidCoordinate(String? value, double limit) {
    final number = parseNumber(value);
    return number != null && number >= -limit && number <= limit;
  }

  static bool isValidPositiveInt(String? value) {
    final number = int.tryParse((value ?? '').trim());
    return number != null && number > 0;
  }
}

class AppUserAgent {
  static String? _cachedUserAgent;

  static String getUserAgent() {
    if (_cachedUserAgent != null) return _cachedUserAgent!;

    String osInfo = 'UnknownPlatform';

    if (kIsWeb) {
      osInfo = 'WebBrowser';
    } else if (Platform.isAndroid) {
      osInfo = 'Android ${Platform.operatingSystemVersion}';
    } else if (Platform.isIOS) {
      osInfo = 'iOS ${Platform.operatingSystemVersion}';
    } else if (Platform.isMacOS) {
      osInfo = 'macOS ${Platform.operatingSystemVersion}';
    } else if (Platform.isWindows) {
      osInfo = 'Windows ${Platform.operatingSystemVersion}';
    } else if (Platform.isLinux) {
      osInfo = 'Linux ${Platform.operatingSystemVersion}';
    }

    _cachedUserAgent = 'AcolhePatinhasApp/1.0.0 ($osInfo)';
    return _cachedUserAgent!;
  }
}

class ApiClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  bool _isRefreshing = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers['User-Agent'] = AppUserAgent.getUserAgent();

    final token = await TokenStorage.getAuthToken();
    if (token != null && !request.headers.containsKey('Authorization')) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final copiedRequest = _copyRequest(request);
    var response = await _inner.send(request);

    if (response.statusCode == 401 && !request.url.path.contains('/auth/')) {
      if (!_isRefreshing) {
        _isRefreshing = true;
        final success = await _refreshTokenSilently();
        _isRefreshing = false;

        if (success) {
          final newToken = await TokenStorage.getAuthToken();
          copiedRequest.headers['Authorization'] = 'Bearer $newToken';

          return _inner.send(copiedRequest);
        }
      }
    }
    return response;
  }

  Future<bool> _refreshTokenSilently() async {
    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final refreshResponse = await _inner.post(
        Uri.parse('https://acolhe-patinhas.duckdns.org/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': refreshToken}),
      );

      if (refreshResponse.statusCode == 200) {
        final data = jsonDecode(refreshResponse.body);

        await TokenStorage.saveTokens(
          authToken: (data['accessToken'] ?? data['authToken']) as String,
          refreshToken: (data['refreshToken'] ?? refreshToken) as String,
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  http.BaseRequest _copyRequest(http.BaseRequest original) {
    if (original is http.Request) {
      final req = http.Request(original.method, original.url)
        ..encoding = original.encoding
        ..bodyBytes = original.bodyBytes;
      req.headers.addAll(original.headers);
      return req;
    } else if (original is http.MultipartRequest) {
      final req = http.MultipartRequest(original.method, original.url)
        ..fields.addAll(original.fields)
        ..files.addAll(original.files);
      req.headers.addAll(original.headers);
      return req;
    }
    return original;
  }
}
