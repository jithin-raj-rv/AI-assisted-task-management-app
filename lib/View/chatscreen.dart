// lib/View/chatscreen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/services/supabase_gemini_service.dart';
import 'package:to_do_list/database/chatdata.dart';
import 'package:to_do_list/models/chat_model.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/View/chathistoryscreen.dart'; // Import the new chat history screen
import 'package:to_do_list/providers.dart';
import 'package:to_do_list/util/chatbubble.dart';
import 'package:to_do_list/util/icongradient.dart';
import 'package:to_do_list/util/tittlegradient.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? initialPrompt;
  const ChatScreen({super.key, this.initialPrompt});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ChatData _chatData = ChatData(); // Instantiate ChatData
  bool _isLoading = false;
  bool _initialPromptProcessed = false; // Flag to prevent duplicate processing
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _chatData.loadData(); // Load chat data when the screen initializes

    // If an initial prompt is provided (from onboarding), start a new chat and send it only once
    if (widget.initialPrompt != null && !_initialPromptProcessed) {
      _initialPromptProcessed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startNewChat();
        _sendMessage(customText: widget.initialPrompt);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage({String? customText}) async {
    if (customText != null || _controller.text.isNotEmpty) {
      final messageText = customText ?? _controller.text;
      if (customText == null) _controller.clear();

      // If it's a new chat, try to set the title from the first message
      if (_chatData.currentChatMessages.isEmpty && _chatData.getCurrentChatSessionId() != null) {
        // Check if the current title is the default "New Chat..."
        final currentTitle = _chatData.getChatSessionTitle(_chatData.getCurrentChatSessionId()!);
        if (currentTitle != null && currentTitle.startsWith("New Chat ")) {
          _chatData.updateCurrentChatTitle(messageText.split(' ').take(3).join(' ') + '...');
        }
      }

      // Get relevant chat history (last 5 messages for context)
      // Include system prompt as first message if this is the first message
      final relevantHistory = _chatData.currentChatMessages.length > 5
          ? _chatData.currentChatMessages.skip(_chatData.currentChatMessages.length - 5).toList()
          : _chatData.currentChatMessages;

      // For the first message, we need to ensure system prompt is included in history
      // The backend will handle adding the system prompt to the conversation

      setState(() {
        _chatData.addMessage(Chat(text: messageText, isUser: true));
        _isLoading = true;
      });
      
      _scrollToBottom();

      try {
        // Get current user ID from Riverpod
        final user = ref.read(currentUserProvider);
        if (user == null) {
          throw Exception('User not authenticated');
        }

        final response = await SupabaseGeminiService.sendChatMessage(
          user.id,
          messageText,
          chatHistory: relevantHistory, // Pass chat history
        );

        setState(() {
          _chatData.addMessage(Chat(text: response, isUser: false));
          _isLoading = false;
        });
        
        _scrollToBottom();
      } catch (e) {
        String errorMessage = e.toString();

        // Use the service's error message directly - it's already user-friendly
        if (errorMessage.contains('Error: ')) {
          errorMessage = errorMessage.substring(7); // Remove 'Error: ' prefix
        }

        setState(() {
          _chatData.addMessage(Chat(text: errorMessage, isUser: false));
          _isLoading = false;
        });
        
        _scrollToBottom();

        // Show toast notification for critical errors
        if (errorMessage.contains('sign in') || errorMessage.contains('session')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please sign in again to continue chatting')),
          );
        }
      }
    }
  }

  void _startNewChat() {
    setState(() {
      _chatData.startNewChat();
    });
  }

  void _navigateToChatHistory() async {
    // We expect ChatHistoryScreen to pop itself when a session is selected
    // or when the back button is pressed.
    // If a session is loaded from history, ChatScreen needs to rebuild.
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatHistoryScreen()),
    );
    // After returning from ChatHistoryScreen, force a rebuild to show the potentially
    // new current chat session's messages.
    setState(() {
      _chatData.loadData(); // Reload data to ensure currentChatMessages is updated
    });
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(themeProvider);
    // Get the current chat session ID
    final currentSessionId = _chatData.getCurrentChatSessionId();
    // Get the current chat session title, defaulting to 'New Chat'
    final String currentTitle = currentSessionId != null
        ? _chatData.getChatSessionTitle(currentSessionId) ?? 'New Chat'
        : 'New Chat';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appTheme.background,
        title: Tittlegradient(
          text: currentTitle,
        ),
        actions: [
          IconButton(
            icon: const Icongradient(icon:Icons.add_comment), // Icon for new chat
            onPressed: _startNewChat,
            tooltip: 'New Chat',
          ),
          IconButton(
            icon: const Icongradient(icon:Icons.history), // Icon for chat history
            onPressed: _navigateToChatHistory,
            tooltip: 'Chat History',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              appTheme.background,
              appTheme.primary.withOpacity(0.1),
              appTheme.secondary.withOpacity(0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _chatData.currentChatMessages.length,
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemBuilder: (context, index) {
                  final message = _chatData.currentChatMessages[index];
                  return ChatMessageBubble(
                    text: message.text,
                    isUser: message.isUser,
                    useGradient: true,
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  );
                },
              ),
            ),
            if (_isLoading)
              ChatLoadingIndicator(),
            ChatInputField(
              controller: _controller,
              hintText: 'Type a message...',
              onSubmit: () => _sendMessage(),
              onSend: () => _sendMessage(),
            ),
          ],
        ),
      ),
    );
  }
}
