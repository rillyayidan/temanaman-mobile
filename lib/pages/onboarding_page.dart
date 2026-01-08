import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ui/app_tokens.dart';
import '../home_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _index = 0;

  final pages = const [
    _OnboardData(
      title: "Kamu tidak sendirian 💜",
      description:
          "TemanAman hadir untuk menemani, memberi edukasi, dan membantu kamu menemukan dukungan dengan aman.",
      icon: Icons.favorite_rounded,
    ),
    _OnboardData(
      title: "Chat AI = Dukungan Awal",
      description:
          "Chat AI bersifat informatif dan suportif.\nBukan pengganti psikolog, dokter, atau layanan darurat.",
      icon: Icons.chat_bubble_rounded,
    ),
    _OnboardData(
      title: "Dalam kondisi terancam?",
      description:
          "Gunakan Safe Mode, tekan tombol Butuh Bantuan,\ndan hubungi orang terpercaya atau layanan darurat.",
      icon: Icons.shield_rounded,
    ),
    _OnboardData(
      title: "Privasi Kamu Penting",
      description:
          "Percakapan tidak disimpan permanen.\nData diproses seminimal mungkin demi keamananmu.",
      icon: Icons.lock_rounded,
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLast = _index == pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // =====================
            // SKIP BUTTON
            // =====================
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text("Lewati"),
              ),
            ),

            // =====================
            // PAGE VIEW
            // =====================
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _OnboardPage(data: pages[i]),
              ),
            ),

            // =====================
            // INDICATOR
            // =====================
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _index == i ? 22 : 8,
                  decoration: BoxDecoration(
                    color: _index == i
                        ? scheme.primary
                        : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppTokens.s16),

            // =====================
            // ACTION BUTTON
            // =====================
            Padding(
              padding: AppTokens.pagePadding,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (isLast) {
                      _finish();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Text(isLast ? "Mulai Pakai TemanAman" : "Lanjut"),
                ),
              ),
            ),

            const SizedBox(height: AppTokens.s20),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// SINGLE PAGE UI
// =====================================================
class _OnboardPage extends StatelessWidget {
  final _OnboardData data;
  const _OnboardPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: AppTokens.pagePadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTokens.s20),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              size: 56,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: AppTokens.s24),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppTokens.s12),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// DATA MODEL
// =====================================================
class _OnboardData {
  final String title;
  final String description;
  final IconData icon;

  const _OnboardData({
    required this.title,
    required this.description,
    required this.icon,
  });
}
