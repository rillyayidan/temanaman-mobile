import 'dart:convert';
import 'package:http/http.dart' as http;

class PrivacyPageDto {
  final String code;
  final String title;
  final String body;
  final String updatedAt;

  PrivacyPageDto({
    required this.code,
    required this.title,
    required this.body,
    required this.updatedAt,
  });

  factory PrivacyPageDto.fromJson(Map<String, dynamic> json) {
    return PrivacyPageDto(
      code: (json["code"] ?? "").toString(),
      title: (json["title"] ?? "").toString(),
      body: (json["body"] ?? "").toString(),
      updatedAt: (json["updated_at"] ?? "").toString(),
    );
  }
}

class PrivacyApi {
  // Emulator Android Studio
  static const String baseUrl = "https://temanaman-backend.up.railway.app/";
  final http.Client _client;
  PrivacyApi({http.Client? client}) : _client = client ?? http.Client();

  Future<PrivacyPageDto> getPrivacy({String code = "privacy_policy"}) async {
    final uri = Uri.parse("$baseUrl/privacy")
        .replace(queryParameters: {"code": code});

    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception("GET /privacy failed: ${res.statusCode} ${res.body}");
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return PrivacyPageDto.fromJson(data);
  }
}
