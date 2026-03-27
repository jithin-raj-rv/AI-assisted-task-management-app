# AI-Powered Productivity Manager

A sophisticated Flutter application that combines traditional task management with AI-driven insights and automated habit formation. This application serves as a personalized digital assistant that adapts to user behavior and preferences over time.

## 🚀 Features

### Core Productivity Features
- **Smart Task Management**: Eisenhower Matrix-based todo list with importance/urgency classification
- **Goal Tracking**: Long-term objectives with progress tracking and milestone management
- **Goal Steps**: Break down complex goals into actionable steps
- **Smart Reminders**: Multi-modal notifications with various interaction types
- **Timer Prompts**: AI-driven scheduled prompts that execute at specific times

### AI Integration
- **Gemini API Integration**: Real-time AI responses with function calling capabilities
- **Context-Aware Prompts**: AI has access to complete user data context
- **Scheduled AI Interactions**: Automated AI conversations at user-defined times
- **Customizable System Prompts**: Users can define AI behavior through system prompts
- **Function Calling**: AI can directly modify application data through structured calls

### Technical Features
- **Real-time Synchronization**: Bidirectional sync between local cache and cloud database
- **Offline Support**: Local-first design with automatic sync when connectivity is restored
- **Multi-platform**: Built with Flutter for iOS, Android, web, and desktop
- **Dark/Light Theme**: Customizable theme system with gradient-based UI
- **Secure Authentication**: JWT-based authentication with session management

## 🛠️ Technology Stack

### Frontend
- **Framework**: Flutter (Dart)
- **State Management**: Riverpod
- **UI Components**: Custom gradient-based components
- **Local Storage**: Hive for offline caching
- **Notifications**: Awesome Notifications for rich notifications

### Backend
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth
- **Real-time**: Supabase Real-time subscriptions
- **Serverless Functions**: Supabase Edge Functions
- **AI Integration**: Google Gemini API

### Development Tools
- **Version Control**: Git
- **Package Management**: Pub (Dart)
- **Build System**: Flutter build tools
- **Testing**: Flutter testing framework

## 📋 System Requirements

### Development Environment
- Flutter SDK 3.19.0 or higher
- Dart 3.3.0 or higher
- Node.js 18+ (for Supabase CLI)
- Supabase CLI

### Runtime Requirements
- iOS 12.0+ or Android 6.0+ (API level 23+)
- Internet connection for cloud features
- Push notification support for reminders

## 🚀 Quick Start

### 1. Installation

Clone the repository:
```bash
git clone <repository-url>
cd to_do_list
```

Install dependencies:
```bash
flutter pub get
```

### 2. Environment Setup

Create a `.env` file in the project root:
```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
GEMINI_API_KEY=your_gemini_api_key
```

### 3. Database Setup

Set up Supabase:
```bash
supabase login
supabase init
supabase start
```

Run database migrations:
```bash
supabase db push
```

### 4. Build and Run

For development:
```bash
flutter run
```

For production:
```bash
flutter build apk
flutter build ios
```

## 🏗️ Architecture Overview

### Layered Architecture
```
┌─────────────────────────────────────────┐
│              Presentation Layer         │
│  ┌─────────────┐  ┌──────────────────┐  │
│  │    Views    │  │     Components   │  │
│  └─────────────┘  └──────────────────┘  │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│              Business Logic Layer       │
│  ┌─────────────┐  ┌──────────────────┐  │
│  │ ViewModels  │  │     Services     │  │
│  └─────────────┘  └──────────────────┘  │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│              Data Layer                 │
│  ┌─────────────┐  ┌──────────────────┐  │
│  │   Providers │  │     Cache        │  │
│  └─────────────┘  └──────────────────┘  │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│              External Services          │
│  ┌─────────────┐  ┌──────────────────┐  │
│  │ Supabase    │  │     Gemini API   │  │
│  └─────────────┘  └──────────────────┘  │
└─────────────────────────────────────────┘
```

### Key Components

#### State Management (Riverpod)
- **Providers**: Centralized state management
- **Notifiers**: Reactive state updates
- **Async Data**: Handling async operations
- **Dependency Injection**: Clean dependency management

#### Data Synchronization
- **Local Cache**: Hive-based local storage
- **Cloud Sync**: Supabase real-time synchronization
- **Conflict Resolution**: Automatic conflict handling
- **Offline Support**: Full functionality without internet

#### AI Integration
- **Function Calling**: Structured AI interactions
- **Context Management**: AI access to user data
- **Prompt Engineering**: Customizable system prompts
- **Response Processing**: Structured response handling

## 📖 Usage Guide

### Getting Started
1. **Sign Up**: Create an account or sign in
2. **Onboarding**: Complete the user information quiz
3. **Setup**: Configure your goals and preferences
4. **Start Using**: Begin adding todos and setting reminders

### Core Workflows

#### Task Management
1. Add todos with importance and urgency levels
2. Organize tasks using the Eisenhower Matrix
3. Track progress and completion status
4. Set due dates and reminders

#### Goal Tracking
1. Create long-term goals with target dates
2. Break goals into actionable steps
3. Track progress through step completion
4. Review and adjust goals as needed

#### AI Integration
1. Set up timer prompts for regular AI check-ins
2. Configure system prompts to shape AI behavior
3. Interact with AI through reminders and prompts
4. Use AI suggestions to optimize your productivity

### Advanced Features

#### Custom Reminders
- **Basic**: Simple notification reminders
- **Options**: Multiple choice responses
- **Answer Back**: Free-form text responses
- **AI Prompts**: AI-driven interactive reminders

#### System Prompts
- Define AI personality and behavior
- Customize response style and tone
- Set context for AI interactions
- Update prompts based on experience

## 🔧 Configuration

### Environment Variables
```env
# Supabase Configuration
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key

# AI Configuration
GEMINI_API_KEY=your_gemini_api_key

# Firebase Configuration (for push notifications)
FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_APP_ID=your_firebase_app_id
```

### Database Schema
The application uses the following main tables:
- `todos`: Task management
- `goals`: Long-term objectives
- `goal_steps`: Goal breakdown
- `timer_prompts`: AI prompt scheduling
- `reminders`: Notification system
- `user_feedback`: User interactions
- `personality_traits`: User preferences
- `additional_info`: User context
- `system_prompts`: AI configuration

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Widget Tests
```bash
flutter test --tags=widget
```

### Integration Tests
```bash
flutter test integration_test/
```

### Test Coverage
```bash
flutter test --coverage
```

## 🚀 Deployment

### Web Deployment
```bash
flutter build web
# Deploy to Firebase Hosting or similar service
```

### Mobile Deployment
```bash
# Android
flutter build apk --release
flutter build appbundle

# iOS
flutter build ios --release
```

### Backend Deployment
```bash
# Deploy to Supabase
supabase deploy

# Deploy functions
supabase functions deploy
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Workflow
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Write tests for your changes
5. Run the test suite
6. Submit a pull request

### Code Style
- Follow Dart style guidelines
- Use meaningful variable names
- Write clear, concise comments
- Maintain consistent formatting

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

### Documentation
- [Architecture Documentation](ARCHITECTURE.md)
- [API Documentation](API_DOCS.md)
- [Development Guide](DEVELOPMENT.md)
- [AI Integration Guide](AI_INTEGRATION.md)

### Community
- [GitHub Issues](https://github.com/your-repo/issues)
- [Discussions](https://github.com/your-repo/discussions)
- [Documentation](https://your-docs-url.com)

### Contact
For support and questions:
- Email: support@yourapp.com
- Discord: [Invite Link]
- Twitter: [@yourapp]

## 🔗 Related Projects

- [Supabase](https://supabase.com) - Backend as a Service
- [Flutter](https://flutter.dev) - UI Framework
- [Google Gemini](https://ai.google.dev/gemini-api) - AI API
- [Riverpod](https://riverpod.dev) - State Management

## 📊 Analytics

This application includes comprehensive analytics for:
- User engagement metrics
- Feature usage statistics
- Performance monitoring
- Error tracking and reporting

---

**Note**: This is a sophisticated AI-powered productivity application. Please ensure you have the necessary API keys and permissions before deployment.