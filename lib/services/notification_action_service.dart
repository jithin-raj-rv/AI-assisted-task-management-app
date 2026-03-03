import 'package:rxdart/rxdart.dart';
import 'package:to_do_list/models/notification_action_model.dart';

class NotificationActionService {
  final _actionStream = BehaviorSubject<NotificationAction>();

  Stream<NotificationAction> get actionStream => _actionStream.stream;

  void addAction(NotificationAction action) {
    _actionStream.add(action);
  }

  void dispose() {
    _actionStream.close();
  }
}
