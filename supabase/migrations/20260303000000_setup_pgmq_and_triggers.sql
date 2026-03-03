-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS pgmq;
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;

-- Create the notification jobs queue
SELECT pgmq.create('notification_jobs');

-- Create trigger function for reminders to update user_devices
CREATE OR REPLACE FUNCTION public.update_device_status_on_reminder_change()
RETURNS TRIGGER AS $$
BEGIN
    -- When a reminder is created/updated, set user's devices to need scheduling
    UPDATE public.user_devices 
    SET is_scheduled = false, 
        is_sent = false,
        updated_at = NOW()
    WHERE user_id = COALESCE(NEW.user_id, OLD.user_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Replace existing triggers on reminders
DROP TRIGGER IF EXISTS send_reminder_notification_trigger ON public.reminders;
DROP TRIGGER IF EXISTS send_reminder_deletion_notification ON public.reminders;
DROP TRIGGER IF EXISTS on_reminder_change ON public.reminders;

CREATE TRIGGER on_reminder_change
    AFTER INSERT OR UPDATE OR DELETE ON public.reminders
    FOR EACH ROW
    EXECUTE FUNCTION public.update_device_status_on_reminder_change();

-- Create trigger function for user_devices
CREATE OR REPLACE FUNCTION public.process_user_device_changes()
RETURNS TRIGGER AS $$
BEGIN
    -- If is_scheduled = false AND is_sent = false -> wait 30 seconds, get reminders, send immediately
    IF NEW.is_scheduled = false AND NEW.is_sent = false AND (OLD.is_scheduled = true OR OLD.is_sent = true) THEN
        PERFORM pgmq.send(
            queue_name := 'notification_jobs',
            msg := jsonb_build_object(
                'user_id', NEW.user_id,
                'fcm_token', NEW.fcm_token,
                'action', 'immediate_send'
            ),
            delay := 30
        );
    -- If is_scheduled = false AND is_sent = true -> schedule and send with FCM
    ELSIF NEW.is_scheduled = false AND NEW.is_sent = true AND OLD.is_scheduled = true THEN
        PERFORM pgmq.send(
            queue_name := 'notification_jobs',
            msg := jsonb_build_object(
                'user_id', NEW.user_id,
                'fcm_token', NEW.fcm_token,
                'action', 'schedule_send'
            ),
            delay := 0
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_user_device_change ON public.user_devices;

CREATE TRIGGER on_user_device_change
    AFTER UPDATE ON public.user_devices
    FOR EACH ROW
    EXECUTE FUNCTION public.process_user_device_changes();

-- Function to read pgmq and trigger edge function
CREATE OR REPLACE FUNCTION public.process_notification_queue()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    project_url text;
    service_role_key text;
BEGIN
    project_url := current_setting('app.settings.project_url', true);
    service_role_key := current_setting('app.settings.service_role_key', true);
    
    -- If settings are missing, use hardcoded or fallback (update as needed)
    IF project_url IS NULL OR project_url = '' THEN
        project_url := 'https://wxmqwlumweeviifzqktz.supabase.co';
    END IF;

    -- Simply invoke the edge function, which will handle reading from pgmq
    PERFORM net.http_post(
        url := project_url || '/functions/v1/process-notification-queue',
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || COALESCE(service_role_key, 'anon')
        ),
        body := '{}'::jsonb
    );
END;
$$;

-- Schedule it to run frequently (cron supports down to minutes standard, but we'll run every minute to trigger the queue processor)
-- Using 1 minute as standard pg_cron format
SELECT cron.schedule('process-notification-queue-job', '* * * * *', 'SELECT public.process_notification_queue()');
