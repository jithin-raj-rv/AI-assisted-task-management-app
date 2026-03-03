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

    final stream = _supabase.from('user_feedback').stream(primaryKey: ['id']).eq('user_id', user.id);
    stream.listen((payload) async {
      final box = await Hive.openBox<UserFeedback>('user_feedback');
      for (final record in payload) {
        final feedback = UserFeedback.fromJson(record);
        await box.put(feedback.id, feedback);
      }
    });
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