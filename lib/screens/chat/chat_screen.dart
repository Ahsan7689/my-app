import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:provider/provider.dart';
import '../../providers/chatbot_provider.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatbotProvider = Provider.of<ChatbotProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('StyleBot Assistant'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Chat(
        messages: chatbotProvider.messages,
        onSendPressed: chatbotProvider.sendMessage,
        user: const types.User(id: 'user'), // Placeholder for current user
        theme: DefaultChatTheme(
          primaryColor: Theme.of(context).primaryColor,
          secondaryColor: Colors.grey.shade200,
          inputBackgroundColor: Colors.white,
        ),
        isTyping: chatbotProvider.isTyping,
      ),
    );
  }
}
