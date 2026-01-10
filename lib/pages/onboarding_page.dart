import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ui/app_tokens.dart';
import '../home_page.dart';

// =====================================================
// ONBOARDING PAGE
// =====================================================
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _index = 0;
  bool _isProcessing = false;

  static const _kFastAnim = Duration(milliseconds: 200);
  static const _kMediumAnim = Duration(milliseconds: 350);

  final List<_OnboardData> pages = const [
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
          "Aktifkan Safe Mode, tekan tombol Butuh Bantuan,\ndan hubungi orang terpercaya atau layanan darurat.",
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
    if (_isProcessing) return;
    _isProcessing = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
            Padding(
              padding: AppTokens.pagePadding,
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  duration: _kFastAnim,
                  opacity: isLast ? 0 : 1,
                  child: TextButton(
                    onPressed: isLast
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            _finish();
                          },
                    child: const Text("Lewati"),
                  ),
                ),
              ),
            ),

            // =====================
            // PAGE VIEW
            // =====================
            Expanded(
              child: PageView.builder(
                controller: _controller,
                physics: const BouncingScrollPhysics(),
                itemCount: pages.length,
                onPageChanged: (i) {
                  if (_index != i) {
                    setState(() => _index = i);
                  }
                },
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
                  duration: _kMediumAnim,
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _index == i ? 24 : 8,
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
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isProcessing
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          if (isLast) {
                            _finish();
                          } else {
                            _controller.nextPage(
                              duration: _kMediumAnim,
                              curve: Curves.easeOutCubic,
                            );
                          }
                        },
                  child: AnimatedSwitcher(
                    duration: _kFastAnim,
                    child: Text(
                      isLast ? "Mulai Pakai TemanAman" : "Lanjut",
                      key: ValueKey(isLast),
                    ),
                  ),
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

  _OnboardPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: AppTokens.pagePadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (_, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
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
                  height: 1.45,
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
