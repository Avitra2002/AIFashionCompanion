// home.dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Chat')),
    );
  }
}

// set a rule that there needs to be at least 3 items of each category in the closet to use the feature --> meaningful results
// if there are less than 3 items, show a message to the user to add more
// if there are more than 3 items, show the AI chat feature