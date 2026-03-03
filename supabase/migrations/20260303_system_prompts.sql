-- Create system_prompts table
CREATE TABLE IF NOT EXISTS public.system_prompts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    system_chat_prompt TEXT NOT NULL,
    system_timer_prompt TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create unique index to ensure one system prompt per user
CREATE UNIQUE INDEX IF NOT EXISTS idx_system_prompts_user_id_unique ON public.system_prompts(user_id);

-- Enable Row Level Security
ALTER TABLE public.system_prompts ENABLE ROW LEVEL SECURITY;

-- Create policies for system_prompts
DROP POLICY IF EXISTS "Users can view their own system prompts" ON public.system_prompts;
CREATE POLICY "Users can view their own system prompts" ON public.system_prompts
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own system prompts" ON public.system_prompts;
CREATE POLICY "Users can insert their own system prompts" ON public.system_prompts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own system prompts" ON public.system_prompts;
CREATE POLICY "Users can update their own system prompts" ON public.system_prompts
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own system prompts" ON public.system_prompts;
CREATE POLICY "Users can delete their own system prompts" ON public.system_prompts
    FOR DELETE USING (auth.uid() = user_id);

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_system_prompts_user_id ON public.system_prompts(user_id);

-- Create trigger function to create default system prompts on user creation
CREATE OR REPLACE FUNCTION public.create_default_system_prompts()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert default system prompts for the new user
    INSERT INTO public.system_prompts (user_id, system_chat_prompt, system_timer_prompt)
    VALUES 
        (NEW.id, 
         'You are a professional Personal manager. Help the user manage their tasks, goals, and reminders effectively.',
         'You are a timer prompt assistant. Help the user with scheduled AI prompts and task management.');
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically create default system prompts
DROP TRIGGER IF EXISTS on_auth_user_created_create_prompts ON auth.users;
CREATE TRIGGER on_auth_user_created_create_prompts
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.create_default_system_prompts();

-- Enable realtime for system_prompts table
ALTER PUBLICATION supabase_realtime ADD TABLE IF NOT EXISTS public.system_prompts;
