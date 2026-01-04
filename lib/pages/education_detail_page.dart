import 'package:flutter/material.dart';
import '../api/education_api.dart';
import '../ui/app_tokens.dart';

class EducationDetailPage extends StatefulWidget {
  final String contentSlug;
  const EducationDetailPage({super.key, required this.contentSlug});

  @override
  State<EducationDetailPage> createState() => _EducationDetailPageState();
}

class _EducationDetailPageState extends State<EducationDetailPage> {
  final api = EducationApi();

  bool loading = true;
  String? error;
  ContentDetailDto? data;

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
      final res = await api.getContentDetail(widget.contentSlug);
      if (!mounted) return;
      setState(() {
        data = res;
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
  String _formatPublished(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return "";

    DateTime? dt;

    // 1) Coba parse ISO (paling umum)
    dt = DateTime.tryParse(s);

    // 2) Coba format "YYYY-MM-DD HH:mm:ss" (tanpa 'T')
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

    // Kalau tetap gagal, tampilkan raw tapi dipendekin
    if (dt == null) {
      return s.length > 32 ? "${s.substring(0, 32)}…" : s;
    }

    // Kalau DateTime.parse ISO ada 'Z', dia jadi UTC. Kita tampilkan local biar “manusiawi”.
    // Kalau dt sudah local, toLocal() aman juga.
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

    // Jika jam-menit meaningful (bukan 00:00), tampilkan jam juga.
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

    final publishedRaw = (data?.publishedAt ?? "").trim();
    final publishedPretty = publishedRaw.isEmpty ? "" : _formatPublished(publishedRaw);

    return Scaffold(
      appBar: AppBar(
        title: Text(data?.title ?? "Detail Edukasi"),
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
            ? const _DetailShimmer()
            : (error != null)
                ? _ErrorView(message: error!, onRetry: _load)
                : (data == null)
                    ? const _EmptyView(
                        title: "Konten tidak ditemukan",
                        message: "Coba refresh atau kembali ke daftar konten.",
                        icon: Icons.article_outlined,
                      )
                    : SingleChildScrollView(
                        padding: AppTokens.pagePadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1️⃣ JUDUL
                            Text(
                              data!.title,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: AppTokens.s10),

                            // 2️⃣ META (tanggal)
                            Wrap(
                              spacing: AppTokens.s8,
                              runSpacing: AppTokens.s8,
                              children: [
                                if (publishedPretty.isNotEmpty)
                                  _MetaPill(
                                    icon: Icons.calendar_today_outlined,
                                    text: "Dipublikasikan: $publishedPretty",
                                  ),
                              ],
                            ),

                            const SizedBox(height: AppTokens.s12),
                            Divider(color: scheme.outlineVariant.withOpacity(0.6)),
                            const SizedBox(height: AppTokens.s12),

                            // 3️⃣ INFO CALLOUT (INI TEMPAT YANG BENAR)
                            _InfoCallout(
                              icon: Icons.info_outline,
                              title: "Catatan Penting",
                              message:
                                  "Informasi ini bersifat edukatif dan tidak menggantikan bantuan profesional. "
                                  "Jika kamu membutuhkan bantuan segera, gunakan menu Layanan Bantuan.",
                            ),

                            const SizedBox(height: AppTokens.s16),

                            // 4️⃣ BODY ARTIKEL (SATU KALI SAJA)
                            _ArticleCard(
                              child: Text(
                                data!.body,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      height: 1.75,
                                      letterSpacing: 0.2,
                                    ),
                              ),
                            ),

                            const SizedBox(height: AppTokens.s24),
                          ],
                        ),
                      )

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
            Text("Gagal memuat detail", style: Theme.of(context).textTheme.titleMedium),
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

/// Shimmer detail sederhana (tanpa package)
class _DetailShimmer extends StatefulWidget {
  const _DetailShimmer();

  @override
  State<_DetailShimmer> createState() => _DetailShimmerState();
}

class _DetailShimmerState extends State<_DetailShimmer> with SingleTickerProviderStateMixin {
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

    Widget bar(double h, double w) => Container(
          height: h,
          width: w,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(10),
          ),
        );

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
                      bar(18, 260),
                      const SizedBox(height: AppTokens.s12),
                      bar(12, 180),
                      const SizedBox(height: AppTokens.s16),
                      bar(12, double.infinity),
                      const SizedBox(height: AppTokens.s10),
                      bar(12, double.infinity),
                      const SizedBox(height: AppTokens.s10),
                      bar(12, 280),
                      const SizedBox(height: AppTokens.s10),
                      bar(12, double.infinity),
                      const SizedBox(height: AppTokens.s10),
                      bar(12, 220),
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

class _ArticleCard extends StatelessWidget {
  final Widget child;
  const _ArticleCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s18,
        vertical: AppTokens.s20,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppTokens.radius(AppTokens.r24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: scheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: child,
    );
  }
}

class _InfoCallout extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _InfoCallout({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppTokens.s14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withOpacity(0.65),
        borderRadius: AppTokens.radius(AppTokens.r16),
        border: Border(
          left: BorderSide(
            color: scheme.primary,
            width: 4,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.onPrimaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.onPrimaryContainer,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
