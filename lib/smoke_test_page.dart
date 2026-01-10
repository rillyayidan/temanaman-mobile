import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool running = false;

  final ScrollController _scroll = ScrollController();
  final List<_LogItem> logs = [];

  void addLog(String message, {LogType type = LogType.info}) {
    setState(() {
      logs.insert(
        0,
        _LogItem(
          time: DateTime.now(),
          message: message,
          type: type,
        ),
      );
    });

    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _exportText() {
    final buffer = StringBuffer();
    buffer.writeln("=== TemanAman API Smoke Test Log ===");
    buffer.writeln("User ID : $userId");
    buffer.writeln("Exported: ${DateTime.now().toIso8601String()}");
    buffer.writeln("----------------------------------");

    for (final l in logs.reversed) {
      buffer.writeln(
        "[${l.time.toIso8601String()}] "
        "[${l.type.name.toUpperCase()}] "
        "${l.message}",
      );
    }

    return buffer.toString();
  }

  Future<void> exportLog() async {
    if (logs.isEmpty) return;

    final text = _exportText();
    await Clipboard.setData(ClipboardData(text: text));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Log berhasil disalin ke clipboard"),
      ),
    );
  }

  Future<void> runFlow() async {
    if (running) return;
    setState(() => running = true);

    try {
      addLog("Creating room...");
      final rid = await api.createRoom(userId: userId);
      roomId = rid;
      addLog("Room created: $rid", type: LogType.success);

      addLog("Sending message...");
      final reply = await api.sendMessage(
        roomId: rid,
        userId: userId,
        message: "Halo, aku lagi cemas.",
      );
      addLog("Assistant reply: $reply", type: LogType.ai);

      final state = await api.getRoomState(rid);
      addLog(
        "Room messages count: ${(state["messages"] as List).length}",
      );

      addLog("Ending room...");
      final deleted = await api.endRoom(roomId: rid, userId: userId);
      addLog("Room ended (deleted=$deleted)", type: LogType.success);

      try {
        await api.getRoomState(rid);
        addLog("WARN: room still exists (unexpected)", type: LogType.warn);
      } catch (_) {
        addLog("Room state after end: not found (expected)",
            type: LogType.success);
      }
    } catch (e) {
      addLog("ERROR: $e", type: LogType.error);
    } finally {
      setState(() => running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Smoke Test • TemanAman API"),
        actions: [
          IconButton(
            tooltip: "Export log",
            onPressed: logs.isEmpty ? null : exportLog,
            icon: const Icon(Icons.upload_file_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "API Flow Test",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              "create room → send message → get state → end room",
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: running
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(running ? "Running..." : "Run API Flow"),
                onPressed: running ? null : runFlow,
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: scheme.outlineVariant.withOpacity(0.6),
                  ),
                ),
                child: logs.isEmpty
                    ? Center(
                        child: Text(
                          "Belum ada log.\nTekan \"Run API Flow\" untuk memulai.",
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        reverse: true,
                        itemCount: logs.length,
                        itemBuilder: (_, i) => _LogTile(item: logs[i]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// LOG TILE
// =====================================================
class _LogTile extends StatelessWidget {
  final _LogItem item;
  const _LogTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Color color;
    IconData icon;

    switch (item.type) {
      case LogType.success:
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case LogType.error:
        color = Colors.red;
        icon = Icons.error_outline;
        break;
      case LogType.warn:
        color = Colors.orange;
        icon = Icons.warning_amber_rounded;
        break;
      case LogType.ai:
        color = scheme.primary;
        icon = Icons.smart_toy_outlined;
        break;
      default:
        color = scheme.onSurfaceVariant;
        icon = Icons.info_outline;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "[${item.time.toIso8601String().substring(11, 19)}] ${item.message}",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: "monospace",
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// MODELS
// =====================================================
enum LogType { info, success, warn, error, ai }

class _LogItem {
  final DateTime time;
  final String message;
  final LogType type;

  _LogItem({
    required this.time,
    required this.message,
    this.type = LogType.info,
  });
}
