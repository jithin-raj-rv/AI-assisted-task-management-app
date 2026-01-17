-- Timer Prompts Update Script
-- Run this to add timer prompt functionality to existing Supabase setup
-- Safe to run multiple times (uses IF NOT EXISTS where appropriate)

-- Enable required extensions (if not already enabled)
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Create Timer Prompts table
CREATE TABLE IF NOT EXISTS timer_prompts (
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

-- Enable RLS on timer prompts table
ALTER TABLE timer_prompts ENABLE ROW LEVEL SECURITY;

-- RLS Policies for Timer Prompts
DROP POLICY IF EXISTS "Users can view their own timer prompts" ON timer_prompts;
CREATE POLICY "Users can view their own timer prompts" ON timer_prompts FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own timer prompts" ON timer_prompts;
CREATE POLICY "Users can insert their own timer prompts" ON timer_prompts FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own timer prompts" ON timer_prompts;
CREATE POLICY "Users can update their own timer prompts" ON timer_prompts FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own timer prompts" ON timer_prompts;
CREATE POLICY "Users can delete their own timer prompts" ON timer_prompts FOR DELETE USING (auth.uid() = user_id);

-- Function to calculate next occurrence for recurring timer prompts
CREATE OR REPLACE FUNCTION calculate_next_timer_occurrence(
  scheduled_time TIMESTAMPTZ,
  is_recurring BOOLEAN,
  weekdays INTEGER[]
) RETURNS TIMESTAMPTZ AS $$
DECLARE
  next_time TIMESTAMPTZ;
  current_day INTEGER;
  target_days INTEGER[];
  i INTEGER;
  days_ahead INTEGER;
BEGIN
  IF NOT is_recurring OR weekdays IS NULL OR array_length(weekdays, 1) = 0 THEN
    RETURN scheduled_time;
  END IF;

  -- Get current day of week (1=Monday, 7=Sunday in ISO)
  current_day := EXTRACT(DOW FROM scheduled_time);
  IF current_day = 0 THEN current_day := 7; END IF; -- Convert Sunday from 0 to 7

  -- Find next occurrence
  days_ahead := 7; -- Maximum days to look ahead
  FOR i IN 1..7 LOOP
    IF current_day + i > 7 THEN
      current_day := (current_day + i) - 7;
    ELSE
      current_day := current_day + i;
    END IF;

    IF current_day = ANY(weekdays) THEN
      days_ahead := i;
      EXIT;
    END IF;
  END LOOP;

  -- Calculate next occurrence at same time
  next_time := scheduled_time + INTERVAL '1 day' * days_ahead;

  RETURN next_time;
END;
$$ LANGUAGE plpgsql;

-- Function to unschedule timer prompt execution (for deletions)
CREATE OR REPLACE FUNCTION unschedule_timer_prompt_execution()
RETURNS TRIGGER AS $$
DECLARE
  cron_job_name TEXT;
BEGIN
  -- Unschedule the cron job for the deleted timer prompt
  cron_job_name := 'timer_prompt_' || OLD.id;

  -- Use PERFORM to unschedule job (ignore error if job doesn't exist)
  BEGIN
    PERFORM cron.unschedule(cron_job_name);
  EXCEPTION
    WHEN OTHERS THEN
      -- Ignore error if job doesn't exist
      NULL;
  END;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to schedule timer prompt execution
CREATE OR REPLACE FUNCTION schedule_timer_prompt_execution()
RETURNS TRIGGER AS $$
DECLARE
  execution_time TIMESTAMPTZ;
  cron_job_name TEXT;
  edge_function_url TEXT;
  command_text TEXT;
BEGIN
  -- Only trigger on changes to prompt or scheduled_time
  IF (TG_OP = 'UPDATE') THEN
    IF OLD.prompt = NEW.prompt AND OLD.scheduled_time = NEW.scheduled_time THEN
      RETURN NEW;
    END IF;
  END IF;

  -- Calculate execution time
  IF NEW.is_recurring AND NEW.scheduled_time < NOW() THEN
    -- Past time, schedule next occurrence
    execution_time := calculate_next_timer_occurrence(NEW.scheduled_time, NEW.is_recurring, NEW.weekdays);
  ELSIF NEW.scheduled_time < NOW() AND NOT NEW.is_recurring THEN
    -- Past time and not recurring, skip
    RETURN NEW;
  ELSE
    execution_time := NEW.scheduled_time;
  END IF;

  -- Skip if still in past (shouldn't happen but safety check)
  IF execution_time < NOW() THEN
    RETURN NEW;
  END IF;

  cron_job_name := 'timer_prompt_' || NEW.id;

  -- Use PERFORM to clear old jobs (ignore error if job doesn't exist)
  BEGIN
    PERFORM cron.unschedule(cron_job_name);
  EXCEPTION
    WHEN OTHERS THEN
      -- Ignore error if job doesn't exist (for new inserts)
      NULL;
  END;

  -- 1. Correctly fetch project URL
  edge_function_url := 'https://' || current_setting('app.settings.supabase_url', true) || '/functions/v1/execute-timer-prompt';

  -- 2. Build the command string using format() to avoid quote confusion
  command_text := format(
    'SELECT net.http_post(url := %L, headers := jsonb_build_object(''Content-Type'', ''application/json'', ''Authorization'', ''Bearer '' || current_setting(''app.settings.service_role_key'', true)), body := jsonb_build_object(''timerPromptId'', %L));',
    edge_function_url,
    NEW.id
  );

  -- 3. Schedule the job using proper cron expression format: 'min hour day month dow'
  PERFORM cron.schedule(
    cron_job_name,
    format('%s %s %s %s %s',
      EXTRACT(MINUTE FROM execution_time),
      EXTRACT(HOUR FROM execution_time),
      EXTRACT(DAY FROM execution_time),
      EXTRACT(MONTH FROM execution_time),
      EXTRACT(DOW FROM execution_time)
    ),
    command_text
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to handle recurring timer prompt rescheduling
CREATE OR REPLACE FUNCTION reschedule_recurring_timer_prompt(timer_prompt_id TEXT)
RETURNS VOID AS $$
DECLARE
  prompt_record RECORD;
  next_execution TIMESTAMPTZ;
  cron_job_name TEXT;
  edge_function_url TEXT;
  command_text TEXT;
BEGIN
  -- Get timer prompt details
  SELECT * INTO prompt_record
  FROM timer_prompts
  WHERE id = timer_prompt_id;

  IF NOT FOUND OR NOT prompt_record.is_recurring THEN
    RETURN;
  END IF;

  -- Calculate next execution time
  next_execution := calculate_next_timer_occurrence(
    prompt_record.scheduled_time,
    prompt_record.is_recurring,
    prompt_record.weekdays
  );

  -- Delete existing cron job (ignore error if job doesn't exist)
  cron_job_name := 'timer_prompt_' || timer_prompt_id;
  BEGIN
    PERFORM cron.unschedule(cron_job_name);
  EXCEPTION
    WHEN OTHERS THEN
      -- Ignore error if job doesn't exist
      NULL;
  END;

  -- Build Edge Function URL
  edge_function_url := 'https://' || current_setting('app.settings.supabase_url', true) || '/functions/v1/execute-timer-prompt';

  -- Build the command string using format() to avoid quote confusion
  command_text := format(
    'SELECT net.http_post(url := %L, headers := jsonb_build_object(''Content-Type'', ''application/json'', ''Authorization'', ''Bearer '' || current_setting(''app.settings.service_role_key'', true)), body := jsonb_build_object(''timerPromptId'', %L));',
    edge_function_url,
    timer_prompt_id
  );

  -- Schedule the job using proper cron expression format: 'min hour day month dow'
  PERFORM cron.schedule(
    cron_job_name,
    format('%s %s %s %s %s',
      EXTRACT(MINUTE FROM next_execution),
      EXTRACT(HOUR FROM next_execution),
      EXTRACT(DAY FROM next_execution),
      EXTRACT(MONTH FROM next_execution),
      EXTRACT(DOW FROM next_execution)
    ),
    command_text
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create triggers
DROP TRIGGER IF EXISTS update_timer_prompts_updated_at ON timer_prompts;
CREATE TRIGGER update_timer_prompts_updated_at BEFORE UPDATE ON timer_prompts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS schedule_timer_prompt_trigger ON timer_prompts;
CREATE TRIGGER schedule_timer_prompt_trigger AFTER INSERT OR UPDATE ON timer_prompts FOR EACH ROW EXECUTE FUNCTION schedule_timer_prompt_execution();

DROP TRIGGER IF EXISTS unschedule_timer_prompt_trigger ON timer_prompts;
CREATE TRIGGER unschedule_timer_prompt_trigger BEFORE DELETE ON timer_prompts FOR EACH ROW EXECUTE FUNCTION unschedule_timer_prompt_execution();
