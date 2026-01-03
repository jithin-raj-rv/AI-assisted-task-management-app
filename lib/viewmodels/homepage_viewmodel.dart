import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/models/todo_model.dart';
import 'package:to_do_list/models/todo_category_model.dart';
import 'package:to_do_list/viewmodels/todo_viewmodel.dart';
import 'package:to_do_list/providers.dart';

int getCategoryScore(TodoCategory category) {
  if (category.importance == 'IMPORTANT' && category.urgency == 'URGENT') {
    return 1;
  }
  if (category.importance == 'IMPORTANT' && category.urgency == 'NOT URGENT') {
    return 2;
  }
  if (category.importance == 'NOT IMPORTANT' && category.urgency == 'URGENT') {
    return 3;
  }
  return 4; // NOT IMPORTANT, NOT URGENT
}

List<TodoCategory> deriveCategories(List<Todo> todos) {
  final categories = todos
      .map((t) => TodoCategory(importance: t.importance, urgency: t.urgency))
      .toSet()
      .toList();
  categories.sort((a, b) => getCategoryScore(a).compareTo(getCategoryScore(b)));
  return categories;
}

class HomePageState {
  final List<Todo> todos;

  const HomePageState({this.todos = const []});

  HomePageState copyWith({List<Todo>? todos}) {
    return HomePageState(todos: todos ?? this.todos);
  }
}

class HomePageViewModel extends Notifier<HomePageState> {
  @override
  HomePageState build() {
    final todoState = ref.watch(todoViewModelProvider);
    return HomePageState(todos: todoState.todos);
  }
}

final homePageViewModelProvider =
    NotifierProvider<HomePageViewModel, HomePageState>(() => HomePageViewModel());
