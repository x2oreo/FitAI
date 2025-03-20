import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat', style: theme.textTheme.headlineLarge),
      ),
      body: const Center(
        child: Text(
          'Welcome to the Chat Page!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}