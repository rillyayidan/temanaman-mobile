import 'package:flutter/material.dart';
import '../api/education_api.dart';
import '../ui/app_tokens.dart';
import 'education_contents_page.dart';

class EducationCategoriesPage extends StatefulWidget {
  const EducationCategoriesPage({super.key});

  @override
  State<EducationCategoriesPage> createState() => _EducationCategoriesPageState();
}

class _EducationCategoriesPageState extends State<EducationCategoriesPage> {
  final api = EducationApi();

  bool loading = true;
  String? error;
  List<CategoryDto> items = [];

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
      final res = await api.listCategories();
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edukasi"),
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
            ? const _ListShimmer(itemCount: 6)
            : (error != null)
                ? _ErrorView(message: error!, onRetry: _load)
                : (items.isEmpty)
                    ? const _EmptyView(
                        title: "Belum ada kategori",
                        message: "Kategori edukasi belum tersedia saat ini.",
                        icon: Icons.menu_book_outlined,
                      )
                    : ListView(
                        padding: AppTokens.listPadding,
                        children: [
                          Text(
                            "Pilih kategori",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppTokens.s6),
                          Text(
                            "Baca materi singkat, jelas, dan langsung bisa dipraktikkan.",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: AppTokens.s16),
                          ...items.map((c) {
                            final desc = (c.description ?? "").trim();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppTokens.s12),
                              child: _EduCard(
                                title: c.name,
                                subtitle: desc.isEmpty ? null : desc,
                                leading: Icons.category_outlined,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EducationContentsPage(categorySlug: c.slug),
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

class _EduCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData leading;
  final VoidCallback onTap;

  const _EduCard({
    required this.title,
    required this.leading,
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
              _LeadingBadge(icon: leading),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
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
            Text("Gagal memuat kategori", style: Theme.of(context).textTheme.titleMedium),
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
                    height: 84,
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
      },
    );
  }
}
