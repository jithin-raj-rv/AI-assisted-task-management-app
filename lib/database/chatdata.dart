import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do_list/models/chat_model.dart';
import 'package:uuid/uuid.dart';
import 'dart:collection';
import 'package:intl/intl.dart';

class ChatData {
  // Currently active chat session messages
  List<Chat> currentChatMessages = [];

  // All chat sessions stored as a map of sessionId to a list of messages
  LinkedHashMap<String, List<Chat>> _allChatSessions = LinkedHashMap();

  // Titles for each chat session
  LinkedHashMap<String, String> _chatSessionTitles = LinkedHashMap();

  // ID of the currently active chat session
  String? _currentChatSessionId;

  final _mybox = Hive.box('boxx');
  final Uuid _uuid = const Uuid();

  // Initialize data or load from Hive
  void loadData() {
    // Load all chat sessions
    final rawSessions = _mybox.get("ALL_CHAT_SESSIONS") as Map? ?? {};
    _allChatSessions = LinkedHashMap<String, List<Chat>>.fromEntries(
      rawSessions.entries.map((e) => MapEntry(
        e.key as String,
        (e.value as List).map((item) => Chat.fromHiveList(item as List<dynamic>)).toList(),
      )),
    );

    // Load chat session titles
    final rawTitles = _mybox.get("CHAT_SESSION_TITLES") as Map? ?? {};
    _chatSessionTitles = LinkedHashMap<String, String>.fromEntries(
      rawTitles.entries.map((e) => MapEntry(e.key as String, e.value as String)),
    );

    // Load current chat session ID
    _currentChatSessionId = _mybox.get("CURRENT_CHAT_SESSION_ID") as String?;

    // If no current session or no sessions at all, create a new one
    if (_currentChatSessionId == null || !_allChatSessions.containsKey(_currentChatSessionId)) {
      startNewChat();
    } else {
      currentChatMessages = _allChatSessions[_currentChatSessionId] ?? [];
    }
  }

  // Update data to Hive
  void updateData() {
    _mybox.put("ALL_CHAT_SESSIONS", _allChatSessions.map((key, value) => MapEntry(
      key, value.map((chat) => chat.toHiveList()).toList(),
    )));
    _mybox.put("CHAT_SESSION_TITLES", _chatSessionTitles);
    _mybox.put("CURRENT_CHAT_SESSION_ID", _currentChatSessionId);
  }

  // Start a new chat session
  void startNewChat() {
    _currentChatSessionId = _uuid.v4();
    currentChatMessages = [];
    _allChatSessions[_currentChatSessionId!] = currentChatMessages;
    _chatSessionTitles[_currentChatSessionId!] = "New Chat ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}";
    updateData();
  }

  // Load an existing chat session by its ID
  void loadChat(String sessionId) {
    if (_allChatSessions.containsKey(sessionId)) {
      _currentChatSessionId = sessionId;
      currentChatMessages = _allChatSessions[sessionId]!;
      updateData();
    }
  }

  // Delete a chat session by its ID
  void deleteChat(String sessionId) {
    _allChatSessions.remove(sessionId);
    _chatSessionTitles.remove(sessionId);
    if (_currentChatSessionId == sessionId) {
      startNewChat(); // Start a new chat if the current one was deleted
    } else {
      updateData();
    }
  }

  // Update the title of the current chat session
  void updateCurrentChatTitle(String newTitle) {
    if (_currentChatSessionId != null) {
      _chatSessionTitles[_currentChatSessionId!] = newTitle;
      updateData();
    }
  }

  // Get current chat session ID
  String? getCurrentChatSessionId() => _currentChatSessionId;

  // Get a list of all chat session summaries (id and title)
  List<Map<String, String>> getAllChatSessionSummaries() {
    return _chatSessionTitles.entries
        .map((entry) => {'id': entry.key, 'title': entry.value})
        .toList();
  }

  // Get the title of a specific chat session
  String? getChatSessionTitle(String sessionId) {
    return _chatSessionTitles[sessionId];
  }

  // Add a message to the current chat session
  void addMessage(Chat message) {
    currentChatMessages.add(message);
    // Also update in the _allChatSessions map
    if (_currentChatSessionId != null) {
      _allChatSessions[_currentChatSessionId!] = currentChatMessages;
    }
    updateData();
  }
}