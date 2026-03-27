# Deployment Guide for process-prompt Function

## Overview

This guide will help you properly deploy the updated `process-prompt` function to resolve the `AI_InvalidPromptError`.

## Prerequisites

- Supabase project with Functions enabled
- Access to Supabase CLI
- Node.js installed locally

## Step 1: Deploy the Updated Function

### Option A: Using Supabase CLI (Recommended)

1. **Navigate to your project directory:**
   ```bash
   cd c:/Jithin/Files for Projects/to_do_list
   ```

2. **Login to Supabase CLI:**
   ```bash
   supabase login
   ```

3. **Link your project:**
   ```bash
   supabase link --project-ref YOUR_PROJECT_REF
   ```
   Replace `YOUR_PROJECT_REF` with your actual Supabase project reference.

4. **Deploy the function:**
   ```bash
   supabase functions deploy process-prompt
   ```

**Note:** You may see TypeScript errors in your editor about missing modules, but these won't affect the actual function deployment since Supabase functions use the `npm:` prefix for external dependencies.

### Option B: Using Supabase Dashboard

1. **Go to your Supabase Dashboard**
2. **Navigate to Functions**
3. **Find the `process-prompt` function**
4. **Click "Edit"**
5. **Replace the entire function code** with the updated code from `supabase/functions/process-prompt/index.ts`
6. **Click "Save"**

## Step 2: Verify Deployment

### Check Function Status

1. **Using CLI:**
   ```bash
   supabase functions list
   ```

2. **Using Dashboard:**
   - Go to Functions in your Supabase Dashboard
   - Check that `process-prompt` shows as "Deployed"

### Test the Function

1. **Using curl:**
   ```bash
   curl -X POST https://YOUR_PROJECT_REF.supabase.co/functions/v1/process-prompt \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer YOUR_JWT_TOKEN" \
     -d '{
       "userInput": "Test message",
       "chatHistory": [
         {
           "role": "user",
           "content": "Hello"
         }
       ]
     }'
   ```

2. **Expected Response:**
   ```json
   {
     "response": "Hello! How can I help you today?"
   }
   ```

## Step 3: Test with Problematic Chat History

Test the function with the problematic chat history that was causing the error:

```bash
curl -X POST https://YOUR_PROJECT_REF.supabase.co/functions/v1/process-prompt \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "userInput": "Test message",
    "chatHistory": [
      {
        "role": "user",
        "content": "hoii"
      },
      {
        "role": "assistant",
        "content": "Exception: Server temporarily unavailable. Please try again later."
      },
      {
        "role": "user",
        "content": "hoiiii"
      },
      {
        "role": "assistant",
        "content": "Exception: Server temporarily unavailable. Please try again later."
      }
    ]
  }'
```

**Expected Result:** The function should now filter out the error messages and process the valid user messages.

## Step 4: Monitor Function Logs

### Using Supabase Dashboard

1. **Go to Functions**
2. **Click on `process-prompt`**
3. **View Logs** to see the validation messages

### Expected Log Messages

You should see logs like:
```
[process-prompt] Validating chat history with 4 messages
[process-prompt] Skipping error message at index 1: Exception: Server temporarily unavailable. Please try again later.
[process-prompt] Skipping error message at index 3: Exception: Server temporarily unavailable. Please try again later.
[process-prompt] Chat history validation complete: 4 input messages -> 2 valid messages
[process-prompt] Final conversation history: 2 messages
```

## Step 5: Troubleshooting

### Common Issues

1. **Function not deploying:**
   - Check that you're logged into the correct Supabase project
   - Ensure you have the necessary permissions
   - Verify your internet connection

2. **Function still returning errors:**
   - Check the function logs in the Supabase Dashboard
   - Verify that the environment variables are set correctly:
     - `SUPABASE_URL`
     - `SUPABASE_SERVICE_ROLE_KEY`
     - `GEMINI_API_KEY`

3. **Environment Variables Not Set:**
   - Go to your Supabase Dashboard
   - Navigate to Settings > Config
   - Add the required environment variables

### Environment Variables Required

- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY`: Your Supabase service role key
- `GOOGLE_GENERATIVE_AI_API_KEY`: Your Google Gemini API key (Note: Use this instead of GEMINI_API_KEY)

## Step 6: Verify Fix

After deployment, test your application again. The `AI_InvalidPromptError` should now be resolved.

### What the Fix Does

1. **Comprehensive Error Pattern Matching:** Catches all variations of error messages
2. **Content Quality Validation:** Ensures messages are actual conversational content
3. **Fallback Mechanisms:** Handles cases where validation fails completely
4. **Enhanced Logging:** Provides detailed information for debugging

### Key Improvements

- Filters out error messages like "Exception: Server temporarily unavailable"
- Validates message structure and content quality
- Provides detailed logging for troubleshooting
- Includes fallback mechanisms for edge cases

## Support

If you continue to experience issues:

1. **Check the function logs** in your Supabase Dashboard
2. **Verify all environment variables** are correctly set
3. **Test with the curl commands** provided above
4. **Share the function logs** if you need further assistance

The enhanced validation should now handle all the problematic chat history patterns that were causing the `AI_InvalidPromptError`.