# Database Schema Documentation

This document provides comprehensive documentation of the database schema used in the AI-powered productivity application, including table structures, relationships, constraints, and migration scripts.

## Table of Contents

1. [Database Overview](#database-overview)
2. [Table Schemas](#table-schemas)
3. [Relationships and Constraints](#relationships-and-constraints)
4. [Indexes and Performance](#indexes-and-performance)
5. [Row Level Security (RLS)](#row-level-security-rls)
6. [Triggers and Functions](#triggers-and-functions)
7. [Migration Scripts](#migration-scripts)
8. [Data Validation Rules](#data-validation-rules)

## Database Overview

### Database System
- **Database**: PostgreSQL (managed by Supabase)
- **Storage**: Supabase Storage for file attachments
- **Real-time**: Supabase Real-time subscriptions
- **Authentication**: Supabase Auth integration

### Schema Structure
```
public schema:
├── todos                    # Task management
├── goals                    # Long-term objectives
├── goal_steps               # Goal breakdown into steps
├── timer_prompts            # AI prompt scheduling
├── reminders                # Notification system
├── user_feedback            # User interactions with AI
├── personality_traits       # User preferences and traits
├── additional_info          # User context information
├── system_prompts           # AI configuration
└── profiles                 # User profiles (Supabase Auth)
```

### Data Flow
```
User Input → Application → Supabase API → PostgreSQL Database
     ↑                                    ↓
     ←────── Real-time Subscriptions ←─────
```

## Table Schemas

### 1. todos

Task management table for the Eisenhower Matrix-based todo list.

```sql
CREATE TABLE todos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    task_name VARCHAR(255) NOT NULL,
    description TEXT DEFAULT '',
    due_date TIMESTAMP WITH TIME ZONE,
    is_completed BOOLEAN DEFAULT FALSE,
    importance VARCHAR(20) NOT NULL CHECK (importance IN ('IMPORTANT', 'NOT IMPORTANT')),
    urgency VARCHAR(20) NOT NULL CHECK (urgency IN ('URGENT', 'NOT URGENT')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_synced BOOLEAN DEFAULT FALSE,
    last_sync_attempt TIMESTAMP WITH TIME ZONE
);
```

**Fields Description:**
- `id`: Unique identifier (UUID)
- `user_id`: Foreign key to auth.users table
- `task_name`: Task title (max 255 chars)
- `description`: Optional task description
- `due_date`: Task deadline (nullable)
- `is_completed`: Completion status
- `importance`: Task importance level
- `urgency`: Task urgency level
- `created_at`: Creation timestamp
- `updated_at`: Last modification timestamp
- `is_synced`: Sync status with cloud
- `last_sync_attempt`: Last sync attempt timestamp

**Constraints:**
- Importance must be 'IMPORTANT' or 'NOT IMPORTANT'
- Urgency must be 'URGENT' or 'NOT URGENT'
- User_id references auth.users with cascade delete

### 2. goals

Long-term objectives table for goal tracking.

```sql
CREATE TABLE goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT DEFAULT '',
    target_date TIMESTAMP WITH TIME ZONE,
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Fields Description:**
- `id`: Unique identifier (UUID)
- `user_id`: Foreign key to auth.users table
- `title`: Goal title (max 255 chars)
- `description`: Optional goal description
- `target_date`: Goal completion deadline
- `is_completed`: Goal completion status
- `created_at`: Creation timestamp
- `updated_at`: Last modification timestamp

### 3. goal_steps

Breakdown of goals into actionable steps.

```sql
CREATE TABLE goal_steps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    goal_id UUID NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
    step_text TEXT NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Fields Description:**
- `id`: Unique identifier (UUID)
- `user_id`: Foreign key to auth.users table
- `goal_id`: Foreign key to goals table
- `step_text`: Step description
- `is_completed`: Step completion status
- `sort_order`: Order of steps (integer)
- `created_at`: Creation timestamp
- `updated_at`: Last modification timestamp

**Constraints:**
- Each step belongs to exactly one goal
- Steps are ordered by sort_order

### 4. timer_prompts

AI-driven scheduled prompts table.

```sql
CREATE TABLE timer_prompts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    prompt TEXT NOT NULL,
    scheduled_time TIMESTAMP WITH TIME ZONE NOT NULL,
    recurring_type VARCHAR(20) DEFAULT 'never' CHECK (recurring_type IN ('never', 'daily', 'weekly')),
    weekdays JSONB, -- Array of integers 1-7 representing Monday-Sunday
    response TEXT,
    sent BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Fields Description:**
- `id`: Unique identifier (UUID)
- `user_id`: Foreign key to auth.users table
- `prompt`: AI prompt text
- `scheduled_time`: When the prompt should execute
- `recurring_type`: Recurrence pattern
- `weekdays`: JSON array of weekday numbers (1=Monday, 7=Sunday)
- `response`: AI response text
- `sent`: Whether prompt has been sent/executed
- `created_at`: Creation timestamp
- `updated_at`: Last modification timestamp

**Constraints:**
- Weekdays is JSON array when recurring_type is 'weekly'
- Scheduled time must be in the future

### 5. reminders

Smart notification system table.

```sql
CREATE TABLE reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    body TEXT,
    scheduled_date TIMESTAMP WITH TIME ZONE NOT NULL,
    reminder_type VARCHAR(20) NOT NULL CHECK (reminder_type IN ('basic', 'option', 'answer_back', 'ai_prompt')),
    options JSONB, -- Array of strings for option-type reminders
    expected_answer TEXT, -- Expected answer for answer_back type
    ai_prompt TEXT, -- AI prompt for ai_prompt type
    payload TEXT, -- Notification payload
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Fields Description:**
- `id`: Unique identifier (UUID)
- `user_id`: Foreign key to auth.users table
- `title`: Reminder title
- `body`: Optional reminder body text
- `scheduled_date`: When reminder should trigger
- `reminder_type`: Type of reminder interaction
- `options`: JSON array of options for option-type
- `expected_answer`: Expected response for answer_back
- `ai_prompt`: AI prompt for ai_prompt type
- `payload`: Notification payload
- `created_at`: Creation timestamp
- `updated_at`: Last modification timestamp

**Constraints:**
- Reminder type determines which fields are required
- Options is JSON array for option-type reminders

### 6. user_feedback

User interactions and feedback with AI.

```sql
CREATE TABLE user_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    feedback TEXT NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    context JSONB, -- Additional context about the feedback
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Fields Description:**
- `id`: Unique identifier (UUID)
- `user_id`: Foreign key to auth.users table
- `feedback`: User feedback text
- `timestamp`: When feedback was provided
- `context`: JSON object with additional context
- `created_at`: Creation timestamp

### 7. personality_traits

User personality and preference traits.

```sql
CREATE TABLE personality_traits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    trait TEXT NOT NULL,
    value TEXT, -- Optional value for the trait
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Fields Description:**
- `id`: Unique identifier (UUID)
- `user_id`: Foreign key to auth.users table
- `trait`: Trait description
- `value`: Optional trait value
- `created_at`: Creation timestamp

### 8. additional_info

Additional user context and information.

```sql
CREATE TABLE additional_info (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    info TEXT NOT NULL,
    category VARCHAR(50), -- Optional category
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Fields Description:**
- `id`: Unique identifier (UUID)
- `user_id`: Foreign key to auth.users table
- `info`: Additional information text
- `category`: Optional information category
- `created_at`: Creation timestamp

### 9. system_prompts

AI system prompt configuration.

```sql
CREATE TABLE system_prompts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    system_timer_prompt TEXT, -- Custom system prompt for timer prompts
    system_chat_prompt TEXT, -- Custom system prompt for chat
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Fields Description:**
- `id`: Unique identifier (UUID)
- `user_id`: Foreign key to auth.users table
- `system_timer_prompt`: Custom prompt for timer-based AI interactions
- `system_chat_prompt`: Custom prompt for chat-based AI interactions
- `created_at`: Creation timestamp
- `updated_at`: Last modification timestamp

**Constraints:**
- Each user can have only one system prompt configuration
- Unique constraint on user_id

## Relationships and Constraints

### Foreign Key Relationships

```sql
-- todos → auth.users
ALTER TABLE todos ADD CONSTRAINT fk_todos_user_id 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- goals → auth.users
ALTER TABLE goals ADD CONSTRAINT fk_goals_user_id 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- goal_steps → auth.users
ALTER TABLE goal_steps ADD CONSTRAINT fk_goal_steps_user_id 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- goal_steps → goals
ALTER TABLE goal_steps ADD CONSTRAINT fk_goal_steps_goal_id 
FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE CASCADE;

-- timer_prompts → auth.users
ALTER TABLE timer_prompts ADD CONSTRAINT fk_timer_prompts_user_id 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- reminders → auth.users
ALTER TABLE reminders ADD CONSTRAINT fk_reminders_user_id 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- user_feedback → auth.users
ALTER TABLE user_feedback ADD CONSTRAINT fk_user_feedback_user_id 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- personality_traits → auth.users
ALTER TABLE personality_traits ADD CONSTRAINT fk_personality_traits_user_id 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- additional_info → auth.users
ALTER TABLE additional_info ADD CONSTRAINT fk_additional_info_user_id 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- system_prompts → auth.users
ALTER TABLE system_prompts ADD CONSTRAINT fk_system_prompts_user_id 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
```

### Unique Constraints

```sql
-- Each user can have only one system prompt configuration
ALTER TABLE system_prompts ADD CONSTRAINT uk_system_prompts_user_id 
UNIQUE (user_id);
```

### Check Constraints

```sql
-- Importance values
ALTER TABLE todos ADD CONSTRAINT chk_todos_importance 
CHECK (importance IN ('IMPORTANT', 'NOT IMPORTANT'));

-- Urgency values
ALTER TABLE todos ADD CONSTRAINT chk_todos_urgency 
CHECK (urgency IN ('URGENT', 'NOT URGENT'));

-- Reminder types
ALTER TABLE reminders ADD CONSTRAINT chk_reminders_type 
CHECK (reminder_type IN ('basic', 'option', 'answer_back', 'ai_prompt'));

-- Recurring types
ALTER TABLE timer_prompts ADD CONSTRAINT chk_timer_prompts_recurring 
CHECK (recurring_type IN ('never', 'daily', 'weekly'));
```

## Indexes and Performance

### Primary Indexes

```sql
-- Primary keys (automatically indexed)
-- todos(id), goals(id), goal_steps(id), etc.

-- Foreign key indexes
CREATE INDEX idx_todos_user_id ON todos(user_id);
CREATE INDEX idx_goals_user_id ON goals(user_id);
CREATE INDEX idx_goal_steps_user_id ON goal_steps(user_id);
CREATE INDEX idx_goal_steps_goal_id ON goal_steps(goal_id);
CREATE INDEX idx_timer_prompts_user_id ON timer_prompts(user_id);
CREATE INDEX idx_reminders_user_id ON reminders(user_id);
CREATE INDEX idx_user_feedback_user_id ON user_feedback(user_id);
CREATE INDEX idx_personality_traits_user_id ON personality_traits(user_id);
CREATE INDEX idx_additional_info_user_id ON additional_info(user_id);
CREATE INDEX idx_system_prompts_user_id ON system_prompts(user_id);
```

### Performance Indexes

```sql
-- Todo completion status and priority
CREATE INDEX idx_todos_completion_priority ON todos(is_completed, importance, urgency);

-- Goal completion status
CREATE INDEX idx_goals_completion ON goals(is_completed);

-- Goal steps completion and order
CREATE INDEX idx_goal_steps_completion_order ON goal_steps(is_completed, sort_order);

-- Timer prompts scheduling
CREATE INDEX idx_timer_prompts_scheduled ON timer_prompts(scheduled_time);
CREATE INDEX idx_timer_prompts_sent ON timer_prompts(sent);

-- Reminders scheduling
CREATE INDEX idx_reminders_scheduled ON reminders(scheduled_date);

-- User feedback timestamp
CREATE INDEX idx_user_feedback_timestamp ON user_feedback(timestamp);

-- Composite indexes for common queries
CREATE INDEX idx_todos_user_completion ON todos(user_id, is_completed);
CREATE INDEX idx_goals_user_completion ON goals(user_id, is_completed);
CREATE INDEX idx_reminders_user_scheduled ON reminders(user_id, scheduled_date);
```

### Partial Indexes

```sql
-- Index only incomplete todos for better performance
CREATE INDEX idx_todos_incomplete ON todos(user_id) WHERE is_completed = FALSE;

-- Index only future reminders
CREATE INDEX idx_reminders_future ON reminders(user_id, scheduled_date) 
WHERE scheduled_date > NOW();

-- Index only unsent timer prompts
CREATE INDEX idx_timer_prompts_unsent ON timer_prompts(user_id, scheduled_time) 
WHERE sent = FALSE;
```

## Row Level Security (RLS)

### RLS Policies

```sql
-- Enable RLS on all tables
ALTER TABLE todos ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE goal_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE timer_prompts ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE personality_traits ENABLE ROW LEVEL SECURITY;
ALTER TABLE additional_info ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_prompts ENABLE ROW LEVEL SECURITY;

-- Policies for authenticated users only
CREATE POLICY "Users can access their own todos" ON todos
FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can access their own goals" ON goals
FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can access their own goal steps" ON goal_steps
FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can access their own timer prompts" ON timer_prompts
FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can access their own reminders" ON reminders
FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can access their own feedback" ON user_feedback
FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can access their own personality traits" ON personality_traits
FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can access their own additional info" ON additional_info
FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can access their own system prompts" ON system_prompts
FOR ALL USING (user_id = auth.uid());

-- Policies for inserts (users can only insert their own data)
CREATE POLICY "Users can insert their own todos" ON todos
FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can insert their own goals" ON goals
FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can insert their own goal steps" ON goal_steps
FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can insert their own timer prompts" ON timer_prompts
FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can insert their own reminders" ON reminders
FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can insert their own feedback" ON user_feedback
FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can insert their own personality traits" ON personality_traits
FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can insert their own additional info" ON additional_info
FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can insert their own system prompts" ON system_prompts
FOR INSERT WITH CHECK (user_id = auth.uid());
```

### RLS for System Prompts (Unique Constraint)

```sql
-- Allow update of existing system prompts but prevent duplicates
CREATE POLICY "Users can update their system prompts" ON system_prompts
FOR UPDATE USING (user_id = auth.uid());

-- Allow delete of existing system prompts
CREATE POLICY "Users can delete their system prompts" ON system_prompts
FOR DELETE USING (user_id = auth.uid());
```

## Triggers and Functions

### Update Timestamp Triggers

```sql
-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply to tables with updated_at columns
CREATE TRIGGER update_todos_updated_at 
BEFORE UPDATE ON todos 
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_goals_updated_at 
BEFORE UPDATE ON goals 
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_goal_steps_updated_at 
BEFORE UPDATE ON goal_steps 
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_timer_prompts_updated_at 
BEFORE UPDATE ON timer_prompts 
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reminders_updated_at 
BEFORE UPDATE ON reminders 
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_system_prompts_updated_at 
BEFORE UPDATE ON system_prompts 
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### Data Validation Triggers

```sql
-- Validate timer prompt weekdays when recurring_type is weekly
CREATE OR REPLACE FUNCTION validate_timer_prompt_weekdays()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.recurring_type = 'weekly' AND NEW.weekdays IS NULL THEN
        RAISE EXCEPTION 'Weekdays must be specified for weekly recurring prompts';
    END IF;
    
    IF NEW.recurring_type != 'weekly' AND NEW.weekdays IS NOT NULL THEN
        RAISE EXCEPTION 'Weekdays should only be specified for weekly recurring prompts';
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER validate_timer_prompt_weekdays_trigger
BEFORE INSERT OR UPDATE ON timer_prompts
FOR EACH ROW EXECUTE FUNCTION validate_timer_prompt_weekdays();

-- Validate reminder options when type is option
CREATE OR REPLACE FUNCTION validate_reminder_options()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.reminder_type = 'option' AND NEW.options IS NULL THEN
        RAISE EXCEPTION 'Options must be specified for option-type reminders';
    END IF;
    
    IF NEW.reminder_type != 'option' AND NEW.options IS NOT NULL THEN
        RAISE EXCEPTION 'Options should only be specified for option-type reminders';
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER validate_reminder_options_trigger
BEFORE INSERT OR UPDATE ON reminders
FOR EACH ROW EXECUTE FUNCTION validate_reminder_options();
```

### Cleanup Triggers

```sql
-- Automatically delete goal steps when goal is deleted
-- (Handled by CASCADE DELETE, but we can add additional logic if needed)

-- Function to clean up orphaned data
CREATE OR REPLACE FUNCTION cleanup_orphaned_data()
RETURNS void AS $$
BEGIN
    -- Delete goal steps with non-existent goals
    DELETE FROM goal_steps 
    WHERE goal_id NOT IN (SELECT id FROM goals);
    
    -- Delete system prompts for non-existent users (shouldn't happen with CASCADE)
    DELETE FROM system_prompts 
    WHERE user_id NOT IN (SELECT id FROM auth.users);
END;
$$ language 'plpgsql';

-- Schedule cleanup (can be called manually or via cron job)
-- SELECT cleanup_orphaned_data();
```

## Migration Scripts

### Initial Migration Script

```sql
-- migration_001_initial_schema.sql
-- Create all tables and initial constraints

BEGIN;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create todos table
CREATE TABLE todos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    task_name VARCHAR(255) NOT NULL,
    description TEXT DEFAULT '',
    due_date TIMESTAMP WITH TIME ZONE,
    is_completed BOOLEAN DEFAULT FALSE,
    importance VARCHAR(20) NOT NULL,
    urgency VARCHAR(20) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_synced BOOLEAN DEFAULT FALSE,
    last_sync_attempt TIMESTAMP WITH TIME ZONE
);

-- Create goals table
CREATE TABLE goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT DEFAULT '',
    target_date TIMESTAMP WITH TIME ZONE,
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create goal_steps table
CREATE TABLE goal_steps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    goal_id UUID NOT NULL,
    step_text TEXT NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create timer_prompts table
CREATE TABLE timer_prompts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    prompt TEXT NOT NULL,
    scheduled_time TIMESTAMP WITH TIME ZONE NOT NULL,
    recurring_type VARCHAR(20) DEFAULT 'never',
    weekdays JSONB,
    response TEXT,
    sent BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create reminders table
CREATE TABLE reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT,
    scheduled_date TIMESTAMP WITH TIME ZONE NOT NULL,
    reminder_type VARCHAR(20) NOT NULL,
    options JSONB,
    expected_answer TEXT,
    ai_prompt TEXT,
    payload TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create user_feedback table
CREATE TABLE user_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    feedback TEXT NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    context JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create personality_traits table
CREATE TABLE personality_traits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    trait TEXT NOT NULL,
    value TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create additional_info table
CREATE TABLE additional_info (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    info TEXT NOT NULL,
    category VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create system_prompts table
CREATE TABLE system_prompts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    system_timer_prompt TEXT,
    system_chat_prompt TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add foreign key constraints
ALTER TABLE todos ADD CONSTRAINT fk_todos_user_id 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE goals ADD CONSTRAINT fk_goals_user_id 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE goal_steps ADD CONSTRAINT fk_goal_steps_user_id 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE goal_steps ADD CONSTRAINT fk_goal_steps_goal_id 
FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE CASCADE;

ALTER TABLE timer_prompts ADD CONSTRAINT fk_timer_prompts_user_id 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE reminders ADD CONSTRAINT fk_reminders_user_id 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE user_feedback ADD CONSTRAINT fk_user_feedback_user_id 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE personality_traits ADD CONSTRAINT fk_personality_traits_user_id 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE additional_info ADD CONSTRAINT fk_additional_info_user_id 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE system_prompts ADD CONSTRAINT fk_system_prompts_user_id 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Add check constraints
ALTER TABLE todos ADD CONSTRAINT chk_todos_importance 
CHECK (importance IN ('IMPORTANT', 'NOT IMPORTANT'));

ALTER TABLE todos ADD CONSTRAINT chk_todos_urgency 
CHECK (urgency IN ('URGENT', 'NOT URGENT'));

ALTER TABLE reminders ADD CONSTRAINT chk_reminders_type 
CHECK (reminder_type IN ('basic', 'option', 'answer_back', 'ai_prompt'));

ALTER TABLE timer_prompts ADD CONSTRAINT chk_timer_prompts_recurring 
CHECK (recurring_type IN ('never', 'daily', 'weekly'));

-- Add unique constraint for system_prompts
ALTER TABLE system_prompts ADD CONSTRAINT uk_system_prompts_user_id 
UNIQUE (user_id);

-- Enable RLS
ALTER TABLE todos ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE goal_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE timer_prompts ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE personality_traits ENABLE ROW LEVEL SECURITY;
ALTER TABLE additional_info ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_prompts ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can access their own todos" ON todos
FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can access their own goals" ON goals
FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can access their own goal steps" ON goal_steps
FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can access their own timer prompts" ON timer_prompts
FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can access their own reminders" ON reminders
FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can access their own feedback" ON user_feedback
FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can access their own personality traits" ON personality_traits
FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can access their own additional info" ON additional_info
FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can access their own system prompts" ON system_prompts
FOR ALL USING (user_id = auth.uid());

-- Create insert policies
CREATE POLICY "Users can insert their own todos" ON todos
FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can insert their own goals" ON goals
FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can insert their own goal steps" ON goal_steps
FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can insert their own timer prompts" ON timer_prompts
FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can insert their own reminders" ON reminders
FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can insert their own feedback" ON user_feedback
FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can insert their own personality traits" ON personality_traits
FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can insert their own additional info" ON additional_info
FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can insert their own system prompts" ON system_prompts
FOR INSERT WITH CHECK (user_id = auth.uid());

-- Create update and delete policies for system_prompts
CREATE POLICY "Users can update their system prompts" ON system_prompts
FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can delete their system prompts" ON system_prompts
FOR DELETE USING (user_id = auth.uid());

-- Create update timestamp function and triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_todos_updated_at 
BEFORE UPDATE ON todos 
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_goals_updated_at 
BEFORE UPDATE ON goals 
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_goal_steps_updated_at 
BEFORE UPDATE ON goal_steps 
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_timer_prompts_updated_at 
BEFORE UPDATE ON timer_prompts 
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reminders_updated_at 
BEFORE UPDATE ON reminders 
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_system_prompts_updated_at 
BEFORE UPDATE ON system_prompts 
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create validation triggers
CREATE OR REPLACE FUNCTION validate_timer_prompt_weekdays()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.recurring_type = 'weekly' AND NEW.weekdays IS NULL THEN
        RAISE EXCEPTION 'Weekdays must be specified for weekly recurring prompts';
    END IF;
    
    IF NEW.recurring_type != 'weekly' AND NEW.weekdays IS NOT NULL THEN
        RAISE EXCEPTION 'Weekdays should only be specified for weekly recurring prompts';
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER validate_timer_prompt_weekdays_trigger
BEFORE INSERT OR UPDATE ON timer_prompts
FOR EACH ROW EXECUTE FUNCTION validate_timer_prompt_weekdays();

CREATE OR REPLACE FUNCTION validate_reminder_options()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.reminder_type = 'option' AND NEW.options IS NULL THEN
        RAISE EXCEPTION 'Options must be specified for option-type reminders';
    END IF;
    
    IF NEW.reminder_type != 'option' AND NEW.options IS NOT NULL THEN
        RAISE EXCEPTION 'Options should only be specified for option-type reminders';
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER validate_reminder_options_trigger
BEFORE INSERT OR UPDATE ON reminders
FOR EACH ROW EXECUTE FUNCTION validate_reminder_options();

-- Create indexes
CREATE INDEX idx_todos_user_id ON todos(user_id);
CREATE INDEX idx_todos_completion_priority ON todos(is_completed, importance, urgency);
CREATE INDEX idx_todos_incomplete ON todos(user_id) WHERE is_completed = FALSE;

CREATE INDEX idx_goals_user_id ON goals(user_id);
CREATE INDEX idx_goals_completion ON goals(is_completed);

CREATE INDEX idx_goal_steps_user_id ON goal_steps(user_id);
CREATE INDEX idx_goal_steps_goal_id ON goal_steps(goal_id);
CREATE INDEX idx_goal_steps_completion_order ON goal_steps(is_completed, sort_order);

CREATE INDEX idx_timer_prompts_user_id ON timer_prompts(user_id);
CREATE INDEX idx_timer_prompts_scheduled ON timer_prompts(scheduled_time);
CREATE INDEX idx_timer_prompts_sent ON timer_prompts(sent);
CREATE INDEX idx_timer_prompts_unsent ON timer_prompts(user_id, scheduled_time) WHERE sent = FALSE;

CREATE INDEX idx_reminders_user_id ON reminders(user_id);
CREATE INDEX idx_reminders_scheduled ON reminders(scheduled_date);
CREATE INDEX idx_reminders_future ON reminders(user_id, scheduled_date) WHERE scheduled_date > NOW();

CREATE INDEX idx_user_feedback_user_id ON user_feedback(user_id);
CREATE INDEX idx_user_feedback_timestamp ON user_feedback(timestamp);

CREATE INDEX idx_personality_traits_user_id ON personality_traits(user_id);
CREATE INDEX idx_additional_info_user_id ON additional_info(user_id);
CREATE INDEX idx_system_prompts_user_id ON system_prompts(user_id);

COMMIT;
```

### Migration Script for Adding New Features

```sql
-- migration_002_add_new_features.sql
-- Example migration for adding new features

BEGIN;

-- Add new column to todos table
ALTER TABLE todos ADD COLUMN priority_score INTEGER DEFAULT 0;

-- Create new table for habits
CREATE TABLE habits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    frequency VARCHAR(20) NOT NULL CHECK (frequency IN ('daily', 'weekly', 'monthly')),
    target_count INTEGER DEFAULT 1,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    consistency INTEGER DEFAULT 0, -- Percentage 0-100
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on new table
ALTER TABLE habits ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for habits
CREATE POLICY "Users can access their own habits" ON habits
FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own habits" ON habits
FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their habits" ON habits
FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can delete their habits" ON habits
FOR DELETE USING (user_id = auth.uid());

-- Create update timestamp trigger for habits
CREATE TRIGGER update_habits_updated_at 
BEFORE UPDATE ON habits 
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create indexes for habits
CREATE INDEX idx_habits_user_id ON habits(user_id);
CREATE INDEX idx_habits_active ON habits(user_id, is_active) WHERE is_active = TRUE;

COMMIT;
```

## Data Validation Rules

### Application-Level Validation

```dart
// Example validation rules from the application

class DataValidator {
  // Todo validation
  static bool isValidTodo(Todo todo) {
    return todo.taskName.isNotEmpty &&
           todo.taskName.length <= 255 &&
           ['IMPORTANT', 'NOT IMPORTANT'].contains(todo.importance) &&
           ['URGENT', 'NOT URGENT'].contains(todo.urgency) &&
           (todo.dueDate == null || todo.dueDate!.isAfter(DateTime.now().subtract(Duration(days: 365))));
  }

  // Goal validation
  static bool isValidGoal(Goal goal) {
    return goal.title.isNotEmpty &&
           goal.title.length <= 255 &&
           (goal.targetDate == null || goal.targetDate!.isAfter(DateTime.now()));
  }

  // Timer prompt validation
  static bool isValidTimerPrompt(TimerPrompt prompt) {
    return prompt.prompt.isNotEmpty &&
           prompt.scheduledTime.isAfter(DateTime.now()) &&
           (prompt.recurringType == 'never' || prompt.recurringType == 'daily' || prompt.recurringType == 'weekly') &&
           (prompt.recurringType != 'weekly' || (prompt.weekdays != null && prompt.weekdays!.isNotEmpty));
  }

  // Reminder validation
  static bool isValidReminder(Reminder reminder) {
    return reminder.title.isNotEmpty &&
           reminder.title.length <= 255 &&
           reminder.scheduledDate.isAfter(DateTime.now()) &&
           ['basic', 'option', 'answer_back', 'ai_prompt'].contains(reminder.reminderType) &&
           (reminder.reminderType != 'option' || (reminder.options != null && reminder.options!.isNotEmpty));
  }
}
```

### Database-Level Validation

```sql
-- Additional validation constraints that could be added

-- Ensure goal steps have valid sort order
ALTER TABLE goal_steps ADD CONSTRAINT chk_goal_steps_sort_order 
CHECK (sort_order >= 0);

-- Ensure timer prompt weekdays are valid (1-7)
ALTER TABLE timer_prompts ADD CONSTRAINT chk_timer_prompts_weekdays 
CHECK (recurring_type != 'weekly' OR (
    weekdays IS NOT NULL AND 
    jsonb_typeof(weekdays) = 'array' AND
    NOT EXISTS (
        SELECT 1 FROM jsonb_array_elements_text(weekdays) elem 
        WHERE elem::integer NOT BETWEEN 1 AND 7
    )
));

-- Ensure reminders have appropriate fields based on type
ALTER TABLE reminders ADD CONSTRAINT chk_reminders_fields 
CHECK (
    (reminder_type = 'basic' AND options IS NULL AND expected_answer IS NULL AND ai_prompt IS NULL) OR
    (reminder_type = 'option' AND options IS NOT NULL AND expected_answer IS NULL AND ai_prompt IS NULL) OR
    (reminder_type = 'answer_back' AND options IS NULL AND expected_answer IS NOT NULL AND ai_prompt IS NULL) OR
    (reminder_type = 'ai_prompt' AND options IS NULL AND expected_answer IS NULL AND ai_prompt IS NOT NULL)
);
```

This comprehensive database schema documentation provides all the necessary information for understanding, maintaining, and extending the database structure of the AI-powered productivity application. The schema is designed for scalability, security, and performance while maintaining data integrity through proper constraints and relationships.