import 'package:flutter/material.dart';
import '../api/privacy_api.dart';
import '../ui/app_tokens.dart';

class PrivacyPage extends StatefulWidget {
  final String code; // privacy_policy / ai_disclaimer / terms
  const PrivacyPage({super.key, this.code = "privacy_policy"});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  final api = PrivacyApi();

  PrivacyPageDto? page;
  String? error;
  bool loading = true;

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
      final res = await api.getPrivacy(code: widget.code);
      if (!mounted) return;
      setState(() {
        page = res;
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

  // -----------------------------
  // Human-friendly date formatter
  // -----------------------------
  String _formatUpdated(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return "";

    DateTime? dt;

    // 1) ISO parse
    dt = DateTime.tryParse(s);

    // 2) "YYYY-MM-DD HH:mm:ss" / "YYYY-MM-DD HH:mm"
    if (dt == null) {
      final m = RegExp(
        r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})(?::(\d{2}))?',
      ).firstMatch(s);
      if (m != null) {
        final y = int.parse(m.group(1)!);
        final mo = int.parse(m.group(2)!);
        final d = int.parse(m.group(3)!);
        final hh = int.parse(m.group(4)!);
        final mm = int.parse(m.group(5)!);
        final ss = int.tryParse(m.group(6) ?? '0') ?? 0;
        dt = DateTime(y, mo, d, hh, mm, ss);
      }
    }

    if (dt == null) {
      return s.length > 32 ? "${s.substring(0, 32)}…" : s;
    }

    final local = dt.toLocal();

    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "Mei",
      "Jun",
      "Jul",
      "Agu",
      "Sep",
      "Okt",
      "Nov",
      "Des",
    ];

    final day = local.day.toString().padLeft(2, '0');
    final mon = months[local.month - 1];
    final year = local.year;

    final hasTime = !(local.hour == 0 && local.minute == 0);
    if (hasTime) {
      final hh = local.hour.toString().padLeft(2, '0');
      final mm = local.minute.toString().padLeft(2, '0');
      return "$day $mon $year • $hh:$mm";
    }

    return "$day $mon $year";
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // biar title appbar tidak “loncat” saat loading: default "Privasi"
    final title = (page?.title ?? "Privasi");

    final updatedRaw = (page?.updatedAt ?? "").trim();
    final updatedPretty = updatedRaw.isEmpty ? "" : _formatUpdated(updatedRaw);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: "Refresh",
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: loading
            ? const _PrivacyShimmer()
            : (error != null)
                ? _ErrorView(message: error!, onRetry: _load)
                : (page == null)
                    ? const _EmptyView(
                        title: "Konten tidak tersedia",
                        message: "Halaman privasi belum tersedia saat ini.",
                        icon: Icons.privacy_tip_outlined,
                      )
                    : SingleChildScrollView(
                        padding: AppTokens.pagePadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              page!.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppTokens.s10),
                            if (updatedPretty.isNotEmpty)
                              _MetaPill(
                                icon: Icons.update_outlined,
                                text: "Diperbarui: $updatedPretty",
                              ),
                            const SizedBox(height: AppTokens.s16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppTokens.s16),
                              decoration: BoxDecoration(
                                color: scheme.surface,
                                borderRadius: AppTokens.radius(AppTokens.r20),
                                border: Border.all(
                                  color: scheme.outlineVariant.withOpacity(0.65),
                                ),
                              ),
                              child: Text(
                                page!.body,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      height: 1.55,
                                    ),
                              ),
                            ),
                            const SizedBox(height: AppTokens.s24),
                          ],
                        ),
                      ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaPill({required this.icon, required this.text});

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
            Text("Gagal memuat halaman", style: Theme.of(context).textTheme.titleMedium),
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

class _PrivacyShimmer extends StatefulWidget {
  const _PrivacyShimmer();

  @override
  State<_PrivacyShimmer> createState() => _PrivacyShimmerState();
}

class _PrivacyShimmerState extends State<_PrivacyShimmer> with SingleTickerProviderStateMixin {
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

    Widget box({required double h, double? w}) {
      return Container(
        height: h,
        width: w ?? double.infinity,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(10),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;

        return Padding(
          padding: AppTokens.pagePadding,
          child: ClipRRect(
            borderRadius: AppTokens.radius(AppTokens.r20),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTokens.s16),
                  decoration: BoxDecoration(
                    color: base,
                    border: Border.all(color: scheme.outlineVariant.withOpacity(0.65)),
                    borderRadius: AppTokens.radius(AppTokens.r20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      box(h: 18, w: 220),
                      const SizedBox(height: AppTokens.s12),
                      box(h: 12, w: 160),
                      const SizedBox(height: AppTokens.s16),
                      box(h: 12),
                      const SizedBox(height: AppTokens.s10),
                      box(h: 12),
                      const SizedBox(height: AppTokens.s10),
                      box(h: 12, w: 260),
                      const SizedBox(height: AppTokens.s10),
                      box(h: 12),
                      const SizedBox(height: AppTokens.s10),
                      box(h: 12, w: 200),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.55,
                    child: Transform.translate(
                      offset: Offset((t * 2 - 1) * 260, 0),
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
          ),
        );
      },
    );
  }
}
