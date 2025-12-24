import 'package:flutter/material.dart';
import '../api/quiz_api.dart';
import 'quiz_play_page.dart';
import 'quiz_history_page.dart';
import '../ui/app_tokens.dart';

class QuizLevelsPage extends StatefulWidget {
  const QuizLevelsPage({super.key, required this.userKey});
  final String userKey;

  @override
  State<QuizLevelsPage> createState() => _QuizLevelsPageState();
}

class _QuizLevelsPageState extends State<QuizLevelsPage> {
  final api = QuizApi();

  bool loading = true;
  String? error;
  List<QuizLevelDto> items = [];

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
      final res = await api.levels(userKey: widget.userKey);
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

  Future<void> _start(QuizLevelDto lv) async {
    if (lv.isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Level terkunci. Selesaikan level sebelumnya dulu.")),
      );
      return;
    }

    try {
      final start = await api.start(userKey: widget.userKey, levelId: lv.id);
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizPlayPage(
            userKey: widget.userKey,
            attemptId: start.attemptId,
            levelName: lv.name,
          ),
        ),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kuis"),
        actions: [
          IconButton(
            tooltip: "Refresh",
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: "Riwayat",
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuizHistoryPage(userKey: widget.userKey),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: loading
            ? const _LevelsShimmer()
            : (error != null)
                ? _ErrorView(message: error!, onRetry: _load)
                : (items.isEmpty)
                    ? const _EmptyView(
                        title: "Belum ada level",
                        message: "Level kuis belum tersedia saat ini.",
                        icon: Icons.quiz_outlined,
                      )
                    : ListView(
                        padding: AppTokens.listPadding,
                        children: [
                          Text(
                            "Pilih level",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppTokens.s6),
                          Text(
                            "Selesaikan level untuk membuka level berikutnya. Tanpa timer — fokus ke pemahaman.",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: AppTokens.s16),
                          ...items.map((lv) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppTokens.s12),
                              child: _LevelCard(
                                level: lv,
                                onTap: () => _start(lv),
                              ),
                            );
                          }),
                        ],
                      ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final QuizLevelDto level;
  final VoidCallback onTap;

  const _LevelCard({
    required this.level,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final isLocked = level.isLocked;
    final bg = isLocked ? scheme.surfaceContainerHighest : scheme.primaryContainer.withOpacity(0.45);
    final border = scheme.outlineVariant.withOpacity(0.65);

    return Material(
      color: bg,
      borderRadius: AppTokens.radius(AppTokens.r20),
      child: InkWell(
        borderRadius: AppTokens.radius(AppTokens.r20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppTokens.s14),
          decoration: BoxDecoration(
            borderRadius: AppTokens.radius(AppTokens.r20),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              _LevelBadge(
                text: level.name,
                locked: isLocked,
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((level.description ?? "").trim().isNotEmpty) ...[
                      const SizedBox(height: AppTokens.s6),
                      Text(
                        level.description!.trim(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.25,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else ...[
                      const SizedBox(height: AppTokens.s6),
                      Text(
                        isLocked ? "Selesaikan level sebelumnya untuk membuka." : "Siap dimainkan.",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                    const SizedBox(height: AppTokens.s10),
                    Row(
                      children: [
                        Icon(
                          isLocked ? Icons.lock_outline : Icons.play_circle_outline,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppTokens.s6),
                        Text(
                          isLocked ? "Terkunci" : "Mulai",
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Icon(
                isLocked ? Icons.lock : Icons.chevron_right,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final String text;
  final bool locked;

  const _LevelBadge({required this.text, required this.locked});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Ambil angka dari "Level 1" / "Lv 2" kalau ada; kalau tidak, pakai "L"
    final match = RegExp(r'(\d+)').firstMatch(text);
    final label = match != null ? match.group(1)! : "L";

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppTokens.radius(AppTokens.r16),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.65)),
      ),
      child: Center(
        child: locked
            ? Icon(Icons.lock_outline, size: 20, color: scheme.onSurfaceVariant)
            : Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
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
            Text("Gagal memuat level", style: Theme.of(context).textTheme.titleMedium),
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

/// Shimmer sederhana untuk list level (tanpa package)
class _LevelsShimmer extends StatelessWidget {
  const _LevelsShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: AppTokens.listPadding,
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: AppTokens.s12),
      itemBuilder: (_, __) => const _ShimmerTile(),
    );
  }
}

class _ShimmerTile extends StatefulWidget {
  const _ShimmerTile();

  @override
  State<_ShimmerTile> createState() => _ShimmerTileState();
}

class _ShimmerTileState extends State<_ShimmerTile> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return ClipRRect(
          borderRadius: AppTokens.radius(AppTokens.r20),
          child: Stack(
            children: [
              Container(
                height: 88,
                padding: const EdgeInsets.all(AppTokens.s14),
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: AppTokens.radius(AppTokens.r20),
                  border: Border.all(color: scheme.outlineVariant.withOpacity(0.65)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: AppTokens.radius(AppTokens.r16),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(height: 14, width: double.infinity, color: scheme.surface),
                          const SizedBox(height: AppTokens.s10),
                          Container(height: 12, width: 220, color: scheme.surface),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0.55,
                  child: Transform.translate(
                    offset: Offset((t * 2 - 1) * 240, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.transparent,
                            scheme.surface.withOpacity(0.65),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
