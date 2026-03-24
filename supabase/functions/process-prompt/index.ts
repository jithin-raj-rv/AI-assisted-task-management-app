import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from 'npm:@supabase/supabase-js@2'
import { generateText, jsonSchema } from 'npm:ai'
import { createGoogleGenerativeAI } from 'npm:@ai-sdk/google'
import { withSupermemory } from 'npm:@supermemory/tools/ai-sdk'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface FunctionArgs {
  userInput: string
  chatHistory?: Array<{ role: 'user' | 'model', content: string }>
}

// Helper function to convert time strings to UTC ISO timestamps
// Converts IST times (Indian Standard Time, UTC+5:30) to UTC for storage
// Also provides function to convert UTC to IST for AI prompts
const IST_OFFSET_HOURS = 5;
const IST_OFFSET_MINUTES = 30;

/**
 * Detect if the input timestamp is already in UTC
 */
function isUTC(timeValue: string): boolean {
  const upperTime = timeValue.toUpperCase();
  return (
    upperTime.endsWith('Z') ||
    upperTime.includes('+00') ||
    upperTime.includes('+00:00') ||
    upperTime.includes('-00') ||
    upperTime.includes('-00:00') ||
    upperTime.includes(' UTC')
  );
}

/**
 * Detect if the input timestamp is in IST (Indian Standard Time)
 */
function isIST(timeValue: string): boolean {
  const upperTime = timeValue.toUpperCase();
  return (
    upperTime.includes('IST') ||
    upperTime.includes('INDIA') ||
    upperTime.includes('+05:30') ||
    upperTime.includes('+05') ||
    upperTime.includes('-05:30') ||
    upperTime.includes('-05')
  );
}

/**
 * Convert UTC timestamp to IST for AI prompts
 * Returns the timestamp in IST format (UTC+5:30)
 */
function formatTimestampForAI(utcTimestamp: string | undefined): string | undefined {
  if (!utcTimestamp) return undefined;

  try {
    const date = new Date(utcTimestamp);
    if (isNaN(date.getTime())) return utcTimestamp;

    // Add IST offset to convert UTC to IST
    const istDate = new Date(date.getTime() + (IST_OFFSET_HOURS * 60 * 60 * 1000) + (IST_OFFSET_MINUTES * 60 * 1000));

    const year = istDate.getFullYear();
    const month = String(istDate.getMonth() + 1).padStart(2, '0');
    const day = String(istDate.getDate()).padStart(2, '0');
    const hours = String(istDate.getHours()).padStart(2, '0');
    const minutes = String(istDate.getMinutes()).padStart(2, '0');
    const seconds = String(istDate.getSeconds()).padStart(2, '0');

    return `${year}-${month}-${day}T${hours}:${minutes}:${seconds}+05:30`;
  } catch {
    return utcTimestamp;
  }
}

/**
 * Convert time strings to UTC ISO timestamps for storage
 * Converts IST times to UTC, keeps UTC as-is
 */
function formatTimestamp(timeValue: string | undefined): string | undefined {
  if (!timeValue) return undefined;

  // Check if it's already a full ISO timestamp with UTC timezone - return as-is
  if (timeValue.includes('T') && isUTC(timeValue)) {
    return timeValue;
  }

  // Check if it's IST and convert to UTC
  if (isIST(timeValue)) {
    // Remove timezone indicators from the string for parsing
    const cleanTimeValue = timeValue.replace(/IST|India|\+05:30|\+05|\-05:30|\-05/gi, '').trim();

    // Check if it's a time-only format (HH:MM:SS or HH:MM, with optional AM/PM)
    const timeWithAMPMRegex = /^(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(AM|PM)?$/i;
    const match = cleanTimeValue.match(timeWithAMPMRegex);

    if (match) {
      let hours = parseInt(match[1], 10);
      const minutes = parseInt(match[2], 10);
      const seconds = match[3] ? parseInt(match[3], 10) : 0;
      const ampm = match[4]?.toUpperCase();

      // Convert 12-hour format to 24-hour format
      if (ampm === 'PM' && hours !== 12) {
        hours += 12;
      } else if (ampm === 'AM' && hours === 12) {
        hours = 0;
      }

      // Create a date object with the time in IST
      const now = new Date();
      const istDate = new Date(now.getFullYear(), now.getMonth(), now.getDate(), hours, minutes, seconds);

      // Convert IST to UTC by subtracting the offset
      const utcDate = new Date(istDate.getTime() - (IST_OFFSET_HOURS * 60 * 60 * 1000) - (IST_OFFSET_MINUTES * 60 * 1000));

      const year = utcDate.getFullYear();
      const month = String(utcDate.getMonth() + 1).padStart(2, '0');
      const day = String(utcDate.getDate()).padStart(2, '0');
      const utcHours = String(utcDate.getHours()).padStart(2, '0');
      const utcMinutes = String(utcDate.getMinutes()).padStart(2, '0');
      const utcSeconds = String(utcDate.getSeconds()).padStart(2, '0');

      return `${year}-${month}-${day}T${utcHours}:${utcMinutes}:${utcSeconds}Z`;
    }
  }

  // Check if it's a time-only format without explicit timezone - assume IST
  const cleanTimeValue = timeValue.replace(/IST|India|utc|UTC/gi, '').trim();
  const timeWithAMPMRegex = /^(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(AM|PM)?$/i;
  const match = cleanTimeValue.match(timeWithAMPMRegex);

  if (match) {
    let hours = parseInt(match[1], 10);
    const minutes = parseInt(match[2], 10);
    const seconds = match[3] ? parseInt(match[3], 10) : 0;
    const ampm = match[4]?.toUpperCase();

    // Convert 12-hour format to 24-hour format
    if (ampm === 'PM' && hours !== 12) {
      hours += 12;
    } else if (ampm === 'AM' && hours === 12) {
      hours = 0;
    }

    // Create a date object with the time in IST
    const now = new Date();
    const istDate = new Date(now.getFullYear(), now.getMonth(), now.getDate(), hours, minutes, seconds);

    // Convert IST to UTC by subtracting the offset
    const utcDate = new Date(istDate.getTime() - (IST_OFFSET_HOURS * 60 * 60 * 1000) - (IST_OFFSET_MINUTES * 60 * 1000));

    const year = utcDate.getFullYear();
    const month = String(utcDate.getMonth() + 1).padStart(2, '0');
    const day = String(utcDate.getDate()).padStart(2, '0');
    const utcHours = String(utcDate.getHours()).padStart(2, '0');
    const utcMinutes = String(utcDate.getMinutes()).padStart(2, '0');
    const utcSeconds = String(utcDate.getSeconds()).padStart(2, '0');

    return `${year}-${month}-${day}T${utcHours}:${utcMinutes}:${utcSeconds}Z`;
  }

  // Return as-is if we can't parse it
  return timeValue;
}

Deno.serve(async (req: Request) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { userInput, chatHistory }: FunctionArgs = await req.json()

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

    // Get JWT from Authorization header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized - Missing Authorization header' }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 401,
        }
      )
    }

    // Extract and validate JWT token manually
    const jwt = authHeader.replace('Bearer ', '')
    let userId: string

    try {
      // Decode JWT payload
      const payload = JSON.parse(atob(jwt.split('.')[1]))
      userId = payload.sub

      if (!userId) {
        throw new Error('Invalid JWT payload - missing sub field')
      }

      // Basic token validation - check expiry
      const now = Math.floor(Date.now() / 1000)
      if (payload.exp && payload.exp < now) {
        throw new Error('Token expired')
      }

    } catch (error) {
      console.error('JWT validation error:', error)
      return new Response(
        JSON.stringify({ error: 'Session expired, Please sign in again.' }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 401,
        }
      )
    }

    // Initialize Supabase client with service role key for database operations
    const supabaseClient = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    })

    // Fetch user data
    const [todosRes, goalsRes, goalStepsRes, timerPromptsRes, feedbackRes, personalityRes, additionalInfoRes, remindersRes, systemPromptsRes] = await Promise.all([
      supabaseClient.from('todos').select('*').eq('user_id', userId),
      supabaseClient.from('goals').select('*').eq('user_id', userId),
      supabaseClient.from('goal_steps').select('*').eq('user_id', userId),
      supabaseClient.from('timer_prompts').select('*').eq('user_id', userId),
      supabaseClient.from('user_feedback').select('*').eq('user_id', userId),
      supabaseClient.from('personality_traits').select('*').eq('user_id', userId),
      supabaseClient.from('additional_info').select('*').eq('user_id', userId),
      supabaseClient.from('reminders').select('*').eq('user_id', userId),
      supabaseClient.from('system_prompts').select('*').eq('user_id', userId)
    ])

    if (todosRes.error || goalsRes.error || goalStepsRes.error || timerPromptsRes.error || feedbackRes.error || personalityRes.error || additionalInfoRes.error || remindersRes.error || systemPromptsRes.error) {
      throw new Error('Failed to fetch user data')
    }

    // Convert UTC timestamps to IST for AI
    const todolist = (todosRes.data || []).map((item: any) => ({
      ...item,
      due_date: formatTimestampForAI(item.due_date)
    }))
    const goals = (goalsRes.data || []).map((item: any) => ({
      ...item,
      target_date: formatTimestampForAI(item.target_date)
    }))
    const goalSteps = goalStepsRes.data || []
    const timerPrompts = (timerPromptsRes.data || []).map((item: any) => ({
      ...item,
      scheduled_time: formatTimestampForAI(item.scheduled_time)
    }))
    const feedback = feedbackRes.data || []
    const personalityTraits = personalityRes.data || []
    const additionalInfo = additionalInfoRes.data || []
    const reminders = (remindersRes.data || []).map((item: any) => ({
      ...item,
      scheduled_date: formatTimestampForAI(item.scheduled_date)
    }))

    // Get user's custom system prompt from database, or use default
    let userSystemPrompt = '';
    if (systemPromptsRes.data && systemPromptsRes.data.length > 0) {
      const userPrompt = systemPromptsRes.data[0];
      userSystemPrompt = userPrompt.system_chat_prompt || '';
    } else {
      console.log(`[process-prompt] No custom system prompt found for user: ${userId}, using default`);
    }

    // Create system prompt
    const systemPrompt = `${userSystemPrompt}
You have access to User todolist: ${JSON.stringify(todolist)}
User goals: ${JSON.stringify(goals)}
User goal steps: ${JSON.stringify(goalSteps)}
User reminders: ${JSON.stringify(reminders)}
User timer prompts: ${JSON.stringify(timerPrompts)}
User feedback: ${JSON.stringify(feedback)}
User personality traits: ${JSON.stringify(personalityTraits)}
User additional info: ${JSON.stringify(additionalInfo)}
`

    // Build conversation history for Vercel AI SDK (role 'model' -> 'assistant')
    const messages: Array<{ role: 'user' | 'assistant', content: string }> = (chatHistory || [])
      .filter(msg => msg.role && (msg.role === 'user' || msg.role === 'model') && msg.content)
      .slice(-10)
      .map(msg => ({
        role: msg.role === 'model' ? 'assistant' : 'user',
        content: msg.content
      }))

    // Ensure history starts with 'user'
    while (messages.length > 0 && messages[0].role === 'assistant') {
      messages.shift();
    }

    // Add the current user message
    messages.push({ role: 'user', content: userInput })

    // Initialize Vercel AI SDK with Google provider
    const google = createGoogleGenerativeAI({
      apiKey: Deno.env.get('GEMINI_API_KEY') || ''
    })

    // Wrap the model with Supermemory for persistent per-user memory.
    // SUPERMEMORY_API_KEY must be set in Supabase project secrets.
    // userId is used as the container tag so each user's memory is isolated.
    const modelWithMemory = withSupermemory(
      google('gemini-2.5-flash'),
      `user_${userId}`,
      {
        addMemory: 'always', // auto-save each conversation turn
        mode: 'full',        // retrieve both profile + query-based memories
        apiKey: Deno.env.get('SUPERMEMORY_API_KEY') || ''
      }
    )

    // Define tools using jsonSchema (avoids Zod compatibility issues in Deno)
    const tools = {
      addTodo: {
        description: 'Adds a new to-do item. IMPORTANT and URGENCY are different! importance=how valuable, urgency=how time-sensitive.',
        parameters: jsonSchema<{
          task: string
          importance: 'IMPORTANT' | 'NOT IMPORTANT'
          urgency: 'URGENT' | 'NOT URGENT'
          description?: string
          dueDate?: string
          isCompleted?: boolean
        }>({
          type: 'object',
          properties: {
            task: { type: 'string', description: 'The task to be done.' },
            importance: { type: 'string', enum: ['IMPORTANT', 'NOT IMPORTANT'], description: 'How valuable/meaningful this task is.' },
            urgency: { type: 'string', enum: ['URGENT', 'NOT URGENT'], description: 'How time-sensitive this task is.' },
            description: { type: 'string', description: 'Task description.' },
            dueDate: { type: 'string', description: 'Due date in ISO format.' },
            isCompleted: { type: 'boolean', description: 'Whether the task is completed.' }
          },
          required: ['task', 'importance', 'urgency']
        })
      },
      deleteTodo: {
        description: 'Deletes a to-do item.',
        parameters: jsonSchema<{ taskId: string }>({
          type: 'object',
          properties: { taskId: { type: 'string', description: 'The ID of the task to delete.' } },
          required: ['taskId']
        })
      },
      modifyTodo: {
        description: 'Modifies a to-do item. IMPORTANT and URGENCY are different!',
        parameters: jsonSchema<{
          taskId: string
          newTask: string
          newImportance?: 'IMPORTANT' | 'NOT IMPORTANT'
          newUrgency?: 'URGENT' | 'NOT URGENT'
          newDescription?: string
          newDueDate?: string
          newIsCompleted?: boolean
        }>({
          type: 'object',
          properties: {
            taskId: { type: 'string', description: 'The ID of the task to modify.' },
            newTask: { type: 'string', description: 'The updated task.' },
            newImportance: { type: 'string', enum: ['IMPORTANT', 'NOT IMPORTANT'] },
            newUrgency: { type: 'string', enum: ['URGENT', 'NOT URGENT'] },
            newDescription: { type: 'string' },
            newDueDate: { type: 'string' },
            newIsCompleted: { type: 'boolean' }
          },
          required: ['taskId', 'newTask']
        })
      },
      addGoal: {
        description: 'Adds a new goal. IMPORTANT and URGENCY are different! importance=how valuable, urgency=how time-sensitive.',
        parameters: jsonSchema<{
          title: string
          description?: string
          targetDate?: string
          isCompleted?: boolean
          importance?: 'IMPORTANT' | 'NOT IMPORTANT'
          urgency?: 'URGENT' | 'NOT URGENT'
        }>({
          type: 'object',
          properties: {
            title: { type: 'string', description: 'The goal title.' },
            description: { type: 'string', description: 'Goal description.' },
            targetDate: { type: 'string', description: 'Target date in ISO format.' },
            isCompleted: { type: 'boolean', description: 'Whether the goal is completed.' },
            importance: { type: 'string', enum: ['IMPORTANT', 'NOT IMPORTANT'] },
            urgency: { type: 'string', enum: ['URGENT', 'NOT URGENT'] }
          },
          required: ['title']
        })
      },
      deleteGoal: {
        description: 'Deletes a goal.',
        parameters: jsonSchema<{ goalId: string }>({
          type: 'object',
          properties: { goalId: { type: 'string', description: 'The ID of the goal to delete.' } },
          required: ['goalId']
        })
      },
      modifyGoal: {
        description: 'Modifies a goal. IMPORTANT and URGENCY are different!',
        parameters: jsonSchema<{
          goalId: string
          newTitle: string
          newDescription?: string
          newTargetDate?: string
          newIsCompleted?: boolean
          newImportance?: 'IMPORTANT' | 'NOT IMPORTANT'
          newUrgency?: 'URGENT' | 'NOT URGENT'
        }>({
          type: 'object',
          properties: {
            goalId: { type: 'string' },
            newTitle: { type: 'string' },
            newDescription: { type: 'string' },
            newTargetDate: { type: 'string' },
            newIsCompleted: { type: 'boolean' },
            newImportance: { type: 'string', enum: ['IMPORTANT', 'NOT IMPORTANT'] },
            newUrgency: { type: 'string', enum: ['URGENT', 'NOT URGENT'] }
          },
          required: ['goalId', 'newTitle']
        })
      },
      addGoalStep: {
        description: 'Adds a new step to a goal.',
        parameters: jsonSchema<{
          goalId: string
          title: string
          description?: string
          orderIndex?: number
        }>({
          type: 'object',
          properties: {
            goalId: { type: 'string', description: 'The ID of the goal this step belongs to.' },
            title: { type: 'string', description: 'The step title.' },
            description: { type: 'string', description: 'Step description.' },
            orderIndex: { type: 'number', description: 'The order index of the step.' }
          },
          required: ['goalId', 'title']
        })
      },
      deleteGoalStep: {
        description: 'Deletes a goal step.',
        parameters: jsonSchema<{ stepId: string }>({
          type: 'object',
          properties: { stepId: { type: 'string', description: 'The ID of the step to delete.' } },
          required: ['stepId']
        })
      },
      modifyGoalStep: {
        description: 'Modifies a goal step.',
        parameters: jsonSchema<{
          stepId: string
          newTitle: string
          newDescription?: string
          newIsCompleted?: boolean
          newOrderIndex?: number
        }>({
          type: 'object',
          properties: {
            stepId: { type: 'string' },
            newTitle: { type: 'string' },
            newDescription: { type: 'string' },
            newIsCompleted: { type: 'boolean' },
            newOrderIndex: { type: 'number' }
          },
          required: ['stepId', 'newTitle']
        })
      },
      addTimerPrompt: {
        description: 'Adds a new timer prompt.',
        parameters: jsonSchema<{
          prompt: string
          scheduledTime: string
          isRecurring?: boolean
          weekdays?: number[]
          response?: string
          sent?: boolean
        }>({
          type: 'object',
          properties: {
            prompt: { type: 'string', description: 'The prompt text.' },
            scheduledTime: { type: 'string', description: 'Scheduled time in ISO format.' },
            isRecurring: { type: 'boolean', description: 'Whether it recurs.' },
            weekdays: { type: 'array', items: { type: 'number' }, description: 'Array of weekday numbers.' },
            response: { type: 'string', description: 'The response text.' },
            sent: { type: 'boolean', description: 'Whether it has been sent.' }
          },
          required: ['prompt', 'scheduledTime']
        })
      },
      deleteTimerPrompt: {
        description: 'Deletes a timer prompt.',
        parameters: jsonSchema<{ promptId: string }>({
          type: 'object',
          properties: { promptId: { type: 'string', description: 'The ID of the prompt to delete.' } },
          required: ['promptId']
        })
      },
      modifyTimerPrompt: {
        description: 'Modifies a timer prompt.',
        parameters: jsonSchema<{
          promptId: string
          newPrompt: string
          newScheduledTime?: string
          newIsRecurring?: boolean
          newWeekdays?: number[]
          newResponse?: string
          newSent?: boolean
        }>({
          type: 'object',
          properties: {
            promptId: { type: 'string' },
            newPrompt: { type: 'string' },
            newScheduledTime: { type: 'string' },
            newIsRecurring: { type: 'boolean' },
            newWeekdays: { type: 'array', items: { type: 'number' } },
            newResponse: { type: 'string' },
            newSent: { type: 'boolean' }
          },
          required: ['promptId', 'newPrompt']
        })
      },
      addFeedback: {
        description: 'Adds user feedback.',
        parameters: jsonSchema<{ feedback: string }>({
          type: 'object',
          properties: { feedback: { type: 'string', description: 'The feedback text.' } },
          required: ['feedback']
        })
      },
      deleteFeedback: {
        description: 'Deletes user feedback.',
        parameters: jsonSchema<{ feedbackId: string }>({
          type: 'object',
          properties: { feedbackId: { type: 'string', description: 'The ID of the feedback to delete.' } },
          required: ['feedbackId']
        })
      },
      modifyFeedback: {
        description: 'Modifies user feedback.',
        parameters: jsonSchema<{ feedbackId: string; newFeedback: string }>({
          type: 'object',
          properties: {
            feedbackId: { type: 'string' },
            newFeedback: { type: 'string', description: 'The updated feedback text.' }
          },
          required: ['feedbackId', 'newFeedback']
        })
      },
      addPersonalityTrait: {
        description: 'Adds a new personality trait.',
        parameters: jsonSchema<{ trait: string }>({
          type: 'object',
          properties: { trait: { type: 'string', description: 'The personality trait text.' } },
          required: ['trait']
        })
      },
      deletePersonalityTrait: {
        description: 'Deletes a personality trait.',
        parameters: jsonSchema<{ traitId: string }>({
          type: 'object',
          properties: { traitId: { type: 'string', description: 'The ID of the trait to delete.' } },
          required: ['traitId']
        })
      },
      modifyPersonalityTrait: {
        description: 'Modifies a personality trait.',
        parameters: jsonSchema<{ traitId: string; newTrait: string }>({
          type: 'object',
          properties: {
            traitId: { type: 'string' },
            newTrait: { type: 'string', description: 'The updated trait text.' }
          },
          required: ['traitId', 'newTrait']
        })
      },
      addAdditionalInfo: {
        description: 'Adds additional information.',
        parameters: jsonSchema<{ info: string }>({
          type: 'object',
          properties: { info: { type: 'string', description: 'The additional information text.' } },
          required: ['info']
        })
      },
      deleteAdditionalInfo: {
        description: 'Deletes additional information.',
        parameters: jsonSchema<{ infoId: string }>({
          type: 'object',
          properties: { infoId: { type: 'string', description: 'The ID of the info to delete.' } },
          required: ['infoId']
        })
      },
      modifyAdditionalInfo: {
        description: 'Modifies additional information.',
        parameters: jsonSchema<{ infoId: string; newInfo: string }>({
          type: 'object',
          properties: {
            infoId: { type: 'string' },
            newInfo: { type: 'string', description: 'The updated info text.' }
          },
          required: ['infoId', 'newInfo']
        })
      },
      addReminder: {
        description: 'Adds a new reminder.',
        parameters: jsonSchema<{
          title: string
          scheduledDate: string
          body?: string
          reminderType?: string
          options?: string[]
          expectedAnswer?: string
          aiPrompt?: string
        }>({
          type: 'object',
          properties: {
            title: { type: 'string', description: 'The reminder title.' },
            body: { type: 'string', description: 'The reminder body text.' },
            scheduledDate: { type: 'string', description: 'Scheduled date in ISO format.' },
            reminderType: { type: 'string', description: 'Type of reminder: basic, option, answer_back, ai_prompt.' },
            options: { type: 'array', items: { type: 'string' }, description: 'Options for option-type reminders.' },
            expectedAnswer: { type: 'string', description: 'Expected answer for answer_back reminders.' },
            aiPrompt: { type: 'string', description: 'AI prompt for ai_prompt reminders.' }
          },
          required: ['title', 'scheduledDate']
        })
      },
      deleteReminder: {
        description: 'Deletes a reminder.',
        parameters: jsonSchema<{ reminderId: string }>({
          type: 'object',
          properties: { reminderId: { type: 'string', description: 'The ID of the reminder to delete.' } },
          required: ['reminderId']
        })
      },
      modifyReminder: {
        description: 'Modifies a reminder.',
        parameters: jsonSchema<{
          reminderId: string
          newTitle: string
          newBody?: string
          newScheduledDate?: string
          newReminderType?: string
          newOptions?: string[]
          newExpectedAnswer?: string
          newAiPrompt?: string
        }>({
          type: 'object',
          properties: {
            reminderId: { type: 'string' },
            newTitle: { type: 'string' },
            newBody: { type: 'string' },
            newScheduledDate: { type: 'string' },
            newReminderType: { type: 'string' },
            newOptions: { type: 'array', items: { type: 'string' } },
            newExpectedAnswer: { type: 'string' },
            newAiPrompt: { type: 'string' }
          },
          required: ['reminderId', 'newTitle']
        })
      }
    }

    // Call the AI model via Vercel AI SDK
    // maxSteps allows the model to call tools and then produce a final text response
    const result = await generateText({
      model: modelWithMemory,
      system: systemPrompt,
      messages,
      tools,
      maxSteps: 5,
      temperature: 1,
      maxTokens: 8192,
      onStepFinish: async ({ toolResults }: { toolResults: any[] }) => {
        // Execute database operations for each tool call
        for (const toolResult of toolResults) {
          const args = toolResult.args as any
          switch (toolResult.toolName) {
            case 'addTodo': {
              const { error } = await supabaseClient.from('todos').insert({
                id: Date.now().toString(),
                user_id: userId,
                task_name: args.task || 'Untitled Task',
                importance: args.importance || 'NOT IMPORTANT',
                urgency: args.urgency || 'NOT URGENT',
                description: args.description || '',
                due_date: formatTimestamp(args.dueDate),
                is_completed: args.isCompleted || false
              })
              if (error) throw error
              break
            }
            case 'deleteTodo': {
              const { error } = await supabaseClient.from('todos').delete().eq('id', args.taskId).eq('user_id', userId)
              if (error) throw error
              break
            }
            case 'modifyTodo': {
              const { error } = await supabaseClient.from('todos').update({
                task_name: args.newTask,
                importance: args.newImportance,
                urgency: args.newUrgency,
                description: args.newDescription,
                due_date: formatTimestamp(args.newDueDate),
                is_completed: args.newIsCompleted
              }).eq('id', args.taskId).eq('user_id', userId)
              if (error) throw error
              break
            }
            case 'addGoal': {
              const { error } = await supabaseClient.from('goals').insert({
                id: Date.now().toString(),
                user_id: userId,
                title: args.title || 'Untitled Goal',
                description: args.description || '',
                target_date: formatTimestamp(args.targetDate),
                is_completed: args.isCompleted || false,
                importance: args.importance || 'NOT IMPORTANT',
                urgency: args.urgency || 'NOT URGENT'
              })
              if (error) throw error
              break
            }
            case 'deleteGoal': {
              const { error } = await supabaseClient.from('goals').delete().eq('id', args.goalId).eq('user_id', userId)
              if (error) throw error
              break
            }
            case 'modifyGoal': {
              const { error } = await supabaseClient.from('goals').update({
                title: args.newTitle,
                description: args.newDescription,
                target_date: formatTimestamp(args.newTargetDate),
                is_completed: args.newIsCompleted,
                importance: args.newImportance,
                urgency: args.newUrgency
              }).eq('id', args.goalId).eq('user_id', userId)
              if (error) throw error
              break
            }
            case 'addGoalStep': {
              const { error } = await supabaseClient.from('goal_steps').insert({
                id: Date.now().toString(),
                user_id: userId,
                goal_id: args.goalId,
                step_text: args.title || 'Untitled Step',
                is_completed: false,
                sort_order: args.orderIndex || 0
              })
              if (error) throw error
              break
            }
            case 'deleteGoalStep': {
              const { error } = await supabaseClient.from('goal_steps').delete().eq('id', args.stepId).eq('user_id', userId)
              if (error) throw error
              break
            }
            case 'modifyGoalStep': {
              const { error } = await supabaseClient.from('goal_steps').update({
                step_text: args.newTitle,
                is_completed: args.newIsCompleted,
                sort_order: args.newOrderIndex
              }).eq('id', args.stepId).eq('user_id', userId)
              if (error) throw error
              break
            }
            case 'addTimerPrompt': {
              const { error } = await supabaseClient.from('timer_prompts').insert({
                user_id: userId,
                prompt: args.prompt || 'No prompt',
                response: args.response || '',
                scheduled_time: formatTimestamp(args.scheduledTime),
                recurring_type: args.isRecurring ? 'DAILY' : null,
                weekdays: args.weekdays || [],
                sent: args.sent || false
              })
              if (error) throw error
              break
            }
            case 'deleteTimerPrompt': {
              const { error } = await supabaseClient.from('timer_prompts').delete().eq('id', args.promptId).eq('user_id', userId)
              if (error) throw error
              break
            }
            case 'modifyTimerPrompt': {
              const { error } = await supabaseClient.from('timer_prompts').update({
                prompt: args.newPrompt,
                response: args.newResponse,
                scheduled_time: formatTimestamp(args.newScheduledTime),
                recurring_type: args.newIsRecurring ? 'DAILY' : null,
                weekdays: args.newWeekdays,
                sent: args.newSent
              }).eq('id', args.promptId).eq('user_id', userId)
              if (error) throw error
              break
            }
            case 'addFeedback': {
              const { error } = await supabaseClient.from('user_feedback').insert({
                id: Date.now().toString(),
                user_id: userId,
                feedback: args.feedback
              })
              if (error) throw error
              break
            }
            case 'deleteFeedback': {
              const { error } = await supabaseClient.from('user_feedback').delete().eq('id', args.feedbackId).eq('user_id', userId)
              if (error) throw error
              break
            }
            case 'modifyFeedback': {
              const { error } = await supabaseClient.from('user_feedback').update({
                feedback: args.newFeedback
              }).eq('id', args.feedbackId).eq('user_id', userId)
              if (error) throw error
              break
            }
            case 'addPersonalityTrait': {
              const { error } = await supabaseClient.from('personality_traits').insert({
                id: Date.now().toString(),
                user_id: userId,
                trait: args.trait || 'No trait'
              })
              if (error) throw error
              break
            }
            case 'deletePersonalityTrait': {
              const { error } = await supabaseClient.from('personality_traits').delete().eq('id', args.traitId).eq('user_id', userId)
              if (error) throw error
              break
            }
            case 'modifyPersonalityTrait': {
              const { error } = await supabaseClient.from('personality_traits').update({
                trait: args.newTrait
              }).eq('id', args.traitId).eq('user_id', userId)
              if (error) throw error
              break
            }
            case 'addAdditionalInfo': {
              const { error } = await supabaseClient.from('additional_info').insert({
                id: Date.now().toString(),
                user_id: userId,
                info: args.info || 'No info'
              })
              if (error) throw error
              break
            }
            case 'deleteAdditionalInfo': {
              const { error } = await supabaseClient.from('additional_info').delete().eq('id', args.infoId).eq('user_id', userId)
              if (error) throw error
              break
            }
            case 'modifyAdditionalInfo': {
              const { error } = await supabaseClient.from('additional_info').update({
                info: args.newInfo
              }).eq('id', args.infoId).eq('user_id', userId)
              if (error) throw error
              break
            }
            case 'addReminder': {
              const { error } = await supabaseClient.from('reminders').insert({
                id: Date.now().toString(),
                user_id: userId,
                title: args.title || 'Untitled Reminder',
                body: args.body || '',
                scheduled_date: formatTimestamp(args.scheduledDate),
                payload: args.title || 'Untitled Reminder',
                reminder_type: args.reminderType || 'basic',
                options: args.options ? JSON.stringify(args.options) : null,
                expected_answer: args.expectedAnswer || '',
                ai_prompt: args.aiPrompt || ''
              })
              if (error) throw error
              break
            }
            case 'deleteReminder': {
              const { error } = await supabaseClient.from('reminders').delete().eq('id', args.reminderId).eq('user_id', userId)
              if (error) throw error
              break
            }
            case 'modifyReminder': {
              const { error } = await supabaseClient.from('reminders').update({
                title: args.newTitle,
                body: args.newBody,
                scheduled_date: formatTimestamp(args.newScheduledDate),
                payload: args.newTitle,
                reminder_type: args.newReminderType,
                options: args.newOptions ? JSON.stringify(args.newOptions) : null,
                expected_answer: args.newExpectedAnswer,
                ai_prompt: args.newAiPrompt,
                updated_at: new Date().toISOString()
              }).eq('id', args.reminderId).eq('user_id', userId)
              if (error) throw error
              break
            }
          }
        }
      }
    })

    return new Response(
      JSON.stringify({ response: result.text }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error)
    console.error('[process-prompt] Error:', errorMessage, error)
    return new Response(
      JSON.stringify({ error: errorMessage }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})