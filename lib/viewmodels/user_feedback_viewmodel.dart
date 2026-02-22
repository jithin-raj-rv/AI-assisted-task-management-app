import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/models/user_feedback_model.dart';
import 'package:to_do_list/cache/user_feedback_cache.dart';
import 'package:to_do_list/sync_providers.dart';

class UserFeedbackState {
  final List<UserFeedback> feedbacks;

  UserFeedbackState({this.feedbacks = const []});

  UserFeedbackState copyWith({List<UserFeedback>? feedbacks}) {
    return UserFeedbackState(feedbacks: feedbacks ?? this.feedbacks);
  }
}

class UserFeedbackViewModel extends Notifier<UserFeedbackState> {
  final UserFeedbackCache _cache = UserFeedbackCache();

  @override
  UserFeedbackState build() {
    _cache.watchAll().listen((f) {
      state = UserFeedbackState(feedbacks: f);
    });
    return UserFeedbackState();
  }

  Future<void> addFeedback(UserFeedback feedback) async {
    final id = feedback.timestamp.millisecondsSinceEpoch.toString();
    await _cache.put(id, feedback);
    await ref.read(userFeedbackSyncServiceProvider).syncToSupabase();
  }

  Future<void> deleteFeedback(String id) async {
    await _cache.delete(id);
    // Note: Deletion is local-only for now.
    // To sync deletions, a 'deleted' flag or a separate table would be needed.
  }
}

final userFeedbackViewModelProvider = NotifierProvider<UserFeedbackViewModel, UserFeedbackState>(() => UserFeedbackViewModel());
