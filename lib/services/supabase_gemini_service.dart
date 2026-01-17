import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_list/models/chat_model.dart';

class SupabaseGeminiService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Ensure we have a valid session with fresh tokens
  static Future<void> _ensureValidSession() async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw Exception('No active session');
    }

    // Always try to refresh the token to ensure it's valid
    // This is more reliable than checking expiry time
    try {
      final refreshed = await _supabase.auth.refreshSession();
      if (refreshed.session == null) {
        throw Exception('Session refresh failed - no session returned');
      }
    } catch (e) {
      // If refresh fails, the session is likely invalid
      print('[GeminiService] Session refresh failed: $e');
      throw Exception('Session expired. Please sign in again.');
    }
  }

  /// Send a chat message to the Supabase Gemini Edge Function
  /// Returns the AI response as a string
  static Future<String> sendChatMessage(
    String userId,
    String message, {
    List<Chat>? chatHistory,
    int maxRetries = 5
  }) async {
    int attempt = 0;
    int retryDelay = 1000; // Start with 1 second delay

    while (attempt <= maxRetries) {
      try {
        // Only refresh session on first attempt or after auth errors
        if (attempt == 0) {
          await _ensureValidSession();
        }

        // Verify the current user is authenticated
        final user = await _supabase.auth.getUser();
        if (user.user == null) {
          throw Exception('User not authenticated');
        }

        // Convert chat history to the expected format
        final history = chatHistory?.map((chat) {
          return {
            'role': chat.isUser ? 'user' : 'model',
            'content': chat.text
          };
        }).toList();

        // Add timeout to prevent hanging
        final response = await _supabase.functions.invoke(
          'process-prompt',
          body: {
            'userInput': message,
            'chatHistory': history,
          },
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('Request timeout'),
        );

        if (response.status == 200) {
          final data = response.data as Map<String, dynamic>;
          return data['response'] as String? ?? 'No response from AI';
        } else if (response.status == 401 && attempt < maxRetries) {
          // Auth error - refresh session and retry
          try {
            await _supabase.auth.refreshSession();
          } catch (e) {
            // If session refresh fails, don't retry
            throw Exception('Authentication failed. Please sign in again.');
          }
          attempt++;
          await Future.delayed(Duration(milliseconds: retryDelay));
          retryDelay = min(retryDelay * 2, 15000); // Exponential backoff, max 15s
          continue;
        } else if (response.status >= 400 && response.status < 600) {
          // Client/Server errors - don't retry these
          if (response.status >= 500) {
            throw Exception('Server error. Please try again later.');
          } else {
            throw Exception('Request error: ${response.status}');
          }
        } else {
          throw Exception('Unexpected response: ${response.status}');
        }
      } catch (e) {
        final errorMessage = e.toString().toLowerCase();

        // Log the actual error for debugging
        print('[GeminiService] Error on attempt $attempt: $e');

        // Check if this is a retryable network error
        final isRetryableError = errorMessage.contains('timeout') ||
                                errorMessage.contains('connection') ||
                                errorMessage.contains('network') ||
                                errorMessage.contains('socket') ||
                                errorMessage.contains('dns') ||
                                errorMessage.contains('internet') ||
                                errorMessage.contains('unreachable') ||
                                errorMessage.contains('failed host lookup') ||
                                errorMessage.contains('connection refused') ||
                                errorMessage.contains('connection reset') ||
                                errorMessage.contains('connection closed');

        if (isRetryableError && attempt < maxRetries) {
          // Network error - retry with backoff
          print('[GeminiService] Retrying network error (attempt ${attempt + 1}/$maxRetries)');
          attempt++;
          await Future.delayed(Duration(milliseconds: retryDelay));
          retryDelay = min(retryDelay * 2, 15000); // Exponential backoff, max 15s
          continue;
        } else {
          // Non-retryable error or max retries reached
          if (errorMessage.contains('session') || errorMessage.contains('auth') ||
              errorMessage.contains('jwt') || errorMessage.contains('unauthorized') ||
              errorMessage.contains('invalid_token') || errorMessage.contains('token_expired')) {
            throw Exception('Session expired. Please sign in again.');
          } else if (isRetryableError) {
            throw Exception('Network connection issue. Please check your internet connection and try again.');
          } else if (errorMessage.contains('timeout')) {
            throw Exception('Request timed out. Please try again.');
          } else if (errorMessage.contains('server error') || errorMessage.contains('internal server') ||
                     errorMessage.contains('bad gateway') || errorMessage.contains('service unavailable')) {
            throw Exception('Server temporarily unavailable. Please try again later.');
          } else if (errorMessage.contains('json') || errorMessage.contains('parsing') ||
                     errorMessage.contains('format')) {
            throw Exception('Data processing error. Please try again.');
          } else if (errorMessage.contains('rate limit') || errorMessage.contains('quota')) {
            throw Exception('Service temporarily busy. Please wait a moment and try again.');
          } else {
            // Log unexpected errors for debugging
            print('[GeminiService] Unexpected error: $e');
            // Include error details in the message for debugging
            throw Exception('An unexpected error occurred: ${e.toString()}. Please try again.');
          }
        }
      }
    }

    throw Exception('Network connection issue. Please check your internet connection and try again.');
  }
}
