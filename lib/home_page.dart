import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/user_identity.dart';

import 'chat/chat_page.dart';
import 'pages/quiz_levels_page.dart';
import 'pages/education_categories_page.dart';
import 'pages/privacy_page.dart';
import 'pages/help_page.dart';

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
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadUserKey,
            child: ListView(
              padding: AppTokens.pagePadding,
              children: [
                // =========================
                // HERO AI SECTION
                // =========================
                Container(
                  padding: const EdgeInsets.all(AppTokens.s20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [scheme.primary, scheme.primaryContainer],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: AppTokens.radius(AppTokens.r24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Kamu nggak sendirian.",
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: scheme.onPrimary),
                      ),
                      const SizedBox(height: AppTokens.s8),
                      Text(
                        "TemanAman siap menemani kamu bicara, belajar, dan mencari bantuan dengan aman.",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onPrimary.withOpacity(0.9),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppTokens.s16),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.onPrimary,
                          foregroundColor: scheme.primary,
                        ),
                        icon: const Icon(Icons.chat_bubble_rounded),
                        label: const Text("Mulai Chat AI"),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatPage(userKey: userKey!),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
 
                const SizedBox(height: AppTokens.s24),

                // =========================
                // QUICK ACTIONS
                // =========================
                Text(
                  "Fitur lainnya",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppTokens.s12),

                _ActionTile(
                  icon: Icons.menu_book_rounded,
                  title: "Edukasi",
                  subtitle: "Materi pencegahan & perlindungan diri",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EducationCategoriesPage(),
                      ),
                    );
                  },
                ),
                _ActionTile(
                  icon: Icons.quiz_rounded,
                  title: "Kuis",
                  subtitle: "Uji pemahaman dan tingkatkan kesadaran",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizLevelsPage(userKey: userKey!),
                      ),
                    );
                  },
                ),
                _ActionTile(
                  icon: Icons.support_agent_rounded,
                  title: "Layanan Bantuan",
                  subtitle: "Kontak bantuan terpercaya & darurat",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HelpPage()),
                    );
                  },
                ),
                _ActionTile(
                  icon: Icons.privacy_tip_rounded,
                  title: "Privasi & Ketentuan",
                  subtitle: "Kebijakan, disclaimer AI, dan penggunaan",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrivacyPage()),
                    );
                  },
                ),

                if (kDebugMode) ...[
                  const SizedBox(height: AppTokens.s24),
                  _DebugInfoCard(userKey: userKey!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// ACTION TILE
// =====================================================
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s12),
      child: Material(
        color: scheme.surface,
        borderRadius: AppTokens.radius(AppTokens.r20),
        child: InkWell(
          borderRadius: AppTokens.radius(AppTokens.r20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.s16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTokens.s10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: AppTokens.radius(AppTokens.r14),
                  ),
                  child: Icon(icon, color: scheme.primary),
                ),
                const SizedBox(width: AppTokens.s14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// DEBUG CARD
// =====================================================
class _DebugInfoCard extends StatelessWidget {
  final String userKey;
  const _DebugInfoCard({required this.userKey});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s12),
        child: Row(
          children: [
            Icon(Icons.fingerprint, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppTokens.s10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "UserKey (debug)",
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppTokens.s4),
                  Text(
                    userKey,
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
