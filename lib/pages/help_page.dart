import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/help_api.dart';
import '../ui/app_tokens.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final api = HelpApi();
  final ScrollController _scrollController = ScrollController();

  List<HelpContactDto> items = [];
  String? error;
  bool loading = true;

  final List<String?> regions = [
    null,
    "Indonesia",
    "Yogyakarta",
    "Jawa Tengah",
    "Jawa Barat",
    "Jawa Timur",
    "DKI Jakarta",
    "Banten",
  ];
  String? selectedRegion;

  Timer? _reloadDebounce;
  bool _isHeaderExpanded = true;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _reloadDebounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Header mengecil setelah scroll > 50px
    final shouldExpand = _scrollController.offset < 50;
    if (shouldExpand != _isHeaderExpanded) {
      setState(() => _isHeaderExpanded = shouldExpand);
    }
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await api.listHelp(region: selectedRegion);
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

  void _scheduleReload() {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 250), _load);
  }

  // =============================
  // ACTION HANDLERS
  // =============================

  Future<void> _openContact(HelpContactDto c) async {
    final uri = _buildUri(c);

    if (uri == null) {
      await _copyWithFallbackSnack(c.contactValue, opened: false);
      return;
    }

    if (!await canLaunchUrl(uri)) {
      await _copyWithFallbackSnack(c.contactValue, opened: false);
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      await _copyWithFallbackSnack(c.contactValue, opened: false);
    }
  }

  Uri? _buildUri(HelpContactDto c) {
    final value = c.contactValue.trim();

    switch (c.contactType) {
      case "phone":
        return Uri.parse("tel:$value");

      case "whatsapp":
        var digits = value.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.startsWith('0')) {
          digits = digits.replaceFirst(RegExp(r'^0'), '62');
        } else if (digits.startsWith('62')) {
          // ok
        } else if (value.trim().startsWith('+62')) {
          digits = '62${digits.replaceFirst(RegExp(r'^62'), '')}';
        }
        return Uri.parse("https://wa.me/$digits");

      case "email":
        return Uri.parse("mailto:$value");

      case "website":
        return Uri.parse(value.startsWith("http") ? value : "https://$value");

      case "instagram":
        if (value.startsWith("http")) return Uri.parse(value);
        final username = value.replaceAll("@", "");
        return Uri.parse("https://instagram.com/$username");

      default:
        return null;
    }
  }

  Future<void> _copyWithFallbackSnack(
    String text, {
    required bool opened,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          opened
              ? "Berhasil dibuka"
              : "Tidak bisa dibuka, disalin ke clipboard",
        ),
      ),
    );
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Disalin ke clipboard")));
  }

  String _typeLabel(String t) {
    switch (t) {
      case "phone":
        return "Telepon";
      case "whatsapp":
        return "WhatsApp";
      case "email":
        return "Email";
      case "website":
        return "Website";
      case "instagram":
        return "Instagram";
      default:
        return "Lainnya";
    }
  }

  IconData _typeIcon(String t) {
    switch (t) {
      case "phone":
        return Icons.phone_rounded;
      case "whatsapp":
        return Icons.chat_rounded;
      case "email":
        return Icons.email_rounded;
      case "website":
        return Icons.language_rounded;
      case "instagram":
        return Icons.camera_alt_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _actionLabel(String type) {
    switch (type) {
      case "phone":
        return "Telepon";
      case "whatsapp":
        return "Chat";
      case "email":
        return "Email";
      case "website":
      case "instagram":
        return "Buka";
      default:
        return "Buka";
    }
  }

  // =============================
  // UI
  // =============================

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Layanan Bantuan"),
        actions: [
          IconButton(
            tooltip: "Refresh",
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header dengan animasi collapse
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: EdgeInsets.fromLTRB(
                16,
                _isHeaderExpanded ? 12 : 8,
                16,
                _isHeaderExpanded ? 8 : 6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title dan deskripsi - hilang saat scroll
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200),
                    crossFadeState: _isHeaderExpanded
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Kontak bantuan cepat",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppTokens.s6),
                        Text(
                          "Pilih region untuk melihat kontak terdekat. Tap kartu untuk membuka. Jika gagal, kamu bisa salin nomor/link.",
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(height: AppTokens.s12),
                      ],
                    ),
                    secondChild: const SizedBox.shrink(),
                  ),
                  // Dropdown filter - tetap terlihat
                  DropdownButtonFormField<String?>(
                    value: selectedRegion,
                    items: regions
                        .map(
                          (r) => DropdownMenuItem<String?>(
                            value: r,
                            child: Text(r ?? "Semua region"),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() => selectedRegion = v);
                      _scheduleReload();
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.place_outlined),
                      labelText: "Region",
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : (error != null)
                      ? _ErrorView(message: error!, onRetry: _load)
                      : (items.isEmpty)
                          ? const _EmptyView(
                              title: "Belum ada kontak",
                              message:
                                  "Tidak ada data kontak bantuan untuk region ini.",
                              icon: Icons.support_agent_outlined,
                            )
                          : ListView.separated(
                              controller: _scrollController,
                              padding: AppTokens.listPadding,
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppTokens.s12),
                              itemBuilder: (context, i) {
                                final c = items[i];
                                return _HelpCard(
                                  contact: c,
                                  typeLabel: _typeLabel(c.contactType),
                                  typeIcon: _typeIcon(c.contactType),
                                  actionLabel: _actionLabel(c.contactType),
                                  onOpen: () => _openContact(c),
                                  onCopy: () => _copy(c.contactValue),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  final HelpContactDto contact;
  final String typeLabel;
  final IconData typeIcon;
  final String actionLabel;
  final VoidCallback onOpen;
  final VoidCallback onCopy;

  const _HelpCard({
    required this.contact,
    required this.typeLabel,
    required this.typeIcon,
    required this.actionLabel,
    required this.onOpen,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: AppTokens.radius(AppTokens.r20),
      child: InkWell(
        borderRadius: AppTokens.radius(AppTokens.r20),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(AppTokens.s14),
          decoration: BoxDecoration(
            borderRadius: AppTokens.radius(AppTokens.r20),
            border: Border.all(color: scheme.outlineVariant.withOpacity(0.65)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _LeadingBadge(icon: typeIcon),
                  const SizedBox(width: AppTokens.s12),
                  Expanded(
                    child: Text(
                      contact.organizationName,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s10),
              Wrap(
                spacing: AppTokens.s8,
                runSpacing: AppTokens.s8,
                children: [
                  _Chip(text: typeLabel, icon: typeIcon),
                  if ((contact.region ?? "").trim().isNotEmpty)
                    _Chip(
                      text: contact.region!.trim(),
                      icon: Icons.place_outlined,
                    ),
                  if ((contact.availability ?? "").trim().isNotEmpty)
                    _Chip(
                      text: contact.availability!.trim(),
                      icon: Icons.schedule_outlined,
                    ),
                ],
              ),
              const SizedBox(height: AppTokens.s12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTokens.s12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: AppTokens.radius(AppTokens.r16),
                ),
                child: SelectableText(
                  contact.contactValue,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if ((contact.description ?? "").trim().isNotEmpty) ...[
                const SizedBox(height: AppTokens.s10),
                Text(
                  contact.description!.trim(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
              ],
              const SizedBox(height: AppTokens.s12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCopy,
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text("Salin"),
                    ),
                  ),
                  const SizedBox(width: AppTokens.s10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: Text(actionLabel),
                    ),
                  ),
                ],
              ),
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

class _Chip extends StatelessWidget {
  final String text;
  final IconData icon;
  const _Chip({required this.text, required this.icon});

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
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
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
            Icon(
              Icons.wifi_off_rounded,
              size: 44,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppTokens.s12),
            Text(
              "Gagal memuat layanan bantuan",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTokens.s6),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}