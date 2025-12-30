import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TemanAmanApi {
  static const String baseUrl = "https://temanaman-backend.up.railway.app/";
  final http.Client _client;
  TemanAmanApi({http.Client? client}) : _client = client ?? http.Client();

  Future<String> createRoom({required String userId}) async {
    final uri = Uri.parse(
      "$baseUrl/chat/rooms",
    ).replace(queryParameters: {"user_id": userId});

    final res = await _client.post(uri);

    if (res.statusCode != 200) {
      throw Exception("createRoom failed: ${res.statusCode} ${res.body}");
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data["room_id"] as String;
  }

  Future<String> sendMessage({
    required String roomId,
    required String userId,
    required String message,
  }) async {
    final uri = Uri.parse("$baseUrl/chat/rooms/$roomId/messages");

    final res = await _client.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "message": message}),
    );

    if (res.statusCode != 200) {
      throw Exception("sendMessage failed: ${res.statusCode} ${res.body}");
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data["assistant_message"] as String;
  }

  Future<bool> endRoom({required String roomId, required String userId}) async {
    final uri = Uri.parse(
      "$baseUrl/chat/rooms/$roomId/end",
    ).replace(queryParameters: {"user_id": userId});

    final res = await _client.post(uri);

    if (res.statusCode != 200) {
      throw Exception("endRoom failed: ${res.statusCode} ${res.body}");
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data["deleted"] as bool;
  }

  Future<Map<String, dynamic>> getRoomState(String roomId) async {
    final uri = Uri.parse("$baseUrl/chat/rooms/$roomId");
    final res = await _client.get(uri);

    if (res.statusCode != 200) {
      throw Exception("getRoomState failed: ${res.statusCode} ${res.body}");
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Stream<String> sendMessageStream({
    required String roomId,
    required String userId,
    required String message,
  }) async* {
    final uri = Uri.parse("$baseUrl/chat/rooms/$roomId/messages/stream");

    final req = http.Request("POST", uri);
    req.headers["Content-Type"] = "application/json";
    req.body = jsonEncode({"user_id": userId, "message": message});

    final streamed = await _client.send(req);

    if (streamed.statusCode != 200) {
      final body = await streamed.stream.bytesToString();
      throw Exception("stream failed: ${streamed.statusCode} $body");
    }

    // SSE: event + data(JSON) blocks separated by blank line
    final decoder = streamed.stream.transform(utf8.decoder);

    String buffer = "";
    await for (final chunk in decoder) {
      buffer += chunk;

      // proses per event block
      while (true) {
        final sepIndex = buffer.indexOf("\n\n");
        if (sepIndex == -1) break;

        final block = buffer.substring(0, sepIndex);
        buffer = buffer.substring(sepIndex + 2);

        String? event;
        String? dataLine;

        for (final line in block.split("\n")) {
          if (line.startsWith("event: ")) {
            event = line.substring(7).trim();
          } else if (line.startsWith("data: ")) {
            dataLine = line.substring(6).trim();
          }
        }

        if (event == null) continue;

        if (event == "delta" && dataLine != null && dataLine.isNotEmpty) {
          final obj = jsonDecode(dataLine) as Map<String, dynamic>;
          final text = (obj["text"] ?? "").toString();
          if (text.isNotEmpty) yield text;
        } else if (event == "done") {
          return;
        } else if (event == "error") {
          String msg = "Stream error";
          if (dataLine != null && dataLine.isNotEmpty) {
            final obj = jsonDecode(dataLine) as Map<String, dynamic>;
            msg = (obj["message"] ?? msg).toString();
          }
          throw Exception(msg);
        }
      }
    }
  }
}
