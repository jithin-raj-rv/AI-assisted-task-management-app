# What To Do (WTD) — AI-Powered Productivity Manager

> A college project turned deep-dive into AI agent integration — born from curiosity, built through experimentation, and still evolving.

## 📖 The Journey (The Real Story)

This app started as a **college project** with a simple goal: build a productivity manager that uses AI to help users form better habits. What followed was an intense learning experience spanning multiple AI frameworks, API limitations, and late-night debugging sessions.

### The AI Integration Rollercoaster

| Stage | What Happened | What I Learned |
|---|---|---|
| **Supabase Edge Functions** | Started here for AI calls. Built working Gemini integration with function calling. | Hit **hard time limits** (Edge Functions timeout). Cold starts made AI responses slow. Great for simple APIs, not for complex agentic workflows. |
| **Agno** | Migrated AI logic to Agno framework. | Learned about **agentic AI frameworks** — how agents, tools, and workflows fit together. But still needed more flexibility. |
| **Gemini API Expired** | Google's free Gemini API tier expired right before submission. 🫠 | Never rely on a single free API for a deadline. Also discovered Google's new AI usage limits mid-project. |
| **Mastra (Current)** | Finally settled on **Mastra** for agentic workflows. Hosted separately. | Agentic AI is powerful but complex. Mastra gives the control needed for this app's vision. Still needs optimisation. |

### The $$$ Challenge

This entire project was built **without spending a dime** — using free tiers of Gemini, Supabase, Firebase, and open-source tools. That constraint shaped every technical decision and made the journey both harder and more rewarding.

---

## 🎯 Core Concept

Inspired by **James Clear's *Atomic Habits***, this app aims to:

1. **Record a goal** — User defines what they want to achieve
2. **Set timers** — User decides when they want to be reminded
3. **AI generates tasks automatically** — Based on the goal and user context, tasks are created at the right times
4. **Smart reminders** — Multi-modal notifications keep the user on track
5. **Full transparency** — AI exposes all stored user data so the user always knows what the AI knows about them

The original Edge Function approach achieved this at a **basic level**, but the output quality wasn't satisfying. The complexity of automated task generation, habit formation logic, and context-aware scheduling required **proper agentic workflows** — hence the move to Mastra.

---

## 🏗️ Current Architecture

```
┌─────────────────────────────────────────────────┐
│                Flutter App (This Repo)           │
│  ┌──────────┐  ┌──────────┐  ┌───────────────┐  │
│  │  Views   │  │ ViewModels│  │   Services    │  │
│  │ (UI)     │  │(Logic)   │  │ (API/Cache)   │  │
│  └──────────┘  └──────────┘  └───────────────┘  │
└──────────────────────┬──────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
┌────────────┐ ┌──────────────┐ ┌──────────────┐
│  Supabase  │ │  Supabase    │ │   Mastra     │
│ (Database) │ │  (Auth)      │ │ (AI Agents)  │
└────────────┘ └──────────────┘ └──────┬───────┘
                                       │
                              (via tunnel.bat)
                              ┌─────────┐
                              │Localhost │
                              │Mastra Dev│
                              └─────────┘
```

### Components

| Component | Technology | Status |
|---|---|---|
| **Frontend** | Flutter (Dart) + Riverpod | ✅ Working |
| **Database** | Supabase (PostgreSQL) | ✅ Working |
| **Auth** | Supabase Auth (JWT) | ✅ Working |
| **Local Cache** | Hive | ✅ Working |
| **Reminders** | Awesome Notifications | ✅ Working |
| **Edge Functions** | Supabase (OpenRouter — stripped down) | ⚠️ Legacy (Gemini code removed) |
| **AI Agent** | Mastra (external repo) | 🚧 Experimental, needs optimisation |

---

## 🔧 Mastra Setup (AI Agent)

The AI agent is hosted in a **separate repository**:
👉 [github.com/jithin-raj-rv/AI-workflow-Experiments](https://github.com/jithin-raj-rv/AI-workflow-Experiments/tree/master/Mastra%20for%20todo)

### Setup Steps

```bash
# 1. Clone the Mastra experiments repo
git clone https://github.com/jithin-raj-rv/AI-workflow-Experiments.git
cd "AI-workflow-Experiments/Mastra for todo"

# 2. Start Mastra dev server
npx mastra dev

# 3. In a separate terminal, run the tunnel script
#    This exposes your local Mastra to the internet via tunnel.bat
./tunnel.bat
#    Note: On Windows, double-click tunnel.bat or run from cmd

# 4. Get the public URL from tunnel output (e.g., https://xxx.ngrok.io or similar)

# 5. Update your Supabase configuration with this URL
#    (The Flutter app talks to Supabase, which forwards AI requests to Mastra)
```

> **⚠️ Status**: Mastra integration is **experimental**. The concept works but requires more iterations, testing, and optimisation for production use. If you improve this setup, please share your changes!

---

## 🚀 Quick Start (Flutter App)

### Prerequisites
- Flutter SDK 3.19.0+
- Dart 3.3.0+
- Node.js 18+ (for Supabase CLI)
- Supabase CLI
- A Supabase project (free tier works)

### Installation

```bash
# Clone this repo
git clone https://github.com/jithin-raj-rv/what_to_do-wtd-.git
cd what_to_do(wtd)

# Install dependencies
flutter pub get

# Set up Supabase
supabase login
supabase init
supabase start
supabase db push

# Deploy Edge Functions
supabase functions deploy
```

### Environment Variables

Create a `.env` file:

```env
# Supabase
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key

# OpenRouter (if using legacy Edge Function fallback)
OPENROUTER_API_KEY=your_openrouter_api_key
```

### Run

```bash
flutter run
```

---

## 📊 What Works / What Needs Work

### ✅ Working
- User authentication (login/signup)
- Todo management with Eisenhower Matrix
- Goal tracking with progress milestones
- Goal step breakdown
- Timer-based prompts
- Multi-modal reminders (basic, options, answer-back, AI prompts)
- Local caching with offline support
- Real-time sync with Supabase
- Dark/Light theme
- System prompt customization

### 🚧 Experimental / Needs Work
- **Mastra AI agent** — core concept works but needs:
  - More iterations on agent prompts
  - Performance optimisation
  - Better error handling for tunnel interruptions
  - Production deployment strategy (instead of local tunnel)
- **Edge Functions** (OpenRouter) — stripped down, kept as fallback only
- **Full AI transparency UI** — backend works, frontend needs polish

---

## 📂 Database Schema

| Table | Purpose |
|---|---|
| `todos` | Task management with Eisenhower Matrix classification |
| `goals` | Long-term objectives with target dates |
| `goal_steps` | Breakdown of goals into actionable steps |
| `timer_prompts` | AI-driven scheduled prompts |
| `reminders` | Notification system (basic, options, answer-back, AI) |
| `user_feedback` | User interactions and AI response tracking |
| `personality_traits` | User preferences and behavior patterns |
| `additional_info` | Extended user context |
| `system_prompts` | AI behaviour configuration |

---

## 💡 Lessons Learned

1. **Supabase Edge Functions** aren't designed for long-running AI agentic workflows — timeouts and cold starts are real constraints.
2. **Agentic AI** is fundamentally different from simple API calls — you need proper frameworks (like Mastra) for multi-step reasoning.
3. **Free API tiers** can disappear or change limits without warning — always have a fallback.
4. **Building without spending money** is possible but forces creative workarounds that sometimes become features.
5. **Full data transparency** with AI is hard to implement well — but users deserve to know what the AI knows about them.

---

## 🤝 Contributing

This project was built for learning, and I'd love to see what others do with it!

If you:
- Fork this project and improve it
- Optimise the Mastra setup
- Fix a bug or add a feature
- Use this concept in your own project

**Please share your source code!** Drop a link in Issues or Discussions so this mini-project can keep evolving.

---

## 🔗 Links

<!-- 
  Uncomment and update these when you have them ready
  
  ## 📬 Contact
  - Email: your.email@example.com
  - Twitter: @yourhandle
  - Discord: your-server-link
-->

- **Flutter App Repo**: [github.com/jithin-raj-rv/what_to_do-wtd-](https://github.com/jithin-raj-rv/what_to_do-wtd-)
- **Mastra AI Experiments**: [github.com/jithin-raj-rv/AI-workflow-Experiments](https://github.com/jithin-raj-rv/AI-workflow-Experiments/tree/master/Mastra%20for%20todo)
- **Issues**: [github.com/jithin-raj-rv/what_to_do-wtd-/issues](https://github.com/jithin-raj-rv/what_to_do-wtd-/issues)
- **Discussions**: [github.com/jithin-raj-rv/what_to_do-wtd-/discussions](https://github.com/jithin-raj-rv/what_to_do-wtd-/discussions)

---

## 📄 License

MIT License — feel free to use, modify, and share. If you build something cool, I'd love to hear about it!

---

> *"The thrill of building this without spending a dime made it more fun than any fully-funded project could ever be."*