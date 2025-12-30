import 'dart:convert';
import 'package:http/http.dart' as http;

class CategoryDto {
  final String name;
  final String slug;
  final String? description;

  CategoryDto({required this.name, required this.slug, this.description});

  factory CategoryDto.fromJson(Map<String, dynamic> json) => CategoryDto(
        name: (json["name"] ?? "").toString(),
        slug: (json["slug"] ?? "").toString(),
        description: json["description"]?.toString(),
      );
}

class ContentItemDto {
  final String title;
  final String slug;
  final String? excerpt;
  final String? publishedAt;

  ContentItemDto({
    required this.title,
    required this.slug,
    this.excerpt,
    this.publishedAt,
  });

  factory ContentItemDto.fromJson(Map<String, dynamic> json) => ContentItemDto(
        title: (json["title"] ?? "").toString(),
        slug: (json["slug"] ?? "").toString(),
        excerpt: json["excerpt"]?.toString(),
        publishedAt: json["published_at"]?.toString(),
      );
}

class ContentListDto {
  final CategoryDto category;
  final List<ContentItemDto> items;

  ContentListDto({required this.category, required this.items});

  factory ContentListDto.fromJson(Map<String, dynamic> json) => ContentListDto(
        category: CategoryDto.fromJson(json["category"] as Map<String, dynamic>),
        items: (json["items"] as List)
            .map((e) => ContentItemDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ContentDetailDto {
  final String title;
  final String slug;
  final String body;
  final String? publishedAt;

  ContentDetailDto({
    required this.title,
    required this.slug,
    required this.body,
    this.publishedAt,
  });

  factory ContentDetailDto.fromJson(Map<String, dynamic> json) => ContentDetailDto(
        title: (json["title"] ?? "").toString(),
        slug: (json["slug"] ?? "").toString(),
        body: (json["body"] ?? "").toString(),
        publishedAt: json["published_at"]?.toString(),
      );
}

class EducationApi {
  static const String baseUrl = "https://temanaman-backend.up.railway.app/";
  final http.Client _client;
  EducationApi({http.Client? client}) : _client = client ?? http.Client();

  Future<List<CategoryDto>> listCategories() async {
    final uri = Uri.parse("$baseUrl/education/categories");
    final res = await _client.get(uri);

    if (res.statusCode != 200) {
      throw Exception("GET /education/categories failed: ${res.statusCode} ${res.body}");
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (data["items"] as List).cast<Map<String, dynamic>>();
    return items.map(CategoryDto.fromJson).toList();
  }

  Future<ContentListDto> listContentsByCategorySlug(String slug) async {
    final uri = Uri.parse("$baseUrl/education/categories/$slug/contents");
    final res = await _client.get(uri);

    if (res.statusCode != 200) {
      throw Exception("GET /education/categories/$slug/contents failed: ${res.statusCode} ${res.body}");
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return ContentListDto.fromJson(data);
  }

  Future<ContentDetailDto> getContentDetail(String slug) async {
    final uri = Uri.parse("$baseUrl/education/contents/$slug");
    final res = await _client.get(uri);

    if (res.statusCode != 200) {
      throw Exception("GET /education/contents/$slug failed: ${res.statusCode} ${res.body}");
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return ContentDetailDto.fromJson(data);
  }
}
