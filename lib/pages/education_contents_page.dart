import 'package:flutter/material.dart';
import '../api/education_api.dart';
import '../ui/app_tokens.dart';
import 'education_detail_page.dart';

class EducationContentsPage extends StatefulWidget {
  final String categorySlug;
  const EducationContentsPage({super.key, required this.categorySlug});

  @override
  State<EducationContentsPage> createState() => _EducationContentsPageState();
}

class _EducationContentsPageState extends State<EducationContentsPage> {
  final api = EducationApi();

  bool loading = true;
  String? error;
  ContentListDto? data;

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
      final res = await api.listContentsByCategorySlug(widget.categorySlug);
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = data?.category.name ?? "Konten";

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
        child: loading
            ? const _ListShimmer(itemCount: 7)
            : (error != null)
                ? _ErrorView(message: error!, onRetry: _load)
                : (data == null || data!.items.isEmpty)
                    ? const _EmptyView(
                        title: "Belum ada konten",
                        message: "Konten untuk kategori ini belum tersedia.",
                        icon: Icons.article_outlined,
                      )
                    : ListView(
                        padding: AppTokens.listPadding,
                        children: [
                          Text(
                            "Daftar konten",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppTokens.s6),
                          Text(
                            "Pilih salah satu untuk membaca detail. Materi dibuat ringkas dan mudah dipahami.",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: AppTokens.s16),
                          ...data!.items.map((item) {
                            final excerpt = (item.excerpt ?? "").trim();

                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppTokens.s12),
                              child: _ContentCard(
                                title: item.title,
                                subtitle: excerpt.isEmpty ? null : excerpt,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EducationDetailPage(contentSlug: item.slug),
                                    ),
                                  );
                                },
                              ),
                            );
                          }),
                        ],
                      ),
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ContentCard({
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: AppTokens.radius(AppTokens.r20),
      child: InkWell(
        borderRadius: AppTokens.radius(AppTokens.r20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppTokens.s14),
          decoration: BoxDecoration(
            borderRadius: AppTokens.radius(AppTokens.r20),
            border: Border.all(color: scheme.outlineVariant.withOpacity(0.65)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _LeadingBadge(icon: Icons.article_outlined),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppTokens.s6),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadingBadge extends StatelessWidget {
  final IconData icon;
  const _LeadingBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: AppTokens.radius(AppTokens.r16),
      ),
      child: Icon(icon, color: scheme.onSurfaceVariant),
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
            Text("Gagal memuat konten", style: Theme.of(context).textTheme.titleMedium),
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

/// Shimmer list sederhana (tanpa package)
class _ListShimmer extends StatefulWidget {
  final int itemCount;
  const _ListShimmer({required this.itemCount});

  @override
  State<_ListShimmer> createState() => _ListShimmerState();
}

class _ListShimmerState extends State<_ListShimmer> with SingleTickerProviderStateMixin {
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

    return ListView.separated(
      padding: AppTokens.listPadding,
      itemCount: widget.itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: AppTokens.s12),
      itemBuilder: (_, __) {
        return AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            return ClipRRect(
              borderRadius: AppTokens.radius(AppTokens.r20),
              child: Stack(
                children: [
                  Container(
                    height: 94,
                    padding: const EdgeInsets.all(AppTokens.s14),
                    decoration: BoxDecoration(
                      color: base,
                      border: Border.all(color: scheme.outlineVariant.withOpacity(0.65)),
                      borderRadius: AppTokens.radius(AppTokens.r20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: AppTokens.radius(AppTokens.r16),
                          ),
                        ),
                        const SizedBox(width: AppTokens.s12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(height: 14, width: double.infinity, color: scheme.surface),
                              const SizedBox(height: AppTokens.s10),
                              Container(height: 12, width: 260, color: scheme.surface),
                              const SizedBox(height: AppTokens.s8),
                              Container(height: 12, width: 200, color: scheme.surface),
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
      },
    );
  }
}
