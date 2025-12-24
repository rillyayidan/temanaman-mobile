import 'package:flutter/material.dart';
import 'api/teman_aman_api.dart';

class SmokeTestPage extends StatefulWidget {
  const SmokeTestPage({super.key});

  @override
  State<SmokeTestPage> createState() => _SmokeTestPageState();
}

class _SmokeTestPageState extends State<SmokeTestPage> {
  final api = TemanAmanApi();
  final userId = "demo_user_001";

  String? roomId;
  String logText = "";

  void log(String s) {
    setState(() => logText = "${DateTime.now().toIso8601String()}  $s\n$logText");
  }

  Future<void> runFlow() async {
    try {
      log("Creating room...");
      final rid = await api.createRoom(userId: userId);
      roomId = rid;
      log("Room created: $rid");

      log("Sending message...");
      final reply = await api.sendMessage(roomId: rid, userId: userId, message: "Halo, aku lagi cemas.");
      log("Assistant: $reply");

      final state = await api.getRoomState(rid);
      log("Room messages count: ${(state["messages"] as List).length}");

      log("Ending room...");
      final deleted = await api.endRoom(roomId: rid, userId: userId);
      log("Room ended. deleted=$deleted");

      // Optional: verify already deleted
      try {
        await api.getRoomState(rid);
        log("WARN: room still exists (unexpected)");
      } catch (e) {
        log("Room state after end: not found (expected)");
      }
    } catch (e) {
      log("ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("TemanAman Smoke Test")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            FilledButton(
              onPressed: runFlow,
              child: const Text("Run API Flow"),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                reverse: true,
                child: Text(logText),
              ),
            )
          ],
        ),
      ),
    );
  }
}
