DECLARE
  project_url TEXT := 'https://wxmqwlumweeviifzqktz.supabase.co'; -- Your actual project URL
BEGIN
  -- Use a BEGIN/EXCEPTION block to gracefully handle any errors during the HTTP request.
  -- This ensures that a failure in the notification process does not block the primary database transaction.
  BEGIN
    PERFORM net.http_post(
      url := project_url || '/functions/v1/send-reminder-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
      ),
      body := jsonb_build_object(
        'record', NEW,
        'event_type', TG_OP -- TG_OP will be 'INSERT' or 'UPDATE'
      )
    );
  EXCEPTION
    WHEN OTHERS THEN
      RAISE WARNING '[send_reminder_notification_trigger] Failed to send notification: %', SQLERRM;
  END;

  RETURN NEW;
END;