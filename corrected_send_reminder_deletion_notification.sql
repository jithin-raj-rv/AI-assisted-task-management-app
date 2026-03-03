DECLARE
  project_url TEXT := 'https://wxmqwlumweeviifzqktz.supabase.co'; -- Your actual project URL
  service_role_key TEXT;
BEGIN
  -- Get the service role key from settings
  service_role_key := current_setting('app.settings.service_role_key', true);

  -- Check if service role key is configured
  IF service_role_key IS NULL OR service_role_key = '' THEN
    RAISE WARNING '[send_reminder_deletion_notification] Notification not sent: app.settings.service_role_key is not configured.';
    RETURN OLD;
  END IF;

  -- Send the notification
  BEGIN
    PERFORM net.http_post(
      url := project_url || '/functions/v1/send-reminder-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || service_role_key
      ),
      body := jsonb_build_object(
        'record', OLD,
        'event_type', 'DELETE'
      )
    );
  EXCEPTION
    WHEN OTHERS THEN
      RAISE WARNING '[send_reminder_deletion_notification] Failed to send notification: %', SQLERRM;
  END;

  RETURN OLD;
END;
