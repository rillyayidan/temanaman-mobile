import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/teman_aman_api.dart';
import 'chat_room_controller.dart';
import 'chat_message.dart';
import '../ui/app_tokens.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.userKey});

  final String userKey;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  ChatRoomController? ctrl;

  final _input = TextEditingController();
  final _scroll = ScrollController();

  bool initializing = true;

  // auto-scroll hanya kalau user dekat bawah
  bool _stickToBottom = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _initRoom();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    final distanceToBottom = pos.maxScrollExtent - pos.pixels;
    _stickToBottom = distanceToBottom < 140;
  }

  Future<void> _initRoom() async {
    final controller = ChatRoomController(
      api: TemanAmanApi(),
      userId: widget.userKey,
    );

    controller.addListener(_onControllerChanged);

    setState(() {
      ctrl = controller;
      initializing = true;
    });

    await controller.initRoom();

    if (!mounted) return;
    setState(() => initializing = false);

    _jumpToBottom();
  }

  void _onControllerChanged() {
    // Update UI
    if (mounted) setState(() {});

    // Smooth scroll hanya kalau user memang sedang di bawah.
    if (_stickToBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animateToBottom();
      });
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  void _animateToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    ctrl?.removeListener(_onControllerChanged);
    ctrl?.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<bool> _confirmExit() async {
    if (ctrl == null || ctrl!.roomId == null) return true;

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Keluar dari chat?"),
        content: const Text(
          "Jika kamu keluar, riwayat chat akan dihapus dan tidak bisa dikembalikan.",
        ),
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

    if (shouldExit == true) {
      await ctrl!.endRoom();
      return true;
    }
    return false;
  }

  Future<void> _exit() async {
    final ok = await _confirmExit();
    if (!mounted) return;
    if (ok) Navigator.pop(context);
  }

  Future<void> _send() async {
    final c = ctrl;
    if (c == null) return;

    final text = _input.text.trim();
    if (text.isEmpty) return;

    _stickToBottom = true;

    _input.clear();
    await c.sendStream(text);
  }

  @override
  Widget build(BuildContext context) {
    if (initializing || ctrl == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("TemanAman Chat")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final c = ctrl!;
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _exit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("TemanAman Chat"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _exit,
          ),
          actions: [
            IconButton(
              tooltip: "Butuh bantuan",
              icon: const Icon(Icons.support_agent),
              onPressed: () => _QuickHelpButton.show(context),
            ),
          ],
        ),
        body: Column(
          children: [
            if (c.ended)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s16,
                  vertical: AppTokens.s10,
                ),
                color: scheme.errorContainer.withOpacity(0.55),
                child: Text(
                  "Chat sudah berakhir. Kamu tidak bisa mengirim pesan lagi.",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onErrorContainer,
                  ),
                ),
              ),
            Expanded(
              child: _MessagesList(
                messages: c.messages,
                scroll: _scroll,
                loading: c.loading,
              ),
            ),
            _Composer(
              controller: _input,
              enabled: !c.ended,
              busy: c.loading, // saat streaming, kita anggap sedang sibuk
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagesList extends StatelessWidget {
  final List<ChatMessage> messages;
  final ScrollController scroll;
  final bool loading;

  const _MessagesList({
    required this.messages,
    required this.scroll,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 34,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppTokens.s12),
              Text(
                "Mulai obrolan…",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppTokens.s6),
              Text(
                "Ceritakan yang kamu rasakan. TemanAman akan merespons dengan aman dan suportif.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final lastIsEmptyAssistant =
        messages.isNotEmpty &&
        messages.last.role == Role.assistant &&
        messages.last.content.trim().isEmpty;

    // Tampilkan typing bubble hanya kalau tidak sedang ada placeholder assistant kosong.
    // (Kalau placeholder kosong sudah ada, bubble itu sendiri yang jadi indikator “sedang mengetik”.)
    final showTypingBubble = loading && !lastIsEmptyAssistant;

    final itemCount = messages.length + (showTypingBubble ? 1 : 0);

    return ListView.separated(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (showTypingBubble && i == itemCount - 1) {
          return const Align(
            alignment: Alignment.centerLeft,
            child: _TypingBubble(),
          );
        }

        final m = messages[i];
        final isUser = m.role == Role.user;

        return RepaintBoundary(
          child: _ChatBubble(message: m.content, isUser: isUser),
        );
      },
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const _ChatBubble({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final bg = isUser
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest;
    final fg = isUser ? scheme.onPrimaryContainer : scheme.onSurface;
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(AppTokens.r18),
      topRight: const Radius.circular(AppTokens.r18),
      bottomLeft: Radius.circular(isUser ? AppTokens.r18 : AppTokens.r6),
      bottomRight: Radius.circular(isUser ? AppTokens.r6 : AppTokens.r18),
    );

    final maxWidth = MediaQuery.of(context).size.width * 0.78;
    final hardCap = AppTokens.maxChatBubbleWidth;
    final bubbleMax = maxWidth > hardCap ? hardCap : maxWidth;

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: bubbleMax),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: bg, borderRadius: radius),
          child: isUser
              ? Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: fg, height: 1.32),
                )
              : MarkdownBody(
                  data: message,
                  selectable: true, // ⬅️ nanti kita jelaskan
                  onTapLink: (text, href, title) async {
                    if (href == null) return;

                    final uri = Uri.tryParse(href);
                    if (uri == null) return;

                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode
                            .externalApplication, // ⬅️ buka Chrome / browser
                      );
                    }
                  },
                  styleSheet: MarkdownStyleSheet(
                    p: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: fg, height: 1.32),
                    a: TextStyle(
                      color: scheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                    strong: TextStyle(fontWeight: FontWeight.w600, color: fg),
                    em: TextStyle(fontStyle: FontStyle.italic, color: fg),
                    blockquote: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: fg, height: 1.32),
                    blockquotePadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    blockquoteDecoration: BoxDecoration(
                      color: scheme.surface.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: BorderSide(color: scheme.primary, width: 3),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTokens.r18),
      ),
      child: const _TypingDots(),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool busy;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.enabled,
    required this.busy,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final canSend = enabled && !busy;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            top: BorderSide(color: scheme.outlineVariant.withOpacity(0.7)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => canSend ? onSend() : null,
                decoration: InputDecoration(
                  hintText: enabled ? "Tulis pesan…" : "Chat sudah berakhir",
                  prefixIcon: const Icon(Icons.edit_outlined),
                ),
              ),
            ),
            const SizedBox(width: AppTokens.s8),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: canSend ? onSend : null,
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;

        double dot(double shift) {
          final x = (t + shift) % 1.0;
          return 0.25 + 0.75 * (1 - (2 * (x - 0.5)).abs());
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(opacity: dot(0.0), color: scheme.onSurfaceVariant),
            const SizedBox(width: 4),
            _Dot(opacity: dot(0.2), color: scheme.onSurfaceVariant),
            const SizedBox(width: 4),
            _Dot(opacity: dot(0.4), color: scheme.onSurfaceVariant),
          ],
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  final double opacity;
  final Color color;

  const _Dot({required this.opacity, required this.color});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.15, 1.0),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _QuickHelpButton {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Butuh bantuan sekarang?",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                "Kamu bisa menghubungi layanan resmi berikut:",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              _HelpAction(
                icon: Icons.phone,
                label: "Hotline KemenPPPA",
                value: "129",
                uri: "tel:129",
              ),
              _HelpAction(
                icon: Icons.chat,
                label: "SAPA 129 WhatsApp",
                value: "+62 811-1129-129",
                uri: "https://wa.me/628111129129",
              ),
              _HelpAction(
                icon: Icons.public,
                label: "Website Resmi",
                value: "kemenpppa.go.id",
                uri: "https://www.kemenpppa.go.id",
              ),

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class _HelpAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String uri;

  const _HelpAction({
    required this.icon,
    required this.label,
    required this.value,
    required this.uri,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
      onTap: () async {
        final parsed = Uri.parse(uri);
        await launchUrl(parsed, mode: LaunchMode.externalApplication);
      },
    );
  }
}
