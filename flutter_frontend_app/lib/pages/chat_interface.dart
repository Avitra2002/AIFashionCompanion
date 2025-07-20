import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_frontend_app/model/chat_message.dart';
import 'package:flutter_frontend_app/pages/lookDetail.dart';
import 'package:flutter_frontend_app/services/api.dart';

class ChatInterface extends StatefulWidget {
  const ChatInterface({super.key});

  @override
  State<ChatInterface> createState() => _ChatInterfaceState();
}

class _ChatInterfaceState extends State<ChatInterface> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;


  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, sender: Sender.user));
      _controller.clear();
      _isSending = true;
    });

    try {
      final looks = await ApiService.chatWithAI(text);
      for (final look in looks) {
        _messages.add(ChatMessage(look: look, sender: Sender.ai));
      }
    } catch (e) {
      _messages.add(ChatMessage(
        text: "❌ Error: ${e.toString()}",
        sender: Sender.ai,
      ));
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  // Widget _buildLookBubble(Map<String, dynamic> look) {
  //   final base64Str = look["collage_base64"].toString().split(',').last;
  //   final imageBytes = base64Decode(base64Str);

  //   // TODO: Add Gesture to handle when user taps on the look, go to LookDetailPage
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Image.memory(imageBytes),
  //       const SizedBox(height: 8),
  //       Text(
  //         look['look_name'] ?? '',
  //         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //       ),
  //       const SizedBox(height: 4),
  //       Text(look['description'] ?? ''),
  //       const SizedBox(height: 8),
  //       ElevatedButton(
  //         onPressed: () async {
  //           final success = await ApiService.saveLook(look);
  //           final lookName = look['look_name'] ?? 'this look';

  //           final message = success
  //               ? '✅ Successfully saved $lookName!'
  //               : '❌ Failed to save $lookName.';
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             SnackBar(content: Text(message)),
  //           );
             
  //         },
  //         child: const Text("Save Look"),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildLookBubble(Map<String, dynamic> look) {
    final base64Str = look["collage_base64"].toString().split(',').last;
    final imageBytes = base64Decode(base64Str);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LookDetailPage(look: look),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.memory(imageBytes),
          const SizedBox(height: 8),
          Text(
            look['look_name'] ?? '',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(look['description'] ?? ''),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              final success = await ApiService.saveLook(look);
              final lookName = look['look_name'] ?? 'this look';

              final message = success
                  ? '✅ Successfully saved $lookName!'
                  : '❌ Failed to save $lookName.';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            },
            child: const Text("Save Look"),
          ),
        ],
      ),
    );
  }




  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isUser = msg.sender == Sender.user;

              return Align(
                alignment:
                    isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(maxWidth: 320),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Colors.blueAccent
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: msg.look != null
                      ? _buildLookBubble(msg.look!)
                      : Text(
                          msg.text ?? '',
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black87,
                          ),
                        ),
                ),
              );
            },
          ),
        ),
        if (_isSending)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: CircularProgressIndicator(),
          ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "Type in an ocassion you want to dress for...",
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _isSending ? null : _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }

}
