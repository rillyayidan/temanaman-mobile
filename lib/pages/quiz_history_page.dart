import 'package:flutter/material.dart';
import '../api/quiz_api.dart';
import '../ui/app_tokens.dart';

class QuizHistoryPage extends StatefulWidget {
  const QuizHistoryPage({super.key, required this.userKey});
  final String userKey;

  @override
  State<QuizHistoryPage> createState() => _QuizHistoryPageState();
}

class _QuizHistoryPageState extends State<QuizHistoryPage> {
  final api = QuizApi();

  bool loading = true;
  String? error;
  List<HistoryItemDto> items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await api.history(userKey: widget.userKey);
      if (!mounted) return;
      setState(() {
        items = res;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case "completed":
        return "Selesai";
      case "abandoned":
        return "Ditinggalkan";
      case "in_progress":
        return "Berjalan";
      default:
        return s;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case "completed":
        return Icons.verified_outlined;
      case "abandoned":
        return Icons.block_outlined;
      case "in_progress":
        return Icons.timelapse_outlined;
      default:
        return Icons.info_outline;
    }
  }

  // =============================
  // Timestamp formatting (no package)
  // =============================

  static const List<String> _bulan = [
    "Jan", "Feb", "Mar", "Apr", "Mei", "Jun",
    "Jul", "Agu", "Sep", "Okt", "Nov", "Des",
  ];

  String _two(int v) => v.toString().padLeft(2, '0');

  /// ISO -> "24 Des 2025 • 07:15"
  /// Kalau gagal parse, fallback ke raw string.
  String _fmtDateTime(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return "-";
    final dt = DateTime.tryParse(s);
    if (dt == null) return raw;

    final local = dt.toLocal();
    final day = local.day;
    final month = _bulan[(local.month - 1).clamp(0, 11)];
    final year = local.year;
    final hh = _two(local.hour);
    final mm = _two(local.minute);
    return "$day $month $year • $hh:$mm";
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Kuis"),
        actions: [
          IconButton(
            tooltip: "Refresh",
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : (error != null)
                ? _ErrorView(message: error!, onRetry: _load)
                : (items.isEmpty)
                    ? const _EmptyView(
                        title: "Belum ada riwayat",
                        message: "Mainkan kuis untuk melihat progres dan skor kamu di sini.",
                        icon: Icons.history,
                      )
                    : ListView.separated(
                        padding: AppTokens.listPadding,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppTokens.s12),
                        itemBuilder: (context, i) {
                          final h = items[i];
                          final label = _statusLabel(h.status);
                          final icon = _statusIcon(h.status);

                          final started = _fmtDateTime(h.startedAt);
                          final finished = (h.finishedAt ?? "").trim().isEmpty
                              ? null
                              : _fmtDateTime(h.finishedAt!);

                          return Container(
                            decoration: BoxDecoration(
                              color: scheme.surface,
                              borderRadius: AppTokens.radius(AppTokens.r20),
                              border: Border.all(
                                color: scheme.outlineVariant.withOpacity(0.65),
                              ),
                            ),
                            padding: const EdgeInsets.all(AppTokens.s14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        h.levelName,
                                        style: Theme.of(context).textTheme.titleMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: AppTokens.s8),
                                    _StatusChip(label: label, icon: icon),
                                  ],
                                ),
                                const SizedBox(height: AppTokens.s10),
                                Wrap(
                                  spacing: AppTokens.s10,
                                  runSpacing: AppTokens.s8,
                                  children: [
                                    _MetaPill(
                                      icon: Icons.emoji_events_outlined,
                                      text: "Skor ${h.score}",
                                    ),
                                    _MetaPill(
                                      icon: Icons.check_circle_outline,
                                      text: "${h.correctCount}/${h.totalQuestions} benar",
                                    ),
                                    _MetaPill(
                                      icon: Icons.play_circle_outline,
                                      text: "Mulai: $started",
                                    ),
                                    if (finished != null)
                                      _MetaPill(
                                        icon: Icons.flag_outlined,
                                        text: "Selesai: $finished",
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _StatusChip({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: AppTokens.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 44, color: scheme.onSurfaceVariant),
            const SizedBox(height: AppTokens.s12),
            Text("Gagal memuat riwayat", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTokens.s6),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppTokens.s14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text("Coba lagi"),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const _EmptyView({
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: AppTokens.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: scheme.onSurfaceVariant),
            const SizedBox(height: AppTokens.s12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTokens.s6),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
