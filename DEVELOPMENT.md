# Development Guidelines

This document provides comprehensive guidelines for developers working on the AI-powered productivity application.

## Table of Contents

1. [Code Structure](#code-structure)
2. [Coding Standards](#coding-standards)
3. [Testing Strategy](#testing-strategy)
4. [Build and Deployment](#build-and-deployment)
5. [Git Workflow](#git-workflow)
6. [Contributing Guidelines](#contributing-guidelines)
7. [Development Environment Setup](#development-environment-setup)
8. [Debugging and Troubleshooting](#debugging-and-troubleshooting)

## Code Structure

### Project Organization

```
lib/
├── main.dart                    # Application entry point
├── providers.dart              # Riverpod providers
├── sync_providers.dart         # Data synchronization providers
├── theme.dart                  # Theme management
├── cache/                      # Local storage cache
│   ├── todo_cache.dart
│   ├── goal_cache.dart
│   └── ...
├── config/                     # Configuration files
│   └── supabase_config.dart
├── database/                   # Database utilities
│   └── chatdata.dart
├── models/                     # Data models
│   ├── todo_model.dart
│   ├── goal_model.dart
│   ├── timer_prompt_model.dart
│   └── ...
├── services/                   # Business logic services
│   ├── todo_sync_service.dart
│   ├── goal_sync_service.dart
│   ├── supabase_gemini_service.dart
│   └── ...
├── util/                       # Utility components
│   ├── button.dart
│   ├── gradienttextfield.dart
│   ├── chatbubble.dart
│   └── ...
├── viewmodels/                 # State management viewmodels
│   ├── todo_viewmodel.dart
│   ├── goals_viewmodel.dart
│   └── ...
└── View/                       # UI screens
    ├── homepage.dart
    ├── todopage.dart
    ├── goalspage.dart
    ├── chatscreen.dart
    └── ...
```

### Naming Conventions

#### Files and Directories
- Use lowercase with underscores for file names: `todo_model.dart`
- Use lowercase with underscores for directories: `viewmodels/`
- Use descriptive names that reflect the purpose

#### Classes and Types
- Use PascalCase for class names: `TodoViewModel`, `AuthService`
- Use descriptive names that indicate the class purpose
- Suffix view models with `ViewModel`: `TodoViewModel`
- Suffix services with `Service`: `TodoSyncService`
- Suffix models with `Model` (optional): `TodoModel`

#### Variables and Functions
- Use camelCase for variables and functions: `isCompleted`, `getTodos()`
- Use descriptive names that indicate the purpose
- Use boolean variables with `is`, `has`, `can` prefixes: `isLoading`, `hasData`

#### Constants
- Use SCREAMING_SNAKE_CASE for constants: `MAX_RETRY_ATTEMPTS`
- Group related constants in a class or enum

### Code Organization

#### File Structure
Each Dart file should follow this structure:

```dart
// 1. Copyright and license (if applicable)

// 2. Imports (grouped and sorted)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 3. Constants and enums
const kMaxRetryAttempts = 5;

enum ReminderType {
  basic,
  option,
  answerBack,
  aiPrompt
}

// 4. Classes and functions
class TodoViewModel extends Notifier<TodoState> {
  // Implementation
}
```

#### Class Structure
```dart
class ExampleClass {
  // 1. Static constants
  static const String kClassName = 'ExampleClass';
  
  // 2. Private fields
  final String _privateField;
  
  // 3. Public fields
  final String publicField;
  
  // 4. Constructors
  ExampleClass(this._privateField, {required this.publicField});
  
  // 5. Public methods
  void publicMethod() {
    _privateMethod();
  }
  
  // 6. Private methods
  void _privateMethod() {
    // Implementation
  }
}
```

## Coding Standards

### Dart Best Practices

#### Null Safety
- Always use null-safe code
- Use nullable types when appropriate: `String?`
- Use null-aware operators: `??`, `?.`, `!`
- Avoid `late` variables unless absolutely necessary

```dart
// Good
String? optionalValue;
final requiredValue = optionalValue ?? 'default';

// Avoid
late String lateValue; // Only use if you must
```

#### Immutability
- Prefer immutable data structures
- Use `final` for variables that don't change
- Create new objects instead of modifying existing ones

```dart
// Good
final updatedTodo = todo.copyWith(isCompleted: true);

// Avoid
todo.isCompleted = true;
```

#### Error Handling
- Always handle exceptions appropriately
- Use specific exception types
- Provide meaningful error messages

```dart
try {
  await someOperation();
} on NetworkException {
  // Handle network errors
  showErrorMessage('Network connection failed');
} on DatabaseException {
  // Handle database errors
  showErrorMessage('Database operation failed');
} catch (error, stack) {
  // Handle unexpected errors
  logError(error, stack);
  showErrorMessage('An unexpected error occurred');
}
```

#### Async/Await
- Use `async`/`await` for asynchronous operations
- Avoid using `.then()` and `.catchError()`
- Always handle exceptions in async functions

```dart
// Good
Future<void> fetchData() async {
  try {
    final data = await api.getData();
    updateState(data);
  } catch (error) {
    handleError(error);
  }
}

// Avoid
void fetchData() {
  api.getData().then((data) {
    updateState(data);
  }).catchError(handleError);
}
```

### Riverpod Best Practices

#### Provider Organization
- Use `NotifierProvider` for mutable state
- Use `Provider` for immutable state
- Use `FutureProvider` for async data
- Use `StreamProvider` for real-time data

```dart
// State management
final todoViewModelProvider = NotifierProvider<TodoViewModel, TodoState>(
  () => TodoViewModel(),
);

// Async data
final userProvider = FutureProvider<User?>(
  (ref) => ref.watch(authServiceProvider).currentUser,
);

// Real-time data
final todosProvider = StreamProvider<List<Todo>>(
  (ref) => ref.watch(todoSyncServiceProvider).watchTodos(),
);
```

#### Provider Dependencies
- Use `ref.watch()` to access other providers
- Use `ref.read()` for one-time access
- Avoid circular dependencies

```dart
final todoViewModelProvider = NotifierProvider<TodoViewModel, TodoState>(() {
  return TodoViewModel();
});

class TodoViewModel extends Notifier<TodoState> {
  @override
  TodoState build() {
    // Watch for changes
    ref.watch(todoSyncServiceProvider);
    return const TodoState();
  }
  
  Future<void> loadTodos() async {
    // One-time access
    final syncService = ref.read(todoSyncServiceProvider);
    final todos = await syncService.getTodos();
    state = state.copyWith(todos: todos);
  }
}
```

### Widget Best Practices

#### Stateless vs Stateful
- Use `StatelessWidget` when possible
- Use `StatefulWidget` only when state changes
- Extract widgets to improve readability

```dart
// Good - Extracted widget
class TodoItem extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  
  const TodoItem({
    Key? key,
    required this.todo,
    required this.onToggle,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(todo.taskName),
      trailing: Checkbox(
        value: todo.isCompleted,
        onChanged: (_) => onToggle(),
      ),
    );
  }
}

// Usage
@override
Widget build(BuildContext context) {
  return ListView.builder(
    itemCount: todos.length,
    itemBuilder: (context, index) {
      final todo = todos[index];
      return TodoItem(
        todo: todo,
        onToggle: () => toggleTodo(todo.id),
      );
    },
  );
}
```

#### Performance Optimization
- Use `const` constructors when possible
- Use `ListView.builder` for long lists
- Use `Provider` to avoid unnecessary rebuilds

```dart
// Good - Const constructor
const Text('Hello World');

// Good - Lazy loading
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
);

// Good - Provider for state management
Consumer(
  builder: (context, ref, child) {
    final todos = ref.watch(todoProvider);
    return TodoList(todos: todos);
  },
);
```

## Testing Strategy

### Test Organization

```
test/
├── unit/                       # Unit tests
│   ├── models/
│   │   ├── todo_model_test.dart
│   │   └── goal_model_test.dart
│   ├── services/
│   │   ├── todo_sync_service_test.dart
│   │   └── auth_service_test.dart
│   └── viewmodels/
│       ├── todo_viewmodel_test.dart
│       └── goals_viewmodel_test.dart
├── widget/                     # Widget tests
│   ├── todo_page_test.dart
│   ├── goals_page_test.dart
│   └── chat_screen_test.dart
└── integration/                # Integration tests
    ├── app_test.dart
    └── user_workflow_test.dart
```

### Unit Tests

#### Model Tests
```dart
void main() {
  group('Todo Model', () {
    test('should create todo with correct properties', () {
      final todo = Todo(
        id: '1',
        taskName: 'Test Task',
        isCompleted: false,
        importance: 'IMPORTANT',
        urgency: 'URGENT',
      );
      
      expect(todo.id, '1');
      expect(todo.taskName, 'Test Task');
      expect(todo.isCompleted, false);
      expect(todo.importance, 'IMPORTANT');
      expect(todo.urgency, 'URGENT');
    });
    
    test('should copy with new values', () {
      final todo = Todo(
        id: '1',
        taskName: 'Test Task',
        isCompleted: false,
        importance: 'IMPORTANT',
        urgency: 'URGENT',
      );
      
      final updatedTodo = todo.copyWith(isCompleted: true);
      
      expect(updatedTodo.isCompleted, true);
      expect(updatedTodo.taskName, todo.taskName);
    });
  });
}
```

#### Service Tests
```dart
void main() {
  late MockSupabaseClient mockSupabase;
  late TodoSyncService service;
  
  setUp(() {
    mockSupabase = MockSupabaseClient();
    service = TodoSyncService(mockSupabase);
  });
  
  group('TodoSyncService', () {
    test('should fetch todos from supabase', () async {
      // Arrange
      final expectedTodos = [Todo(id: '1', taskName: 'Test')];
      when(() => mockSupabase.from('todos').select())
          .thenAnswer((_) async => expectedTodos);
      
      // Act
      final result = await service.getTodos();
      
      // Assert
      expect(result, expectedTodos);
    });
    
    test('should handle network errors', () async {
      // Arrange
      when(() => mockSupabase.from('todos').select())
          .thenThrow(NetworkException('Network error'));
      
      // Act & Assert
      expect(() => service.getTodos(), throwsA(isA<NetworkException>()));
    });
  });
}
```

#### ViewModel Tests
```dart
void main() {
  late MockTodoSyncService mockService;
  late TodoViewModel viewModel;
  
  setUp(() {
    mockService = MockTodoSyncService();
    viewModel = TodoViewModel(mockService);
  });
  
  group('TodoViewModel', () {
    test('should load todos successfully', () async {
      // Arrange
      final todos = [Todo(id: '1', taskName: 'Test')];
      when(() => mockService.getTodos()).thenAnswer((_) async => todos);
      
      // Act
      await viewModel.loadTodos();
      
      // Assert
      expect(viewModel.state.todos, todos);
      expect(viewModel.state.isLoading, false);
    });
    
    test('should handle loading state', () {
      // Act
      viewModel.setLoading(true);
      
      // Assert
      expect(viewModel.state.isLoading, true);
    });
  });
}
```

### Widget Tests

```dart
void main() {
  group('TodoPage', () {
    testWidgets('displays todo list', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todoViewModelProvider.overrideWithValue(MockTodoViewModel()),
          ],
          child: MaterialApp(home: TodoPage()),
        ),
      );
      
      // Act
      await tester.pump();
      
      // Assert
      expect(find.byType(ListView), findsOneWidget);
    });
    
    testWidgets('displays add todo button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: TodoPage()),
      );
      
      expect(find.text('Add Todo'), findsOneWidget);
    });
  });
}
```

### Integration Tests

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('User Workflow', () {
    testWidgets('user can add and complete todo', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      
      // Act - Navigate to todo page
      await tester.tap(find.text('Todos'));
      await tester.pumpAndSettle();
      
      // Act - Add todo
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      
      await tester.enterText(find.byType(TextField), 'Test Todo');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      
      // Assert - Todo appears in list
      expect(find.text('Test Todo'), findsOneWidget);
      
      // Act - Complete todo
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      
      // Assert - Todo is marked complete
      final checkbox = find.byType(Checkbox).first;
      expect(tester.widget<Checkbox>(checkbox).value, true);
    });
  });
}
```

### Test Utilities

```dart
// test_utils.dart
class TestUtil {
  static Widget createTestApp({
    required Widget child,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: child,
      ),
    );
  }
  
  static MockTodoViewModel createMockTodoViewModel() {
    final mock = MockTodoViewModel();
    when(() => mock.state).thenReturn(TodoState(
      todos: [],
      isLoading: false,
      error: null,
    ));
    return mock;
  }
}
```

## Build and Deployment

### Development Build

```bash
# Run in development mode
flutter run

# Run with specific device
flutter run -d emulator-5554

# Run with debug mode
flutter run --debug

# Run with profile mode
flutter run --profile
```

### Production Build

```bash
# Build for Android
flutter build apk --release
flutter build appbundle --release

# Build for iOS
flutter build ios --release

# Build for Web
flutter build web --release

# Build for Desktop
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

### Environment Configuration

#### Development Environment
```env
# .env.development
SUPABASE_URL=https://dev-project.supabase.co
SUPABASE_ANON_KEY=dev-anon-key
GEMINI_API_KEY=dev-gemini-key
DEBUG_MODE=true
```

#### Production Environment
```env
# .env.production
SUPABASE_URL=https://prod-project.supabase.co
SUPABASE_ANON_KEY=prod-anon-key
GEMINI_API_KEY=prod-gemini-key
DEBUG_MODE=false
```

#### Environment Loading
```dart
class EnvironmentConfig {
  static String get supabaseUrl => const String.fromEnvironment('SUPABASE_URL');
  static String get supabaseAnonKey => const String.fromEnvironment('SUPABASE_ANON_KEY');
  static String get geminiApiKey => const String.fromEnvironment('GEMINI_API_KEY');
  static bool get isDebugMode => const String.fromEnvironment('DEBUG_MODE') == 'true';
  
  static bool get isValid {
    return supabaseUrl.isNotEmpty && 
           supabaseAnonKey.isNotEmpty && 
           geminiApiKey.isNotEmpty;
  }
}
```

### CI/CD Pipeline

#### GitHub Actions Example
```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.19.0'
        channel: 'stable'
    
    - name: Install dependencies
      run: flutter pub get
    
    - name: Run tests
      run: flutter test --coverage
    
    - name: Run analysis
      run: flutter analyze
    
    - name: Build for Android
      run: flutter build apk --release
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage/lcov.info

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Deploy to Supabase
      run: |
        npm install -g @supabase/supabase
        supabase login
        supabase link --project-ref your-project-ref
        supabase deploy
```

## Git Workflow

### Branching Strategy

We use Git Flow with the following branches:

- `main` - Production-ready code
- `develop` - Integration branch for features
- `feature/*` - Feature branches
- `hotfix/*` - Hotfix branches
- `release/*` - Release preparation branches

### Commit Message Convention

Use conventional commits format:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

#### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

#### Examples
```
feat(todos): add todo completion tracking
fix(auth): resolve session timeout issue
docs(readme): update installation instructions
refactor(api): simplify error handling
test(viewModel): add todo viewmodel tests
```

### Pull Request Guidelines

1. **Create feature branch**: `git checkout -b feature/your-feature-name`
2. **Commit changes**: Use conventional commit messages
3. **Push to remote**: `git push origin feature/your-feature-name`
4. **Create PR**: Use the GitHub interface
5. **PR Template**: Fill out the PR template

#### PR Template
```markdown
## Summary
Brief description of changes

## Test plan
- [ ] Test 1
- [ ] Test 2
- [ ] Test 3

## Documentation
- [ ] Updated README
- [ ] Added code comments
- [ ] Created documentation

## Breaking changes
List any breaking changes and migration steps
```

## Contributing Guidelines

### Getting Started

1. **Fork the repository**
2. **Clone your fork**: `git clone https://github.com/your-username/to_do_list.git`
3. **Install dependencies**: `flutter pub get`
4. **Set up environment**: Create `.env` file with required variables
5. **Run the app**: `flutter run`

### Development Process

1. **Check existing issues**: Look for existing issues or feature requests
2. **Create issue**: If new, create an issue to discuss the feature
3. **Fork and branch**: Create a feature branch from `develop`
4. **Implement changes**: Follow coding standards and best practices
5. **Write tests**: Ensure adequate test coverage
6. **Update documentation**: Update relevant documentation
7. **Submit PR**: Create a pull request with detailed description

### Code Review Process

1. **Automated checks**: All CI/CD checks must pass
2. **Code review**: At least one maintainer must approve
3. **Testing**: Manual testing of the feature
4. **Documentation**: Ensure documentation is up to date
5. **Merge**: Squash and merge to `develop` branch

### Quality Standards

- **Code coverage**: Minimum 80% test coverage
- **Code style**: Follow Dart style guide
- **Performance**: No performance regressions
- **Security**: No security vulnerabilities
- **Accessibility**: Follow accessibility guidelines

## Development Environment Setup

### Prerequisites

1. **Flutter SDK**: Version 3.19.0 or higher
2. **Dart**: Version 3.3.0 or higher
3. **Node.js**: Version 18+ (for Supabase CLI)
4. **Supabase CLI**: For local development
5. **Git**: Version control

### Installation Steps

#### 1. Install Flutter
```bash
# Download and install Flutter
# Add Flutter to PATH
flutter doctor
```

#### 2. Install Supabase CLI
```bash
npm install -g @supabase/supabase
supabase login
```

#### 3. Set up Local Development
```bash
# Clone the repository
git clone https://github.com/your-username/to_do_list.git
cd to_do_list

# Install dependencies
flutter pub get

# Set up Supabase locally
supabase init
supabase start

# Run database migrations
supabase db push
```

#### 4. Environment Configuration
Create `.env` file:
```env
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=your-local-anon-key
GEMINI_API_KEY=your-gemini-key
```

#### 5. Run the Application
```bash
# Start development server
flutter run
```

### IDE Setup

#### VS Code Extensions
- Dart
- Flutter
- Supabase
- GitLens
- Prettier

#### Android Studio Plugins
- Flutter
- Dart
- Supabase

#### Code Formatting
```json
// .vscode/settings.json
{
  "dart.lineLength": 120,
  "dart.analyzeAngularTemplates": true,
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.dart": true
  }
}
```

## Debugging and Troubleshooting

### Common Issues

#### 1. Supabase Connection Issues
```dart
// Check connection status
final isConnected = await supabase.from('todos').select().isNotEmpty;

// Handle connection errors
try {
  final result = await supabase.from('todos').select();
} on PostgrestException catch (e) {
  if (e.code == 'PGRST116') {
    // Handle RLS violation
    print('Access denied');
  }
}
```

#### 2. Authentication Issues
```dart
// Check session validity
final session = supabase.auth.currentSession;
if (session == null) {
  // Redirect to login
  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginPage()));
}

// Handle session expiration
supabase.auth.onAuthStateChange.listen((event) {
  if (event.session == null) {
    // Session expired
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginPage()));
  }
});
```

#### 3. AI Integration Issues
```dart
// Handle AI service errors
try {
  final response = await SupabaseGeminiService.sendChatMessage(userId, prompt);
} on TimeoutException {
  showErrorMessage('Request timed out. Please try again.');
} on NetworkException {
  showErrorMessage('Network error. Please check your connection.');
} on AuthException {
  showErrorMessage('Authentication failed. Please sign in again.');
}
```

### Debugging Tools

#### Flutter DevTools
```bash
# Launch DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Or use VS Code extension
```

#### Logging
```dart
import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: false,
    ),
  );
  
  static void d(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error, stackTrace);
  }
  
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error, stackTrace);
  }
}
```

#### Performance Monitoring
```dart
import 'package:flutter/foundation.dart' show kDebugMode;

class PerformanceMonitor {
  static void measure(String operation, Function() action) {
    if (!kDebugMode) return;
    
    final stopwatch = Stopwatch()..start();
    action();
    stopwatch.stop();
    
    print('$operation took ${stopwatch.elapsedMilliseconds}ms');
  }
}
```

### Troubleshooting Checklist

#### App Won't Start
- [ ] Check Flutter installation: `flutter doctor`
- [ ] Check dependencies: `flutter pub get`
- [ ] Check environment variables
- [ ] Check Supabase connection

#### Database Issues
- [ ] Check Supabase status: `supabase status`
- [ ] Check database migrations: `supabase db push`
- [ ] Check RLS policies
- [ ] Check network connectivity

#### AI Integration Issues
- [ ] Check Gemini API key
- [ ] Check network connectivity
- [ ] Check rate limits
- [ ] Check function deployment

#### Performance Issues
- [ ] Check for unnecessary rebuilds
- [ ] Check for memory leaks
- [ ] Check database query performance
- [ ] Check image loading optimization

This development guide provides comprehensive information for developers working on the project. Always refer to this document when contributing to ensure code quality and consistency.