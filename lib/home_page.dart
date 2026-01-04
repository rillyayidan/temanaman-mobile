import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'services/user_identity.dart';

import 'chat/chat_page.dart';
import 'pages/quiz_levels_page.dart';
import 'pages/education_categories_page.dart';
import 'pages/privacy_page.dart';
import 'pages/help_page.dart';
import 'package:flutter/services.dart';

import 'ui/app_tokens.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? userKey;

  @override
  void initState() {
    super.initState();
    _loadUserKey();
  }

  Future<void> _loadUserKey() async {
    final key = await UserIdentity.getUserKey();
    if (!mounted) return;
    setState(() => userKey = key);
  }

  Future<bool> _confirmExit(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Keluar aplikasi?"),
        content: const Text("Kamu yakin ingin keluar dari TemanAman?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Keluar"),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (userKey == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: AppTokens.s12),
                Text(
                  "Menyiapkan identitas pengguna…",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final items = <_HomeItem>[
      _HomeItem(
        title: "Chat AI",
        subtitle: "Curhat & dukungan awal",
        icon: Icons.chat_bubble_outline,
        isPrimary: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatPage(userKey: userKey!)),
          );
        },
      ),
      _HomeItem(
        title: "Edukasi",
        subtitle: "Materi & tips aman",
        icon: Icons.menu_book_outlined,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EducationCategoriesPage()),
          );
        },
      ),
      _HomeItem(
        title: "Kuis",
        subtitle: "Level up + riwayat",
        icon: Icons.quiz_outlined,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuizLevelsPage(userKey: userKey!),
            ),
          );
        },
      ),
      _HomeItem(
        title: "Layanan Bantuan",
        subtitle: "Website/WA/telepon",
        icon: Icons.support_agent_outlined,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HelpPage()),
          );
        },
      ),
      _HomeItem(
        title: "Info Privasi",
        subtitle: "Kebijakan & disclaimer",
        icon: Icons.privacy_tip_outlined,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PrivacyPage()),
          );
        },
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final shouldExit = await _confirmExit(context);
        if (shouldExit && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("TemanAman"),
          actions: [
            IconButton(
              tooltip: "Reload user identity",
              onPressed: () async {
                await _loadUserKey();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("User identity reloaded")),
                );
              },
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadUserKey,
            child: LayoutBuilder(
              builder: (context, c) {
                final width = c.maxWidth;
                final crossAxisCount = width >= 520 ? 3 : 2;
                final childAspectRatio = crossAxisCount == 3 ? 1.20 : 1.12;

                return ListView(
                  padding: AppTokens.listPadding,
                  children: [
                    Text(
                      "Halo!",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppTokens.s6),
                    Text(
                      "Pilih fitur yang kamu butuhkan. Kamu bisa mulai dari Chat AI atau coba Kuis untuk level up.",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppTokens.s16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: AppTokens.s12,
                        mainAxisSpacing: AppTokens.s12,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemBuilder: (context, i) => _HomeCard(item: items[i]),
                    ),
                    if (kDebugMode) ...[
                      const SizedBox(height: AppTokens.s18),
                      _MiniInfoCard(
                        icon: Icons.fingerprint,
                        title: "UserKey (debug)",
                        value: userKey!,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  _HomeItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });
}

class _HomeCard extends StatelessWidget {
  final _HomeItem item;
  const _HomeCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final bg = item.isPrimary
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest;
    final fg = item.isPrimary ? scheme.onPrimaryContainer : scheme.onSurface;

    return Material(
      color: bg,
      borderRadius: AppTokens.radius(AppTokens.r20),
      child: InkWell(
        borderRadius: AppTokens.radius(AppTokens.r20),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.s14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBadge(
                icon: item.icon,
                foreground: fg,
                background: scheme.surface.withOpacity(
                  item.isPrimary ? 0.35 : 0.65,
                ),
              ),
              const Spacer(),
              Text(
                item.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: fg),
              ),
              const SizedBox(height: AppTokens.s6),
              Text(
                item.subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: (item.isPrimary ? fg : scheme.onSurfaceVariant)
                      .withOpacity(0.95),
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color foreground;
  final Color background;

  const _IconBadge({
    required this.icon,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppTokens.radius(AppTokens.r16),
      ),
      child: Icon(icon, size: 26, color: foreground),
    );
  }
}

class _MiniInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _MiniInfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s12),
        child: Row(
          children: [
            Icon(icon, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppTokens.s10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppTokens.s4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
