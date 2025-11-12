import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';

import 'cart_provider.dart';
import 'product_provider.dart';
import 'wishlist_provider.dart';

class ChatbotProvider with ChangeNotifier {
  // Providers
  final ProductProvider _productProvider;
  final WishlistProvider _wishlistProvider;
  final CartProvider _cartProvider;

  // Gemini Model
  final GenerativeModel _model;
  ChatSession? _chatSession;

  // Chat state
  final List<types.Message> _messages = [];
  final types.User _chatbotUser = const types.User(id: 'gemini-bot', firstName: 'Style', lastName: 'Bot');
  bool _isTyping = false;

  // Getters
  List<types.Message> get messages => _messages;
  bool get isTyping => _isTyping;

  ChatbotProvider(
      this._productProvider, this._wishlistProvider, this._cartProvider) : 
      // IMPORTANT: Use a model that supports system instructions, like flash or pro
      _model = FirebaseVertexAI.instance.generativeModel(
              model: 'gemini-1.5-flash-preview-0514',
              // Do not hardcode API keys. This is handled securely by the SDK.
            ) {
    _initializeChat();
  }

  void _initializeChat() {
    // This system instruction is the key to "training" the bot.
    // It's rebuilt every time to ensure the bot has the latest context.
    final systemInstruction = _buildSystemPrompt();
    _chatSession = _model.startChat(
      history: [],
      systemInstruction: Content.system(systemInstruction),
    );
    _addMessage(types.TextMessage(      
      author: _chatbotUser,
      id: const Uuid().v4(),
      text: 'Hi! I am StyleBot. I can help you find products, check your cart, and manage your wishlist. How can I help you today?',
    ));
  }

  Future<void> sendMessage(types.PartialText partialMessage) async {
    final userMessage = types.TextMessage(
      author: const types.User(id: 'user'), // A placeholder for the current user
      id: const Uuid().v4(),
      text: partialMessage.text,
    );
    
    _addMessage(userMessage);
    _isTyping = true;
    notifyListeners();

    try {
      // Re-build the system prompt just before sending the message
      // This ensures the bot has the absolute latest info (e.g., if a user adds to cart in another screen)
      final systemInstruction = _buildSystemPrompt();
      // This is a simplified approach. A more robust solution might involve
      // re-starting the chat session if the system prompt has significantly changed.
      _chatSession?.systemInstruction = Content.system(systemInstruction);
      
      final response = await _chatSession?.sendMessage(Content.text(partialMessage.text));
      final botResponseText = response?.text ?? "I'm sorry, I couldn't understand that.";

      final botMessage = types.TextMessage(
        author: _chatbotUser,
        id: const Uuid().v4(),
        text: botResponseText,
      );
      _addMessage(botMessage);

    } catch (e) {
      final errorMessage = types.TextMessage(
        author: _chatbotUser,
        id: const Uuid().v4(),
        text: "Sorry, I'm having trouble connecting. Please try again later.",
      );
      _addMessage(errorMessage);
       print("Error sending message to Gemini: $e");
    } finally {
       _isTyping = false;
       notifyListeners();
    }
  }

  void _addMessage(types.Message message) {
    _messages.insert(0, message);
    notifyListeners();
  }

  String _buildSystemPrompt() {
    final products = _productProvider.products;
    final wishlistIds = _wishlistProvider.productIds;
    final cartItems = _cartProvider.items;
    
    // Get full product models for items in wishlist and cart
    final wishlistProducts = _productProvider.getProductsByIds(wishlistIds);
    final cartProducts = _productProvider.getProductsByIds(cartItems.map((item) => item.productId).toList());

    // Create readable lists of products
    final allProductNames = products.map((p) => '* ${p.name} (ID: ${p.id})').join('\n');
    final wishlistNames = wishlistProducts.map((p) => '* ${p.name} (ID: ${p.id})').join('\n');
    final cartDetails = cartProducts.map((p) {
      final item = cartItems.firstWhere((i) => i.productId == p.id);
      return '* ${p.name} (ID: ${p.id}), Quantity: ${item.quantity}';
    }).join('\n');

    // This is the core "training" for the bot. It gives it context.
    return '''
    You are StyleBot, a friendly and helpful shopping assistant for an e-commerce app.
    Your goal is to help the user find products and manage their account.
    Do not answer questions that are not related to a shopping assistant's role.
    
    You have access to the following real-time information from the app:

    --- START OF AVAILABLE PRODUCTS ---
    Here is a list of all available products:
    $allProductNames
    --- END OF AVAILABLE PRODUCTS ---

    --- START OF USER'S WISHLIST ---
    The user has the following items in their wishlist:
    $wishlistNames
    --- END OF USER'S WISHLIST ---

    --- START OF USER'S CART ---
    The user has the following items in their shopping cart:
    $cartDetails
    --- END OF USER'S CART ---

    Based on this information, answer the user's questions. 
    Be conversational and helpful. If you mention a product, always refer to it by its name.
    For example, if the user asks "what is in my cart?", you should list the names of the products.
    ''';
  }
}
