import 'package:flutter/material.dart';
import '../api/quiz_api.dart';
import '../ui/app_tokens.dart';

class QuizPlayPage extends StatefulWidget {
  const QuizPlayPage({
    super.key,
    required this.userKey,
    required this.attemptId,
    required this.levelName,
  });

  final String userKey;
  final int attemptId;
  final String levelName;

  @override
  State<QuizPlayPage> createState() => _QuizPlayPageState();
}

class _QuizPlayPageState extends State<QuizPlayPage> {
  final api = QuizApi();

  bool loading = true;
  String? error;

  QuizQuestionDto? q;
  int? selectedOptionId;

  bool answering = false;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    setState(() {
      loading = true;
      error = null;
      selectedOptionId = null;
    });

    try {
      final res = await api.nextQuestion(userKey: widget.userKey, attemptId: widget.attemptId);
      if (!mounted) return;
      setState(() {
        q = res;
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

  bool get _quizInProgress {
    // dianggap masih berjalan kalau belum finished dan bukan loading error state
    return q != null && q!.isFinished == false;
  }

  Future<bool> _confirmExit() async {
    // kalau belum ada soal, atau sudah selesai, bebas keluar tanpa warning
    if (!_quizInProgress) return true;

    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Keluar dari kuis?"),
        content: const Text(
          "Kalau kamu keluar sekarang, percobaan kuis ini akan ditutup dan tercatat di riwayat.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Lanjut kuis"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Keluar"),
          ),
        ],
      ),
    );

    return res == true;
  }

  Future<void> _exitQuiz() async {
    if (_exiting) return;

    final ok = await _confirmExit();
    if (!ok || !mounted) return;

    setState(() => _exiting = true);

    // ✅ tutup attempt di backend supaya status tidak nyangkut in_progress
    try {
      await api.finishAttempt(userKey: widget.userKey, attemptId: widget.attemptId);
    } catch (_) {
      // kalau gagal, tetap izinkan keluar (biar user tidak kejebak).
      // status mungkin masih in_progress, tapi setidaknya UX tidak rusak.
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _submit() async {
    if (q == null || q!.isFinished) return;

    if (selectedOptionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih jawaban dulu.")),
      );
      return;
    }

    setState(() => answering = true);

    try {
      final ans = await api.answer(
        userKey: widget.userKey,
        attemptId: widget.attemptId,
        selectedOptionId: selectedOptionId!,
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) => _AnswerResultDialog(
          isCorrect: ans.isCorrect,
          score: ans.score,
          explanation: ans.explanation,
          isFinished: ans.isFinished,
        ),
      );

      if (!mounted) return;

      if (ans.isFinished) {
        Navigator.pop(context);
        return;
      }

      await _loadQuestion();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => answering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = "Kuis • ${widget.levelName}";
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _exitQuiz();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _exitQuiz,
          ),
        ),
        body: SafeArea(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : (error != null)
                  ? _ErrorView(message: error!, onRetry: _loadQuestion)
                  : (q == null)
                      ? const _EmptyView(
                          title: "Tidak ada data soal",
                          message: "Coba refresh atau kembali ke halaman level.",
                          icon: Icons.help_outline,
                        )
                      : (q!.isFinished)
                          ? const _EmptyView(
                              title: "Kuis selesai",
                              message: "Kamu sudah menyelesaikan semua pertanyaan pada level ini.",
                              icon: Icons.verified_outlined,
                            )
                          : Padding(
                              padding: AppTokens.pagePadding,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _ProgressHeader(
                                    index: q!.index,
                                    total: q!.total,
                                  ),
                                  const SizedBox(height: AppTokens.s14),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(AppTokens.s16),
                                    decoration: BoxDecoration(
                                      color: scheme.surface,
                                      borderRadius: AppTokens.radius(AppTokens.r20),
                                      border: Border.all(color: scheme.outlineVariant.withOpacity(0.65)),
                                    ),
                                    child: Text(
                                      q!.questionText ?? "",
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1.35),
                                    ),
                                  ),
                                  const SizedBox(height: AppTokens.s14),
                                  Expanded(
                                    child: ListView.separated(
                                      itemCount: q!.options.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: AppTokens.s10),
                                      itemBuilder: (context, i) {
                                        final opt = q!.options[i];
                                        // ✅ Generate label A, B, C, D secara dinamis berdasarkan index
                                        final labels = ['A', 'B', 'C', 'D', 'E', 'F'];
                                        final label = i < labels.length ? labels[i] : '';
                                        final selected = selectedOptionId == opt.id;

                                        return _OptionCard(
                                          title: "$label. ${opt.text}",
                                          selected: selected,
                                          enabled: !answering,
                                          onTap: () => setState(() => selectedOptionId = opt.id),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: AppTokens.s12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: (answering || selectedOptionId == null) ? null : _submit,
                                      icon: answering
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Icon(Icons.check_circle_outline),
                                      label: Text(answering ? "Mengirim..." : "Jawab"),
                                    ),
                                  ),
                                ],
                              ),
                            ),
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int index;
  final int total;

  const _ProgressHeader({
    required this.index,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = total <= 0 ? 0.0 : (index / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Soal $index / $total",
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppTokens.s8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String title;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final bg = selected ? scheme.primaryContainer.withOpacity(0.65) : scheme.surface;
    final border = selected ? scheme.primary.withOpacity(0.55) : scheme.outlineVariant.withOpacity(0.65);

    return Material(
      color: bg,
      borderRadius: AppTokens.radius(AppTokens.r18),
      child: InkWell(
        borderRadius: AppTokens.radius(AppTokens.r18),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(AppTokens.s14),
          decoration: BoxDecoration(
            borderRadius: AppTokens.radius(AppTokens.r18),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppTokens.s10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.25),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerResultDialog extends StatelessWidget {
  final bool isCorrect;
  final int score;
  final String? explanation;
  final bool isFinished;

  const _AnswerResultDialog({
    required this.isCorrect,
    required this.score,
    required this.explanation,
    required this.isFinished,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = isCorrect ? "Benar ✅" : "Kurang tepat ❌";
    final subtitle = isCorrect
        ? "Jawabanmu tepat. Lanjutkan!"
        : "Tidak apa-apa. Baca pembahasan lalu lanjut.";

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppTokens.s12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTokens.s12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: AppTokens.radius(AppTokens.r16),
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_events_outlined, color: scheme.onSurfaceVariant),
                  const SizedBox(width: AppTokens.s10),
                  Text("Skor sementara: $score"),
                ],
              ),
            ),
            if ((explanation ?? "").trim().isNotEmpty) ...[
              const SizedBox(height: AppTokens.s14),
              Text("Pembahasan", style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppTokens.s6),
              Text(
                explanation!.trim(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(isFinished ? "Selesai" : "Lanjut"),
        ),
      ],
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
            Text("Gagal memuat soal", style: Theme.of(context).textTheme.titleMedium),
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