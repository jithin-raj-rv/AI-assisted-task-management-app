import 'package:supabase_flutter/supabase_flutter.dart';

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
  static Future<String> sendChatMessage(String userId, String message) async {
    int retries = 0;
    const maxRetries = 2;

    while (retries <= maxRetries) {
      try {
        // Ensure we have a valid session with fresh tokens
        await _ensureValidSession();

        // Verify the current user is authenticated
        final user = await _supabase.auth.getUser();
        if (user.user == null) {
          throw Exception('User not authenticated');
        }

        final response = await _supabase.functions.invoke(
          'process-prompt',
          body: {
            'userInput': message,
          },
        );

        if (response.status == 401) {
          // If we get 401, retry once after refreshing
          if (retries < maxRetries) {
            print('[GeminiService] Got 401, retrying after token refresh...');
            retries++;
            // Force a token refresh before retrying
            try {
              await _supabase.auth.refreshSession();
            } catch (e) {
              print('[GeminiService] Token refresh failed: $e');
              throw Exception('Authentication failed. Please sign in again.');
            }
            continue;
          } else {
            throw Exception('Authentication failed. Please sign in again.');
          }
        } else if (response.status != 200) {
          throw Exception('Failed to get response from Gemini service: ${response.status}');
        }

        final data = response.data as Map<String, dynamic>;
        return data['response'] as String? ?? 'No response from AI';
      } catch (e) {
        // Log the actual error for debugging
        print('Gemini service error (attempt $retries): $e');

        // Handle specific authentication errors
        if (e.toString().contains('refresh') || e.toString().contains('session') || e.toString().contains('JWT') || e.toString().contains('Session expired')) {
          throw Exception('Session expired. Please sign in again.');
        }

        // Handle Edge Function errors
        if (e.toString().contains('process-prompt')) {
          throw Exception('Gemini service error: ${e.toString()}');
        }

        // If it's the last retry or a non-auth error, throw
        if (retries >= maxRetries) {
          throw Exception('Error calling Gemini service: $e');
        }

        // Otherwise, retry
        retries++;
      }
    }

    throw Exception('Max retries exceeded when calling Gemini service');
  }
}
