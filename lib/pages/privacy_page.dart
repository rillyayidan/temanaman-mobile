import 'package:flutter/material.dart';
import '../api/privacy_api.dart';
import '../ui/app_tokens.dart';
import 'package:flutter_html/flutter_html.dart';

class PrivacyPage extends StatefulWidget {
  final String code; // privacy_policy / ai_disclaimer / terms
  const PrivacyPage({super.key, this.code = "privacy_policy"});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  final api = PrivacyApi();

  PrivacyPageDto? page;
  late String activeCode;
  String? error;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    activeCode = widget.code;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await api.getPrivacy(code: activeCode);
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

  String _formatUpdated(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return "";

    DateTime? dt = DateTime.tryParse(s);
    if (dt == null) return s;

    final local = dt.toLocal();
    const months = [
      "Jan","Feb","Mar","Apr","Mei","Jun",
      "Jul","Agu","Sep","Okt","Nov","Des"
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
    final title = page?.title ?? "Privasi";
    final updatedPretty = _formatUpdated(page?.updatedAt ?? "");

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
            : error != null
                ? _ErrorView(message: error!, onRetry: _load)
                : page == null
                    ? const _EmptyView(
                        title: "Konten tidak tersedia",
                        message: "Halaman belum tersedia saat ini.",
                        icon: Icons.privacy_tip_outlined,
                      )
                    : SingleChildScrollView(
                        padding: AppTokens.pagePadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SegmentTabs(
                              value: activeCode,
                              onChanged: (v) {
                                if (v == activeCode) return;
                                setState(() => activeCode = v);
                                _load();
                              },
                            ),
                            const SizedBox(height: AppTokens.s20),

                            Text(
                              page!.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (updatedPretty.isNotEmpty) ...[
                              const SizedBox(height: AppTokens.s8),
                              _MetaPill(
                                icon: Icons.update_outlined,
                                text: "Diperbarui: $updatedPretty",
                              ),
                            ],

                            const SizedBox(height: AppTokens.s20),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppTokens.s18),
                              decoration: BoxDecoration(
                                color: scheme.surface,
                                borderRadius: AppTokens.radius(AppTokens.r24),
                                border: Border.all(
                                  color: scheme.outlineVariant.withOpacity(0.5),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Html(
                                data: page!.body,
                                style: {
                                  "body": Style(
                                    margin: Margins.zero,
                                    padding: HtmlPaddings.zero,
                                    fontSize: FontSize(
                                      Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.fontSize ??
                                          14,
                                    ),
                                    lineHeight: const LineHeight(1.6),
                                    color: scheme.onSurface,
                                  ),
                                  "p": Style(margin: Margins.only(bottom: 12)),
                                  "li": Style(margin: Margins.only(bottom: 8)),
                                },
                              ),
                            ),

                            SizedBox(height: AppTokens.s24),
                          ],
                        ),
                      ),
      ),
    );
  }
}

/* ================== COMPONENTS ================== */

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _SegmentTabs extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _SegmentTabs({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget item(String code, String label) {
      final selected = value == code;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => onChanged(code),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? scheme.primary
                    : scheme.outlineVariant.withOpacity(0.6),
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      color: selected
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        item("privacy_policy", "Privasi"),
        const SizedBox(width: 8),
        item("ai_disclaimer", "AI"),
        const SizedBox(width: 8),
        item("terms", "Ketentuan"),
      ],
    );
  }
}

/* ================== STATES ================== */

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
            Text("Gagal memuat halaman",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTokens.s6),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
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
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/* ================== SHIMMER ================== */

class _PrivacyShimmer extends StatelessWidget {
  const _PrivacyShimmer();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: AppTokens.pagePadding,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: AppTokens.radius(AppTokens.r24),
        ),
      ),
    );
  }
}
