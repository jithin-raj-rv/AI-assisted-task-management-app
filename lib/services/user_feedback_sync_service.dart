import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_list/models/user_feedback_model.dart';
import 'package:to_do_list/services/connectivity_service.dart';
import 'package:to_do_list/cache/user_feedback_cache.dart';

class UserFeedbackSyncService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ConnectivityService _connectivityService;
  final UserFeedbackCache _cache = UserFeedbackCache();

  UserFeedbackSyncService(this._connectivityService);

  Future<void> syncFromSupabase() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      final feedbackData = await _supabase.from('user_feedback').select('*').eq('user_id', user.id) as List;
      final feedbacks = feedbackData.map((f) {
        return UserFeedback(
          id: f['id'],
          feedback: f['feedback'],
          timestamp: DateTime.parse(f['timestamp']),
          userId: f['user_id'],
        );
      }).toList();

      final box = await Hive.openBox<UserFeedback>('user_feedback');
      final newFeedbacks = {for (var feedback in feedbacks) feedback.id!: feedback};
      final oldKeys = box.keys.toSet();
      final keysToDelete = oldKeys.difference(newFeedbacks.keys.toSet());
      if (keysToDelete.isNotEmpty) {
        box.deleteAll(keysToDelete);
      }
      if (newFeedbacks.isNotEmpty) {
        box.putAll(newFeedbacks);
      }
    } catch (e) {
      print('[UserFeedbackSync] Error syncing from Supabase: $e');
    }
  }

  Future<void> syncToSupabase() async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      return;
    }

    final box = await Hive.openBox<UserFeedback>('user_feedback');
    final feedbacks = box.values.toList();

    for (final feedback in feedbacks) {
      try {
        // Check if the feedback already exists in Supabase
        if (feedback.id == null) continue;
        final existing = await _supabase
            .from('user_feedback')
            .select('id')
            .eq('id', feedback.id!)
            .maybeSingle();

        if (existing == null) {
           final supabaseData = {
            'id': feedback.id,
            'user_id': user.id,
            'feedback': feedback.feedback,
            'timestamp': feedback.timestamp.toIso8601String(),
          };
          await _supabase.from('user_feedback').insert(supabaseData);
        }
      } catch (e) {
        print('[UserFeedbackSync] Error syncing feedback to Supabase: $e');
      }
    }
  }
}
