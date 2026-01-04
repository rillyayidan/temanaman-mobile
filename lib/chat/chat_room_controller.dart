import 'dart:async';
import 'package:flutter/foundation.dart';

import '../api/teman_aman_api.dart';
import 'chat_message.dart';

class ChatRoomController extends ChangeNotifier {
  final TemanAmanApi api;
  final String userId;

  String? _roomId;
  bool _loading = false;
  bool _ended = false;

  final List<ChatMessage> _messages = [];

  StreamSubscription<String>? _streamSub;
  ChatMessage? _activeAssistantMsg; // bubble yang sedang di-stream

  ChatRoomController({required this.api, required this.userId});

  String? get roomId => _roomId;
  bool get loading => _loading;
  bool get ended => _ended;
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  Future<void> initRoom() async {
    if (_roomId != null) return;
    _loading = true;
    notifyListeners();
    try {
      final rid = await api.createRoom(userId: userId);
      _roomId = rid;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> cancelStreaming({bool keepPartialText = true}) async {
    await _streamSub?.cancel();
    _streamSub = null;

    // Kalau user cancel dan placeholder assistant masih kosong, kasih teks default biar nggak blank
    if (!keepPartialText && _activeAssistantMsg != null) {
      _activeAssistantMsg!.content = "";
    }
    _activeAssistantMsg = null;

    _loading = false;
    notifyListeners();
  }

  Future<void> sendStream(String text) async {
    final rid = _roomId;
    if (rid == null || _ended) return;

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // 1) Kalau masih streaming sebelumnya, CANCEL dulu
    if (_streamSub != null) {
      await cancelStreaming(keepPartialText: true);
      // Optional: tandai bubble terakhir bahwa dia di-interrupt
      // (kalau kamu mau, aku bisa tambahin flag; untuk sekarang cukup cancel saja)
    }

    // 2) Tambah user message
    _messages.add(ChatMessage(role: Role.user, content: trimmed));

    // 3) Tambah placeholder assistant bubble yang akan di-update
    final assistantMsg = ChatMessage(role: Role.assistant, content: "");
    _messages.add(assistantMsg);
    _activeAssistantMsg = assistantMsg;

    _loading = true;
    notifyListeners();

    try {
      final stream = api.sendMessageStream(
        roomId: rid,
        userId: userId,
        message: trimmed,
      );

      _streamSub = stream.listen(
        (chunk) {
          // Update bubble sedikit-sedikit
          assistantMsg.content += chunk;
          notifyListeners();
        },
        onError: (err) {
          if (assistantMsg.content.isEmpty) {
            assistantMsg.content = "Maaf, koneksi sedang bermasalah. Coba kirim lagi ya.";
          }
          _loading = false;
          _streamSub = null;
          _activeAssistantMsg = null;
          notifyListeners();
        },
        onDone: () {
          // Selesai stream
          if (assistantMsg.content.trim().isEmpty) {
            assistantMsg.content = "Maaf, aku sempat blank. Kamu bisa ulangi sekali lagi?";
          }
          _loading = false;
          _streamSub = null;
          _activeAssistantMsg = null;
          notifyListeners();
        },
        cancelOnError: true,
      );
    } catch (_) {
      if (assistantMsg.content.isEmpty) {
        assistantMsg.content = "Maaf, ada gangguan. Coba kirim lagi ya.";
      }
      _loading = false;
      _streamSub = null;
      _activeAssistantMsg = null;
      notifyListeners();
    }
  }

  Future<void> endRoom() async {
    final rid = _roomId;
    if (rid == null || _ended) return;

    // Cancel stream sebelum end
    await cancelStreaming(keepPartialText: true);

    _loading = true;
    notifyListeners();
    try {
      await api.endRoom(roomId: rid, userId: userId);
      _ended = true;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
  
  /// Menambahkan pesan sistem (disclaimer, info, dll)
  void addSystemMessage(String text) {
    if (text.trim().isEmpty) return;

    _streamSub?.cancel();
    _streamSub = null;
    _activeAssistantMsg = null;

    _messages.add(
      ChatMessage(
        role: Role.assistant,
        content: "[[DISCLAIMER]]$text",
      ),
    );

    notifyListeners();
  }



  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}
