import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { google } from "https://esm.sh/googleapis@128.0.0";

const FCM_SCOPES = ["https://www.googleapis.com/auth/firebase.messaging"];

// Function to get a Google Auth client
function getGoogleAuthClient() {
  const serviceAccount = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_KEY");
  if (!serviceAccount) {
    throw new Error("FIREBASE_SERVICE_ACCOUNT_KEY environment variable not set.");
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
    const { record: reminder } = await req.json();

    if (!reminder || !reminder.user_id) {
      return new Response(JSON.stringify({ error: "Invalid reminder data" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // Fetch FCM tokens for the user
    const { data: devices, error: devicesError } = await supabaseAdmin
      .from("user_devices")
      .select("fcm_token")
      .eq("user_id", reminder.user_id);

    if (devicesError) {
      console.error("Error fetching devices:", devicesError);
      throw devicesError;
    }

    if (!devices || devices.length === 0) {
      console.log(`No devices found for user ${reminder.user_id}`);
      return new Response(JSON.stringify({ message: "No devices to notify" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    const authClient = getGoogleAuthClient();
    const accessToken = await authClient.getAccessToken();
    const serviceAccount = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT_KEY")!);
    const firebaseProjectId = serviceAccount.project_id;

    const fcmEndpoint = `https://fcm.googleapis.com/v1/projects/${firebaseProjectId}/messages:send`;
    
    // Determine notification title and body based on event type
    const eventType = reminder.event_type || 'UPDATE';
    let notificationTitle = '';
    let notificationBody = '';
    
    switch (eventType) {
      case 'INSERT':
        notificationTitle = 'New Reminder Added';
        notificationBody = `Reminder: ${reminder.title}`;
        break;
      case 'UPDATE':
        notificationTitle = 'Reminder Updated';
        notificationBody = `Updated: ${reminder.title}`;
        break;
      case 'DELETE':
        notificationTitle = 'Reminder Deleted';
        notificationBody = `Deleted: ${reminder.title}`;
        break;
      default:
        notificationTitle = 'Reminder Changed';
        notificationBody = `${reminder.title}`;
    }

    // Send a notification to each device
    const sendPromises = devices.map(async (device: { fcm_token: string }) => {
      const message = {
        message: {
          token: device.fcm_token,
          notification: {
            title: notificationTitle,
            body: notificationBody,
          },
          data: {
            // Pass the entire reminder record to the app
            ...Object.fromEntries(
              Object.entries(reminder).map(([key, value]) => [key, String(value)])
            ),
            // Add event type for the app to handle appropriately
            event_type: eventType,
          },
        },
      };

      try {
        const response = await fetch(fcmEndpoint, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${accessToken.token}`,
          },
          body: JSON.stringify(message),
        });

        if (!response.ok) {
          const errorBody = await response.text();
          console.error(`FCM send failed for token ${device.fcm_token}: ${response.status} ${errorBody}`);
        } else {
          console.log(`Successfully sent ${eventType} FCM message to token ${device.fcm_token} for reminder ${reminder.id}`);
        }
      } catch (error: unknown) {
        console.error(`Error sending FCM message to ${device.fcm_token}:`, error);
      }
    });

    await Promise.all(sendPromises);

    return new Response(JSON.stringify({ 
      message: "Notifications sent",
      event_type: eventType,
      reminder_id: reminder.id 
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
