enum Role { user, assistant }

class ChatMessage {
  final Role role;
  String content;
  ChatMessage({required this.role, required this.content});
}
