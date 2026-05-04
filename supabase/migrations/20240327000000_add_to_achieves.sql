-- Create to_achieves table
CREATE TABLE IF NOT EXISTS public.to_achieves (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    goal_id UUID NOT NULL REFERENCES public.goals(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    is_completed BOOLEAN NOT NULL DEFAULT false,
    priority_order INTEGER NOT NULL DEFAULT 0,
    target_date TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.to_achieves ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own to_achieves"
    ON public.to_achieves FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own to_achieves"
    ON public.to_achieves FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own to_achieves"
    ON public.to_achieves FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own to_achieves"
    ON public.to_achieves FOR DELETE
    USING (auth.uid() = user_id);

-- Create index
CREATE INDEX idx_to_achieves_goal_id ON public.to_achieves(goal_id);
CREATE INDEX idx_to_achieves_user_id ON public.to_achieves(user_id);

-- Add trigger for updated_at
CREATE TRIGGER set_to_achieves_updated_at
    BEFORE UPDATE ON public.to_achieves
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Remove target_date from goals
ALTER TABLE public.goals DROP COLUMN IF EXISTS target_date;
