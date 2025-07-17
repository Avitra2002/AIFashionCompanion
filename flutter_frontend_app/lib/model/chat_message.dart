enum Sender { user, ai }

class ChatMessage {
  final String? text;
  final Map<String, dynamic>? look;
  final Sender sender;

  ChatMessage({
    this.text,
    this.look,
    required this.sender,
  });
}
