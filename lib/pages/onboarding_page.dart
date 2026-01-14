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

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final PageController _controller = PageController();
  int _index = 0;
  bool _isProcessing = false;

  static const _kFastAnim = Duration(milliseconds: 200);
  static const _kMediumAnim = Duration(milliseconds: 350);

  late final AnimationController _bgAnimController;
  late final Animation<double> _bgAnim;

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

  @override
  void initState() {
    super.initState();

    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _bgAnim = CurvedAnimation(
      parent: _bgAnimController,
      curve: Curves.easeInOut,
    );
  }

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
    _bgAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLast = _index == pages.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          // =====================================================
          // BACKGROUND GRADIENT (DECORATIVE)
          // =====================================================
          AnimatedBuilder(
            animation: _bgAnim,
            builder: (_, __) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primaryContainer.withOpacity(0.25),
                      scheme.surface,
                      scheme.secondaryContainer.withOpacity(0.25),
                    ],
                    stops: [
                      0,
                      0.5 + (_bgAnim.value * 0.1),
                      1,
                    ],
                  ),
                ),
              );
            },
          ),

          // =====================================================
          // DECORATIVE BLOBS (PURE UI)
          // =====================================================
          const _DecorativeBlobs(),

          // =====================================================
          // MAIN CONTENT
          // =====================================================
          SafeArea(
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
                    itemBuilder: (_, i) => AnimatedSlide(
                      duration: _kMediumAnim,
                      offset: Offset(i == _index ? 0 : 0.02, 0),
                      child: AnimatedOpacity(
                        duration: _kMediumAnim,
                        opacity: i == _index ? 1 : 0.4,
                        child: _OnboardPage(data: pages[i]),
                      ),
                    ),
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

                // =====================
                // FOOTER TEXT (SUBTLE)
                // =====================
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.s12),
                  child: Text(
                    "TemanAman • Ruang aman digital",
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
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
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withOpacity(0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
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
// DECORATIVE BLOBS WIDGET (UI ONLY)
// =====================================================
class _DecorativeBlobs extends StatelessWidget {
  const _DecorativeBlobs();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -80,
            child: _Blob(color: scheme.primary.withOpacity(0.15), size: 220),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child:
                _Blob(color: scheme.secondary.withOpacity(0.12), size: 260),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;

  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
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
