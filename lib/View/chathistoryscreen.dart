import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/database/chatdata.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/util/icongradient.dart';
import 'package:to_do_list/util/smalltextgradient.dart';
import 'package:to_do_list/util/tittlegradient.dart';


class ChatHistoryScreen extends ConsumerStatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  ConsumerState<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends ConsumerState<ChatHistoryScreen> {
  final ChatData _chatData = ChatData();

  @override
  void initState() {
    super.initState();
    _chatData.loadData(); // Ensure chat data is loaded
  }

  void _loadChatSession(String sessionId) {
    _chatData.loadChat(sessionId);
    Navigator.pop(context); // Pop ChatHistoryScreen
    // No need to push ChatScreen again if it's already in the navigation stack.
    // We just need to trigger a rebuild of ChatScreen.
    // A simple setState in ChatScreen might be needed, or manage state with Riverpod.
    // For now, simply popping and assuming ChatScreen rebuilds is okay.
  }

  void _deleteChatSession(String sessionId) {
    setState(() {
      _chatData.deleteChat(sessionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(themeProvider);
    final chatSessions = _chatData.getAllChatSessionSummaries();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appTheme.background,
        title: Tittlegradient(text: 'Chat History'),
      ),
      body: chatSessions.isEmpty
          ? Center(
              child: Text(
                'No chat sessions yet. Start a new chat!',
                style: TextStyle(color: Colors.red),
              ),
            )
          : ListView.builder(
              itemCount: chatSessions.length,
              itemBuilder: (context, index) {
                final session = chatSessions[index];
                final isCurrent = session['id'] == _chatData.getCurrentChatSessionId();
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: appTheme.background,
                  child: ListTile(
                    title: Smalltextgradient(
                      text:session['title']!,
                      fontsize: 18,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: Icongradient(icon:Icons.delete,),
                      onPressed: () => _deleteChatSession(session['id']!),
                    ),
                    onTap: () {
                      _loadChatSession(session['id']!);
                    },
                  ),
                );
              },
            ),
    );
  }
}
