import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { google } from "https://esm.sh/googleapis@128.0.0";

const FCM_SCOPES = ["https://www.googleapis.com/auth/firebase.messaging"];

// Function to get a Google Auth client
function getGoogleAuthClient() {
  const serviceAccount = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_KEY");
  if (!serviceAccount) {
    throw new Error("FIREBASE_SERVICE_URL environment variable not set or invalid.");
  }

  const jwtClient = new google.auth.JWT(
    JSON.parse(serviceAccount).client_email,
    undefined,
    JSON.parse(serviceAccount).private_key,
    FCM_SCOPES
  );
  return jwtClient;
}

serve(async (req) => {
  try {
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // Read jobs from pgmq using the wrapper rpc
    const { data: jobs, error: readError } = await supabaseAdmin
      .rpc('read_queue', { qname: 'notification_jobs' });

    if (readError) {
      console.error("Error reading from pgmq:", readError);
      throw readError;
    }

    if (!jobs || jobs.length === 0) {
      console.log("No notification jobs in queue.");
      return new Response(JSON.stringify({ message: "No jobs" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    console.log(`Processing ${jobs.length} jobs`);

    const authClient = getGoogleAuthClient();
    const accessToken = await authClient.getAccessToken();
    const serviceAccount = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT_KEY")!);
    const firebaseProjectId = serviceAccount.project_id;
    const fcmEndpoint = `https://fcm.googleapis.com/v1/projects/${firebaseProjectId}/messages:send`;

    for (const job of jobs) {
      try {
        const { msg_id, message } = job;
        const { user_id, fcm_token, action } = message;

        if (!user_id || !fcm_token || !action) {
           console.warn(`Invalid job message data: ${JSON.stringify(message)}`);
           continue;
        }

        // Fetch reminders for the user
        const { data: reminders, error: remindersError } = await supabaseAdmin
          .from("reminders")
          .select("*")
          .eq("user_id", user_id);

        if (remindersError) {
          console.error("Error fetching reminders:", remindersError);
          continue;
        }

        if (!reminders || reminders.length === 0) {
            console.log(`No reminders for user ${user_id}`);
            // Still mark as sent so we don't keep polling
            await supabaseAdmin.from('user_devices')
              .update({ is_sent: true })
              .eq('user_id', user_id)
              .eq('fcm_token', fcm_token);
            continue;
        }

        // Send FCM message for each reminder
        // For simplicity in sync, we could send a single data payload with reminders,
        // or just a signal to the app to sync. The prompt says: "use pg mq, and get the reminders for the user in, and then send"
        // Let's send a sync notification that will trigger the local app to pull reminders.
        
        const fcmMessage = {
          message: {
            token: fcm_token,
            data: {
              action: action, // 'immediate_send' or 'schedule_send'
              type: 'sync_reminders',
              reminders: JSON.stringify(reminders)
            },
          },
        };

        const response = await fetch(fcmEndpoint, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${accessToken.token}`,
          },
          body: JSON.stringify(fcmMessage),
        });

        if (!response.ok) {
          const errorBody = await response.text();
          console.error(`FCM send failed for token ${fcm_token}: ${response.status} ${errorBody}`);
        } else {
          console.log(`Successfully sent FCM message to token ${fcm_token} for user ${user_id}`);
          
          // Update device status to is_sent = true and is_scheduled = true (if it was a schedule request)
          const updates: any = { is_sent: true };
          if (action === 'schedule_send') {
              updates.is_scheduled = true;
          }

          await supabaseAdmin.from('user_devices')
            .update(updates)
            .eq('user_id', user_id)
            .eq('fcm_token', fcm_token);
        }
        
        // Delete message from queue upon successful processing
        await supabaseAdmin.rpc('delete_queue_job', { qname: 'notification_jobs', job_id: msg_id });

      } catch (e) {
          console.error(`Failed to process job ${job.msg_id}:`, e);
      }
    }

    return new Response(JSON.stringify({ 
      message: "Jobs processed",
      count: jobs.length
    }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });

  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    console.error("An unexpected error occurred:", errorMessage);
    return new Response(JSON.stringify({ error: errorMessage }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});