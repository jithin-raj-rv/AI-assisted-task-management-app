import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_list/models/chat_model.dart';

class SupabaseGeminiService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  // Base URL for the weather agent endpoint. The example curl uses localhost
  // on port 4111. Adjust if the server runs elsewhere (e.g., on an Android
  // emulator use 10.0.2.2).
  static const String _weatherAgentUrl = 'https://chappu-man-isawsommm.loca.lt/api/agents/weatherAgent/generate';

  static Future<void> _ensureValidSession() async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw Exception('No active session');
    }

    try {
      final refreshed = await _supabase.auth.refreshSession();
      if (refreshed.session == null) {
        throw Exception('Session refresh failed - no session returned');
      }
    } catch (e) {
      print('[GeminiService] Session refresh failed: $e');
      throw Exception('Session expired. Please sign in again.');
    }
  }

  static Future<String> sendChatMessage(
    String userId,
    String message, {
    List<Chat>? chatHistory,
    int maxRetries = 5,
  }) async {
    int attempt = 0;
    int retryDelay = 1000;

    while (attempt <= maxRetries) {
      try {
        if (attempt == 0) {
          await _ensureValidSession();
        }

        final user = await _supabase.auth.getUser();
        if (user.user == null) {
          throw Exception('User not authenticated');
        }

        final history = chatHistory?.map((chat) {
          return {'role': chat.isUser ? 'user' : 'model', 'content': chat.text};
        }).toList();

        // Send request to Mastra server's chat endpoint.
        final List<Map<String, String>> messages = [];
        if (history != null) {
          messages.addAll(history.map((e) => {
                'role': e['role'] as String,
                'content': e['content'] as String,
              }));
        }
        messages.add({'role': 'user', 'content': message});

        // Send request to the weather agent endpoint using the same message
        // payload format as the example curl command.
        final uri = Uri.parse(_weatherAgentUrl);
        // Increase timeout to 60 seconds to accommodate longer processing.
        final httpResponse = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                // The example request does not include an auth token.
              },
              body: jsonEncode(
                {
                  "messages": messages
                }
              ),
            )
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () => throw Exception('Request timeout'),
            );

        if (httpResponse.statusCode == 200) {
          final data = jsonDecode(httpResponse.body) as Map<String, dynamic>;

          // Try path 1: simple { "response": "..." } format
          if (data.containsKey('response')) {
            final responseValue = data['response'];
            if (responseValue is String) {
              return responseValue;
            } else if (responseValue is Map) {
              final mapValue = responseValue as Map<String, dynamic>;
              return (mapValue['text'] ??
                      mapValue['content'] ??
                      mapValue['message'] ??
                      jsonEncode(mapValue))
                  as String;
            } else {
              return responseValue?.toString() ?? 'No response from AI';
            }
          }

          // Try path 2: OpenRouter response format with `messages` array
          if (data.containsKey('messages') && data['messages'] is List) {
            final messages = data['messages'] as List;
            // Find the last assistant message
            for (var i = messages.length - 1; i >= 0; i--) {
              final msg = messages[i];
              if (msg is Map && msg['role'] == 'assistant') {
                final content = msg['content'];
                if (content is String) {
                  return content;
                } else if (content is List) {
                  // Content is an array of parts (reasoning, text, etc.)
                  for (var part in content) {
                    if (part is Map && part['type'] == 'text') {
                      return part['text'] as String;
                    }
                  }
                }
              }
            }
          }

          // Try path 3: `uiMessages` array with `parts`
          if (data.containsKey('uiMessages') && data['uiMessages'] is List) {
            final uiMessages = data['uiMessages'] as List;
            for (var i = uiMessages.length - 1; i >= 0; i--) {
              final msg = uiMessages[i];
              if (msg is Map && msg['role'] == 'assistant') {
                final parts = msg['parts'];
                if (parts is List) {
                  for (var part in parts) {
                    if (part is Map && part['type'] == 'text') {
                      return part['text'] as String;
                    }
                  }
                }
              }
            }
          }

          // Try path 4: `dbMessages` array with nested `content.parts`
          if (data.containsKey('dbMessages') && data['dbMessages'] is List) {
            final dbMessages = data['dbMessages'] as List;
            for (var i = dbMessages.length - 1; i >= 0; i--) {
              final msg = dbMessages[i];
              if (msg is Map && msg['role'] == 'assistant') {
                final content = msg['content'];
                if (content is Map) {
                  final parts = content['parts'];
                  if (parts is List) {
                    for (var part in parts) {
                      if (part is Map && part['type'] == 'text') {
                        return part['text'] as String;
                      }
                    }
                  }
                  // Fallback to `content.content` or `content.text`
                  if (content['content'] is String) {
                    return content['content'] as String;
                  }
                  if (content['text'] is String) {
                    return content['text'] as String;
                  }
                }
              }
            }
          }

          // Last resort: try to find any string field named 'text' or 'content'
          for (final key in ['text', 'content', 'message', 'answer']) {
            if (data[key] is String) {
              return data[key] as String;
            }
          }

          return 'No response from AI';
        } else if (httpResponse.statusCode == 401 && attempt < maxRetries) {
          // Unauthorized – refresh Supabase session and retry.
          await _supabase.auth.refreshSession();
          attempt++;
          await Future.delayed(Duration(milliseconds: retryDelay));
          retryDelay = min(retryDelay * 2, 15000);
          continue;
        } else if (httpResponse.statusCode == 408 && attempt < maxRetries) {
          // Request Timeout – wait and retry.
          attempt++;
          await Future.delayed(Duration(milliseconds: retryDelay));
          retryDelay = min(retryDelay * 2, 15000);
          continue;
        } else if (httpResponse.statusCode >= 500) {
          throw Exception('Server error. Please try again later.');
        } else {
          throw Exception('Request error: ${httpResponse.statusCode}');
        }
      } catch (e) {
        final errorMessage = e.toString().toLowerCase();
        print('[GeminiService] Error on attempt $attempt: $e');

        final isRetryableError = errorMessage.contains('timeout') ||
            errorMessage.contains('connection') ||
            errorMessage.contains('network') ||
            errorMessage.contains('socket') ||
            errorMessage.contains('dns') ||
            errorMessage.contains('unreachable') ||
            errorMessage.contains('unreachable') ||
            errorMessage.contains('failed host lookup') ||
            errorMessage.contains('connection refused') ||
            errorMessage.contains('connection reset') ||
            errorMessage.contains('connection closed');

        if (isRetryableError && attempt < maxRetries) {
          attempt++;
          await Future.delayed(Duration(milliseconds: retryDelay));
          retryDelay = min(retryDelay * 2, 15000);
          continue;
        }

        if (errorMessage.contains('session') ||
            errorMessage.contains('auth') ||
            errorMessage.contains('jwt') ||
            errorMessage.contains('unauthorized') || // Added for FunctionsException
            errorMessage.contains('invalid_token') || // Added for FunctionsException
            errorMessage.contains('token_expired')) {
          throw Exception('Session expired. Please sign in again.');
        } else if (isRetryableError) {
          throw Exception(
              'Network connection issue. Please check your internet connection and try again.');
        } else if (errorMessage.contains('timeout')) {
          throw Exception('Request timed out. Please try again.');
        } else if (errorMessage.contains('server error') ||
            errorMessage.contains('internal server') ||
            errorMessage.contains('bad gateway') ||
            errorMessage.contains('service unavailable') ||
            errorMessage.contains('service unavailable')) {
          throw Exception('Server temporarily unavailable. Please try again later.');
        } else if (errorMessage.contains('json') ||
            errorMessage.contains('parsing') ||
            errorMessage.contains('format')) {
          throw Exception('Data processing error. Please try again.');
        } else if (errorMessage.contains('rate limit') ||
            errorMessage.contains('quota')) {
          throw Exception(
              'Service temporarily busy. Please wait a moment and try again.');
        } else {
          print('[GeminiService] Unexpected error: $e');
          throw Exception(
              'An unexpected error occurred: ${e.toString()}. Please try again.');
        }
      }
    }

    throw Exception(
        'Network connection issue. Please check your internet connection and try again.');
  }
}