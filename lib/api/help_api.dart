import 'dart:convert';
import 'package:http/http.dart' as http;

class HelpContactDto {
  final int id;
  final String organizationName;
  final String contactType;
  final String contactValue;
  final String? region;
  final String? description;
  final String? availability;

  HelpContactDto({
    required this.id,
    required this.organizationName,
    required this.contactType,
    required this.contactValue,
    this.region,
    this.description,
    this.availability,
  });

  factory HelpContactDto.fromJson(Map<String, dynamic> json) {
    return HelpContactDto(
      id: (json["id"] as num).toInt(),
      organizationName: (json["organization_name"] ?? "").toString(),
      contactType: (json["contact_type"] ?? "").toString(),
      contactValue: (json["contact_value"] ?? "").toString(),
      region: json["region"]?.toString(),
      description: json["description"]?.toString(),
      availability: json["availability"]?.toString(),
    );
  }
}

class HelpApi {
  static const String baseUrl = "https://temanaman-backend.up.railway.app/";
  final http.Client _client;
  HelpApi({http.Client? client}) : _client = client ?? http.Client();

  Future<List<HelpContactDto>> listHelp({String? region}) async {
    final uri = Uri.parse("$baseUrl/help")
        .replace(queryParameters: region == null ? null : {"region": region});

    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception("GET /help failed: ${res.statusCode} ${res.body}");
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (data["items"] as List).cast<Map<String, dynamic>>();
    return items.map(HelpContactDto.fromJson).toList();
  }
}
