import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/AI/gemini.dart' as GeminiService;
import 'package:google_generative_ai/google_generative_ai.dart'; // Import for Content
import 'package:to_do_list/database/chatdata.dart';
import 'package:to_do_list/models/chat_model.dart';

class GeminiDialog extends ConsumerStatefulWidget {
  const GeminiDialog({super.key});

  @override
  ConsumerState<GeminiDialog> createState() => _GeminiDialogState();
}

class _GeminiDialogState extends ConsumerState<GeminiDialog> {
  final TextEditingController _controller = TextEditingController();
  final ChatData _chatData = ChatData();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Start a fresh chat session each time the dialog opens.
    _chatData.loadData();
    _chatData.startNewChat();
  }

  void _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      final messageText = _controller.text;
      _controller.clear();

      // Persist user message into short-term chat session and show loading.
      _chatData.addMessage(Chat(text: messageText, isUser: true));
      setState(() {
        _isLoading = true;
      });

      // Build an override history from the current session but exclude the
      // trailing user message (we'll send it separately to the model).
      final messages = _chatData.currentChatMessages;
      final List<Content> dialogChatHistory = [];
      for (int i = 0; i < messages.length - 1; i++) {
        final m = messages[i];
        dialogChatHistory.add(Content(m.isUser ? 'user' : 'model', [TextPart(m.text)]));
      }

      final response = await GeminiService.sendChatMessage(
        ref,
        messageText,
        chatHistoryOverride: dialogChatHistory,
      );

      // Persist assistant reply and update UI
      _chatData.addMessage(Chat(text: response, isUser: false));
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chat with Gemini'),
      content: SizedBox( // Use SizedBox to give AlertDialog a defined height
        width: MediaQuery.of(context).size.width * 0.8, // Adjust width as needed
        height: MediaQuery.of(context).size.height * 0.6, // Adjust height as needed
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _chatData.currentChatMessages.length,
                itemBuilder: (context, index) {
                  final message = _chatData.currentChatMessages[index];
                  return Align(
                    alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: message.isUser
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
                            : Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(
                            color: message.isUser
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSecondary),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: LinearProgressIndicator(),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Enter a prompt...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
