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
  static const String _weatherAgentUrl = 'https://chammpu-man-isawsommm.loca.lt/api/agents/testQueryAgent/generate';

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

        final accessToken = _supabase.auth.currentSession?.accessToken;
        if (accessToken == null || accessToken.isEmpty) {
          throw Exception('No access token available');
        }
         print("Thisssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssfffffffffffffffffffsssssssssssssssssssssssssss ="+ accessToken);
        // Send request to the weather agent endpoint using the same message
        // payload format as the example curl command: {"messages": "Weather in London"}
        final uri = Uri.parse(_weatherAgentUrl);
        // Increase timeout to 60 seconds to accommodate longer processing.
        final httpResponse = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $accessToken',
              },
              body: jsonEncode(
                {
                  "messages": message
                }
              ),
            )
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () => throw Exception('Request timeout'),
            );

        if (httpResponse.statusCode == 200) {
          final data = jsonDecode(httpResponse.body) as Map<String, dynamic>;

          //  Mastra's clean top-level "text" field
          if (data.containsKey('text') && data['text'] is String && data['text']!="") {
            return data['text'] as String;
          }
          else {
            return "No response from AI";
          }
          
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
          print(' Unexpected error: $e');
          throw Exception(
              'An unexpected error occurred: ${e.toString()}. Please try again.');
        }
      }
    }

    throw Exception(
        'Network connection issue. Please check your internet connection and try again.');
  }
}