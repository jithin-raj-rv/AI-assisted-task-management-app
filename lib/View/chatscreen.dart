// lib/View/chatscreen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/services/supabase_gemini_service.dart';
import 'package:to_do_list/database/chatdata.dart';
import 'package:to_do_list/models/chat_model.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/View/chathistoryscreen.dart'; // Import the new chat history screen
import 'package:to_do_list/providers.dart';

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

  @override
  void initState() {
    super.initState();
    _chatData.loadData(); // Load chat data when the screen initializes

    // If an initial prompt is provided (from a notification), start a new chat and send it
    if (widget.initialPrompt != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startNewChat();
        _sendMessage(customText: widget.initialPrompt);
      });
    }
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

      setState(() {
        _chatData.addMessage(Chat(text: messageText, isUser: true));
        _isLoading = true;
      });

      try {
        // Get current user ID from Riverpod
        final user = ref.read(currentUserProvider);
        if (user == null) {
          throw Exception('User not authenticated');
        }

        final response = await SupabaseGeminiService.sendChatMessage(user.id, messageText);

        setState(() {
          _chatData.addMessage(Chat(text: response, isUser: false));
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _chatData.addMessage(Chat(text: 'Error: $e', isUser: false));
          _isLoading = false;
        });
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
        title: Text(
          currentTitle,
          style: TextStyle(
              fontSize: 25.0,
              fontWeight: FontWeight.bold,
              color: appTheme.primaryGradient1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment), // Icon for new chat
            onPressed: _startNewChat,
            tooltip: 'New Chat',
          ),
          IconButton(
            icon: const Icon(Icons.history), // Icon for chat history
            onPressed: _navigateToChatHistory,
            tooltip: 'Chat History',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _chatData.currentChatMessages.length,
              itemBuilder: (context, index) {
                final message = _chatData.currentChatMessages[index];
                return ListTile(
                  title: Align(
                    alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: message.isUser
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(message.text, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onSubmitted: (value) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
