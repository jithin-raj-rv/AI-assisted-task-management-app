import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseGeminiService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Send a chat message to the Supabase Gemini Edge Function
  /// Returns the AI response as a string
  static Future<String> sendChatMessage(String userId, String message) async {
    try {
      final response = await _supabase.functions.invoke(
        'process-prompt',
        body: {
          'userId': userId,
          'userInput': message,
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to get response from Gemini service: ${response.status}');
      }

      final data = response.data as Map<String, dynamic>;
      return data['response'] as String? ?? 'No response from AI';
    } catch (e) {
      throw Exception('Error calling Gemini service: $e');
    }
  }
}
