-- Supabase Setup SQL
-- Run this in your Supabase SQL Editor

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create tables with RLS

-- Todos table
CREATE TABLE todos (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  task_name TEXT NOT NULL,
  is_completed BOOLEAN DEFAULT FALSE,
  importance TEXT NOT NULL,
  urgency TEXT NOT NULL,
  description TEXT NOT NULL,
  due_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Goals table
CREATE TABLE goals (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  target_date TIMESTAMPTZ,
  is_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Timer Prompts table
CREATE TABLE timer_prompts (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  prompt TEXT NOT NULL,
  response TEXT,
  scheduled_time TIMESTAMPTZ NOT NULL,
  is_recurring BOOLEAN DEFAULT FALSE,
  weekdays INTEGER[], -- Array of weekday numbers (1=Monday, 7=Sunday)
  sent BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Feedback table
CREATE TABLE user_feedback (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  feedback TEXT NOT NULL,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- User Profiles table
CREATE TABLE user_profiles (
  id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Personality Traits table
CREATE TABLE personality_traits (
  id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  trait TEXT NOT NULL,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Additional Information table
CREATE TABLE additional_info (
  id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  info TEXT NOT NULL,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Reminders table
CREATE TABLE reminders (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  body TEXT,
  scheduled_date TIMESTAMPTZ NOT NULL,
  payload TEXT NOT NULL,
  reminder_type TEXT,
  options JSONB,
  expected_answer TEXT,
  ai_prompt TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Settings table (for other settings)
CREATE TABLE user_settings (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  setting_key TEXT NOT NULL,
  setting_value JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, setting_key)
);

-- Enable RLS on all tables
ALTER TABLE todos ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE timer_prompts ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE personality_traits ENABLE ROW LEVEL SECURITY;
ALTER TABLE additional_info ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Todos
CREATE POLICY "Users can view their own todos" ON todos FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own todos" ON todos FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own todos" ON todos FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own todos" ON todos FOR DELETE USING (auth.uid() = user_id);

-- Goals
CREATE POLICY "Users can view their own goals" ON goals FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own goals" ON goals FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own goals" ON goals FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own goals" ON goals FOR DELETE USING (auth.uid() = user_id);

-- Timer Prompts
CREATE POLICY "Users can view their own timer prompts" ON timer_prompts FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own timer prompts" ON timer_prompts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own timer prompts" ON timer_prompts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own timer prompts" ON timer_prompts FOR DELETE USING (auth.uid() = user_id);

-- User Feedback
CREATE POLICY "Users can view their own feedback" ON user_feedback FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own feedback" ON user_feedback FOR INSERT WITH CHECK (auth.uid() = user_id);

-- User Profiles
CREATE POLICY "Users can view their own profile" ON user_profiles FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own profile" ON user_profiles FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own profile" ON user_profiles FOR UPDATE USING (auth.uid() = user_id);

-- Personality Traits
CREATE POLICY "Users can view their own personality traits" ON personality_traits FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own personality traits" ON personality_traits FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own personality traits" ON personality_traits FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own personality traits" ON personality_traits FOR DELETE USING (auth.uid() = user_id);

-- Additional Information
CREATE POLICY "Users can view their own additional info" ON additional_info FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own additional info" ON additional_info FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own additional info" ON additional_info FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own additional info" ON additional_info FOR DELETE USING (auth.uid() = user_id);

-- Reminders
CREATE POLICY "Users can view their own reminders" ON reminders FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own reminders" ON reminders FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own reminders" ON reminders FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own reminders" ON reminders FOR DELETE USING (auth.uid() = user_id);

-- User Settings
CREATE POLICY "Users can view their own settings" ON user_settings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own settings" ON user_settings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own settings" ON user_settings FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own settings" ON user_settings FOR DELETE USING (auth.uid() = user_id);

-- Functions for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers
CREATE TRIGGER update_todos_updated_at BEFORE UPDATE ON todos FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_goals_updated_at BEFORE UPDATE ON goals FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_timer_prompts_updated_at BEFORE UPDATE ON timer_prompts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_personality_traits_updated_at BEFORE UPDATE ON personality_traits FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_additional_info_updated_at BEFORE UPDATE ON additional_info FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_reminders_updated_at BEFORE UPDATE ON reminders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_settings_updated_at BEFORE UPDATE ON user_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
