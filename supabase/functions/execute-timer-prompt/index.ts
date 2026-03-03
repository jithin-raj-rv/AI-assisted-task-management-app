import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { GoogleGenerativeAI } from "https://esm.sh/@google/generative-ai"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface FunctionArgs {
  timerPromptId: string
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

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { timerPromptId }: FunctionArgs = await req.json()

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

    if (!timerPromptId) {
      return new Response(
        JSON.stringify({ error: 'timerPromptId is required' }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400,
        }
      )
    }

    // Create Supabase client with service role
    const supabaseClient = createClient(
      supabaseUrl,
      supabaseServiceKey,
      {
        auth: {
          persistSession: false,
        },
      }
    )

    // Fetch the timer prompt
    const { data: timerPrompt, error: promptError } = await supabaseClient
      .from('timer_prompts')
      .select('*')
      .eq('id', timerPromptId)
      .single()

    if (promptError || !timerPrompt) {
      throw new Error('Failed to fetch timer prompt')
    }

    const userId = timerPrompt.user_id

    // Fetch user data
    const [todosRes, goalsRes, goalStepsRes, timerPromptsRes, feedbackRes, personalityRes, additionalInfoRes, remindersRes] = await Promise.all([
      supabaseClient.from('todos').select('*').eq('user_id', userId),
      supabaseClient.from('goals').select('*').eq('user_id', userId),
      supabaseClient.from('goal_steps').select('*').eq('user_id', userId),
      supabaseClient.from('timer_prompts').select('*').eq('user_id', userId),
      supabaseClient.from('user_feedback').select('*').eq('user_id', userId),
      supabaseClient.from('personality_traits').select('*').eq('user_id', userId),
      supabaseClient.from('additional_info').select('*').eq('user_id', userId),
      supabaseClient.from('reminders').select('*').eq('user_id', userId)
    ])

    if (todosRes.error || goalsRes.error || goalStepsRes.error || timerPromptsRes.error || feedbackRes.error || personalityRes.error || additionalInfoRes.error || remindersRes.error) {
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

    // Initialize Gemini
    const genAI = new GoogleGenerativeAI(Deno.env.get('GEMINI_API_KEY') || '')
    const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' })

    // Define tools (same as process-prompt)
    const themeTool = {
      functionDeclarations: [{
        name: 'updateAppColors',
        description: 'Updates the app theme colors based on user preferences.',
        parameters: {
          type: 'object',
          properties: {
            primaryHex: { type: 'string', description: 'Hex code for the primary color' },
            backgroundHex: { type: 'string', description: 'Hex code for the background color' },
            secondaryHex: { type: 'string', description: 'Hex code for the secondary color' },
            tertiaryHex: { type: 'string', description: 'Hex code for the tertiary color' },
            primaryGradient1Hex: { type: 'string', description: 'Hex code for the first primary gradient color' },
            primaryGradient2Hex: { type: 'string', description: 'Hex code for the second primary gradient color' },
            secondaryGradient1Hex: { type: 'string', description: 'Hex code for the first secondary gradient color' },
            secondaryGradient2Hex: { type: 'string', description: 'Hex code for the second secondary gradient color' },
            tertiaryGradient1Hex: { type: 'string', description: 'Hex code for the first tertiary gradient color' },
            tertiaryGradient2Hex: { type: 'string', description: 'Hex code for the second tertiary gradient color' },
            backgroundGradient1Hex: { type: 'string', description: 'Hex code for the first background gradient color' },
            backgroundGradient2Hex: { type: 'string', description: 'Hex code for the second background gradient color' }
          },
          required: ['primaryHex', 'backgroundHex', 'secondaryHex', 'tertiaryHex', 'primaryGradient1Hex', 'primaryGradient2Hex', 'secondaryGradient1Hex', 'secondaryGradient2Hex', 'tertiaryGradient1Hex', 'tertiaryGradient2Hex', 'backgroundGradient1Hex', 'backgroundGradient2Hex']
        }
      }]
    }

    const todoTool = {
      functionDeclarations: [{
        name: 'addTodo',
        description: 'Adds a new to-do item. IMPORTANT and URGENCY are different! importance=how valuable, urgency=how time-sensitive.',
        parameters: {
          type: 'object',
          properties: {
            task: { type: 'string', description: 'The task to be done.' },
            importance: { type: 'string', description: 'How valuable/meaningful: IMPORTANT or NOT IMPORTANT', enum: ['IMPORTANT','NOT IMPORTANT'] },
            urgency: { type: 'string', description: 'How time-sensitive: URGENT or NOT URGENT', enum: ['URGENT', 'NOT URGENT'] },
            description: { type: 'string', description: 'Task description.' },
            dueDate: { type: 'string', description: 'Due date in ISO format.' },
            isCompleted: { type: 'boolean', description: 'Whether the task is completed.' }
          },
          required: ['task', 'importance', 'urgency']
        }
      }, {
        name: 'deleteTodo',
        description: 'Deletes a to-do item.',
        parameters: {
          type: 'object',
          properties: {
            taskId: { type: 'string', description: 'The ID of the task to delete.' }
          },
          required: ['taskId']
        }
      }, {
        name: 'modifyTodo',
        description: 'Modifies a to-do item. IMPORTANT and URGENCY are different!',
        parameters: {
          type: 'object',
          properties: {
            taskId: { type: 'string', description: 'The ID of the task to modify.' },
            newTask: { type: 'string', description: 'The updated task.' },
            newImportance: { type: 'string', description: 'IMPORTANT or NOT IMPORTANT', enum: ['IMPORTANT','NOT IMPORTANT'] },
            newUrgency: { type: 'string', description: 'URGENT or NOT URGENT', enum: ['URGENT', 'NOT URGENT'] },
            newDescription: { type: 'string' },
            newDueDate: { type: 'string' },
            newIsCompleted: { type: 'boolean' }
          },
          required: ['taskId', 'newTask']
        }
      }]
    }

    const goalTool = {
      functionDeclarations: [{
        name: 'addGoal',
        description: 'Adds a new goal.',
        parameters: {
          type: 'object',
          properties: {
            title: { type: 'string', description: 'The goal title.' },
            description: { type: 'string', description: 'Goal description.' },
            targetDate: { type: 'string', description: 'Target date in ISO format.' },
            isCompleted: { type: 'boolean', description: 'Whether the goal is completed.' }
          },
          required: ['title']
        }
      }, {
        name: 'deleteGoal',
        description: 'Deletes a goal.',
        parameters: {
          type: 'object',
          properties: {
            goalId: { type: 'string', description: 'The ID of the goal to delete.' }
          },
          required: ['goalId']
        }
      }, {
        name: 'modifyGoal',
        description: 'Modifies a goal.',
        parameters: {
          type: 'object',
          properties: {
            goalId: { type: 'string', description: 'The ID of the goal to modify.' },
            newTitle: { type: 'string', description: 'The updated title.' },
            newDescription: { type: 'string' },
            newTargetDate: { type: 'string' },
            newIsCompleted: { type: 'boolean' }
          },
          required: ['goalId', 'newTitle']
        }
      }]
    }

    const timerPromptTool = {
      functionDeclarations: [{
        name: 'addTimerPrompt',
        description: 'Adds a new timer prompt.',
        parameters: {
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
        }
      }, {
        name: 'deleteTimerPrompt',
        description: 'Deletes a timer prompt.',
        parameters: {
          type: 'object',
          properties: {
            promptId: { type: 'string', description: 'The ID of the prompt to delete.' }
          },
          required: ['promptId']
        }
      }, {
        name: 'modifyTimerPrompt',
        description: 'Modifies a timer prompt.',
        parameters: {
          type: 'object',
          properties: {
            promptId: { type: 'string', description: 'The ID of the prompt to modify.' },
            newPrompt: { type: 'string', description: 'The updated prompt.' },
            newScheduledTime: { type: 'string' },
            newIsRecurring: { type: 'boolean' },
            newWeekdays: { type: 'array', items: { type: 'number' } },
            newResponse: { type: 'string' },
            newSent: { type: 'boolean' }
          },
          required: ['promptId', 'newPrompt']
        }
      }]
    }

    const feedbackTool = {
      functionDeclarations: [{
        name: 'addFeedback',
        description: 'Adds user feedback.',
        parameters: {
          type: 'object',
          properties: {
            feedback: { type: 'string', description: 'The feedback text.' }
          },
          required: ['feedback']
        }
      }, {
        name: 'deleteFeedback',
        description: 'Deletes user feedback.',
        parameters: {
          type: 'object',
          properties: {
            feedbackId: { type: 'string', description: 'The ID of the feedback to delete.' }
          },
          required: ['feedbackId']
        }
      }, {
        name: 'modifyFeedback',
        description: 'Modifies user feedback.',
        parameters: {
          type: 'object',
          properties: {
            feedbackId: { type: 'string', description: 'The ID of the feedback to modify.' },
            newFeedback: { type: 'string', description: 'The updated feedback text.' }
          },
          required: ['feedbackId', 'newFeedback']
        }
      }]
    }

    const goalStepTool = {
      functionDeclarations: [{
        name: 'addGoalStep',
        description: 'Adds a new step to a goal.',
        parameters: {
          type: 'object',
          properties: {
            goalId: { type: 'string', description: 'The ID of the goal this step belongs to.' },
            title: { type: 'string', description: 'The step title.' },
            description: { type: 'string', description: 'Step description.' },
            orderIndex: { type: 'number', description: 'The order index of the step.' }
          },
          required: ['goalId', 'title']
        }
      }, {
        name: 'deleteGoalStep',
        description: 'Deletes a goal step.',
        parameters: {
          type: 'object',
          properties: {
            stepId: { type: 'string', description: 'The ID of the step to delete.' }
          },
          required: ['stepId']
        }
      }, {
        name: 'modifyGoalStep',
        description: 'Modifies a goal step.',
        parameters: {
          type: 'object',
          properties: {
            stepId: { type: 'string', description: 'The ID of the step to modify.' },
            newTitle: { type: 'string', description: 'The updated title.' },
            newDescription: { type: 'string' },
            newIsCompleted: { type: 'boolean', description: 'Whether the step is completed.' },
            newOrderIndex: { type: 'number', description: 'The updated order index.' }
          },
          required: ['stepId', 'newTitle']
        }
      }]
    }

    const personalityTool = {
      functionDeclarations: [{
        name: 'addPersonalityTrait',
        description: 'Adds a new personality trait.',
        parameters: {
          type: 'object',
          properties: {
            trait: { type: 'string', description: 'The personality trait text.' }
          },
          required: ['trait']
        }
      }, {
        name: 'deletePersonalityTrait',
        description: 'Deletes a personality trait.',
        parameters: {
          type: 'object',
          properties: {
            traitId: { type: 'string', description: 'The ID of the trait to delete.' }
          },
          required: ['traitId']
        }
      }, {
        name: 'modifyPersonalityTrait',
        description: 'Modifies a personality trait.',
        parameters: {
          type: 'object',
          properties: {
            traitId: { type: 'string', description: 'The ID of the trait to modify.' },
            newTrait: { type: 'string', description: 'The updated trait text.' }
          },
          required: ['traitId', 'newTrait']
        }
      }]
    }

    const additionalInfoTool = {
      functionDeclarations: [{
        name: 'addAdditionalInfo',
        description: 'Adds additional information.',
        parameters: {
          type: 'object',
          properties: {
            info: { type: 'string', description: 'The additional information text.' }
          },
          required: ['info']
        }
      }, {
        name: 'deleteAdditionalInfo',
        description: 'Deletes additional information.',
        parameters: {
          type: 'object',
          properties: {
            infoId: { type: 'string', description: 'The ID of the info to delete.' }
          },
          required: ['infoId']
        }
      }, {
        name: 'modifyAdditionalInfo',
        description: 'Modifies additional information.',
        parameters: {
          type: 'object',
          properties: {
            infoId: { type: 'string', description: 'The ID of the info to modify.' },
            newInfo: { type: 'string', description: 'The updated info text.' }
          },
          required: ['infoId', 'newInfo']
        }
      }]
    }

    const reminderTool = {
      functionDeclarations: [{
        name: 'addReminder',
        description: 'Adds a new reminder.',
        parameters: {
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
        }
      }, {
        name: 'deleteReminder',
        description: 'Deletes a reminder.',
        parameters: {
          type: 'object',
          properties: {
            reminderId: { type: 'string', description: 'The ID of the reminder to delete.' }
          },
          required: ['reminderId']
        }
      }, {
        name: 'modifyReminder',
        description: 'Modifies a reminder.',
        parameters: {
          type: 'object',
          properties: {
            reminderId: { type: 'string', description: 'The ID of the reminder to modify.' },
            newTitle: { type: 'string', description: 'The updated title.' },
            newBody: { type: 'string', description: 'The updated body.' },
            newScheduledDate: { type: 'string', description: 'The updated scheduled date.' },
            newReminderType: { type: 'string', description: 'The updated reminder type.' },
            newOptions: { type: 'array', items: { type: 'string' }, description: 'Updated options.' },
            newExpectedAnswer: { type: 'string', description: 'Updated expected answer.' },
            newAiPrompt: { type: 'string', description: 'Updated AI prompt.' }
          },
          required: ['reminderId', 'newTitle']
        }
      }]
    }

    const generationConfig = {
      temperature: 1,
      topP: 0.95,
      topK: 64,
      maxOutputTokens: 8192,
      responseMimeType: 'text/plain',
    }

    const chat = model.startChat({
      generationConfig,
      history: [],
      tools: [themeTool, todoTool, goalTool, goalStepTool, timerPromptTool, feedbackTool, personalityTool, additionalInfoTool, reminderTool]
    })

    const result = await chat.sendMessage([
      {
        text: `
        
You have access to User todolist: ${JSON.stringify(todolist)}
User goals: ${JSON.stringify(goals)}
User goal steps: ${JSON.stringify(goalSteps)}
User reminders: ${JSON.stringify(reminders)}
User timer prompts: ${JSON.stringify(timerPrompts)}
User feedback: ${JSON.stringify(feedback)}
User personality traits: ${JSON.stringify(personalityTraits)}
User additional info: ${JSON.stringify(additionalInfo)}

You are a professional Personal manager. When a user mentions colors, call updateAppColors.
For todos: use addTodo, deleteTodo, modifyTodo.
For goals: addGoal, deleteGoal, modifyGoal.
For goal steps: addGoalStep, deleteGoalStep, modifyGoalStep., use goals, goal steps to help user define their long term goals, and the journey to complete the goal
For timer prompts: addTimerPrompt, deleteTimerPrompt, modifyTimerPrompt.
For feedback: use addFeedback, deleteFeedback, modifyFeedback., use this to access user feedback and remove unwanted feedback after using them.
For personality traits: use addPersonalityTrait, deletePersonalityTrait, modifyPersonalityTrait.
For additional info: use addAdditionalInfo, deleteAdditionalInfo, modifyAdditionalInfo.
For reminders: use addReminder, deleteReminder, modifyReminder.


Help the user figure out of how to achieve goals if they are confused.
Collect user info and store in personality, additional info as necessary.
when user asks to update their todos for the day aknowledge user personality, additional info,feedback and alter goals->goal-steps->daily tasks as user completes or descides to skip them then shedule reminders for the day.
When the user doesn't have any meaningfull goal, help them define the goal, steps, and update their todos and reminders accordingly.
You are very good at storing and retrieving user info in additional info. if goal is not clear, you add additional info to ask the user for more info. and delete it once everything is clear 
You are very good at storing information to understand the user.


You are a highly proactive, empathetic, and organized Professional Personal Manager. Your goal is to architect the user's life by translating high-level goals into actionable daily success.

### CRITICAL: UNDERSTANDING IMPORTANCE vs URGENCY:
- **IMPORTANCE**: How valuable/meaningful the task is. A task that matters for achieving goals. Use "IMPORTANT" if the task contributes significantly to user's goals, health, finances, or personal growth.
- **URGENCY**: How time-sensitive the task is. A task that requires immediate attention. Use "URGENT" if the task has a deadline, is time-bound, or needs to be done NOW.

IMPORTANT ≠ URGENT! A task can be:
- Important but NOT Urgent: Exercise, long-term planning, preventive healthcare
- Urgent but NOT Important: Someone else's emergency, interruptions
- Both Important AND Urgent: Deadline today, medical emergency
- Neither: Trivial tasks, time-wasters

When adding todos, ALWAYS consider both dimensions separately!

### CORE OPERATING PRINCIPLES:
1. **Strategic Translation**: Automatically break down 'Goals' into 'Goal Steps', then translate those into daily 'Todos'.
2. **Reminders from Todos**: You are responsible for analyzing the daily 'Todos' and calling 'addReminder' for each. Determine the best time based on 'Personality Traits' and 'Additional Info'.
3. **The Feedback Loop**: Use 'Feedback' from past reminders to adjust 'Timer Prompts'. If a user skips a task, use 'ModifyReminder' to reschedule and 'AddAdditionalInfo' to note the reason.
4. **Data Hygiene**: Delete 'Feedback' once analyzed and delete temporary 'Additional Info' notes once a goal is clarified.

### TOOL LOGIC:
- **Todos & Reminders**: Use 'addTodo' for the task and 'addReminder' to ensure the user is nudged.
- **Timer Prompts**: Schedule AI-driven prompts to check on goal progress and update 'Todos' based on the response.
- **Visual Aesthetic**: Call 'updateAppColors' when the user mentions mood or color.

### BEHAVIORAL NOTE:
When the user asks about their day, say: "I've analyzed your goal [Goal Name]. Based on your preference for [Personality Trait], I've scheduled [Todo] and set a reminder for [Time]."



Process this timer prompt automatically and execute the appropriate actions.`
      },
      {
        text: timerPrompt.prompt
      }
    ])

    const response = await result.response
    const functionCalls = response.functionCalls?.() ?? []

    let responseText = ''

    for (const call of functionCalls) {
      const args = call.args
      switch (call.name) {
        case 'addTodo':
          const { error: addTodoError } = await supabaseClient.from('todos').insert({
            id: Date.now().toString(),
            user_id: userId,
            task_name: args.task || 'Untitled Task',
            importance: args.importance || 'NOT IMPORTANT',
            urgency: args.urgency || 'NOT URGENT',
            description: args.description || '',
            due_date: formatTimestamp(args.dueDate),
            is_completed: args.isCompleted || false
          })
          if (addTodoError) throw addTodoError
          responseText += `Added todo: ${args.task || 'Untitled Task'}\n`
          break
        case 'deleteTodo':
          const { error: deleteTodoError } = await supabaseClient.from('todos').delete().eq('id', args.taskId).eq('user_id', userId)
          if (deleteTodoError) throw deleteTodoError
          responseText += `Deleted todo\n`
          break
        case 'modifyTodo':
          const { error: modifyTodoError } = await supabaseClient.from('todos').update({
            task_name: args.newTask,
            importance: args.newImportance,
            urgency: args.newUrgency,
            description: args.newDescription,
            due_date: formatTimestamp(args.newDueDate),
            is_completed: args.newIsCompleted
          }).eq('id', args.taskId).eq('user_id', userId)
          if (modifyTodoError) throw modifyTodoError
          responseText += `Modified todo: ${args.newTask}\n`
          break
        case 'addGoal':
          const { error: addGoalError } = await supabaseClient.from('goals').insert({
            id: Date.now().toString(),
            user_id: userId,
            title: args.title || 'Untitled Goal',
            description: args.description || '',
            target_date: formatTimestamp(args.targetDate),
            is_completed: args.isCompleted || false
          })
          if (addGoalError) throw addGoalError
          responseText += `Added goal: ${args.title || 'Untitled Goal'}\n`
          break
        case 'deleteGoal':
          const { error: deleteGoalError } = await supabaseClient.from('goals').delete().eq('id', args.goalId).eq('user_id', userId)
          if (deleteGoalError) throw deleteGoalError
          responseText += `Deleted goal\n`
          break
        case 'modifyGoal':
          const { error: modifyGoalError } = await supabaseClient.from('goals').update({
            title: args.newTitle,
            description: args.newDescription,
            target_date: formatTimestamp(args.newTargetDate),
            is_completed: args.newIsCompleted
          }).eq('id', args.goalId).eq('user_id', userId)
          if (modifyGoalError) throw modifyGoalError
          responseText += `Modified goal: ${args.newTitle}\n`
          break
        case 'addTimerPrompt':
          const { error: addTimerError } = await supabaseClient.from('timer_prompts').insert({
            id: Date.now().toString(),
            user_id: userId,
            prompt: args.prompt || 'No prompt',
            response: args.response || '',
            scheduled_time: formatTimestamp(args.scheduledTime),
            is_recurring: args.isRecurring || false,
            weekdays: args.weekdays || [],
            sent: args.sent || false
          })
          if (addTimerError) throw addTimerError
          responseText += `Added timer prompt: ${args.prompt || 'No prompt'}\n`
          break
        case 'deleteTimerPrompt':
          const { error: deleteTimerError } = await supabaseClient.from('timer_prompts').delete().eq('id', args.promptId).eq('user_id', userId)
          if (deleteTimerError) throw deleteTimerError
          responseText += `Deleted timer prompt\n`
          break
        case 'modifyTimerPrompt':
          const { error: modifyTimerError } = await supabaseClient.from('timer_prompts').update({
            prompt: args.newPrompt,
            response: args.newResponse,
            scheduled_time: formatTimestamp(args.newScheduledTime),
            is_recurring: args.newIsRecurring,
            weekdays: args.newWeekdays,
            sent: args.newSent
          }).eq('id', args.promptId).eq('user_id', userId)
          if (modifyTimerError) throw modifyTimerError
          responseText += `Modified timer prompt: ${args.newPrompt}\n`
          break
        case 'addFeedback':
          const { error: addFeedbackError } = await supabaseClient.from('user_feedback').insert({
            id: Date.now().toString(),
            user_id: userId,
            feedback: args.feedback
          })
          if (addFeedbackError) throw addFeedbackError
          responseText += `Added feedback\n`
          break
        case 'deleteFeedback':
          const { error: deleteFeedbackError } = await supabaseClient.from('user_feedback').delete().eq('id', args.feedbackId).eq('user_id', userId)
          if (deleteFeedbackError) throw deleteFeedbackError
          responseText += `Deleted feedback\n`
          break
        case 'modifyFeedback':
          const { error: modifyFeedbackError } = await supabaseClient.from('user_feedback').update({
            feedback: args.newFeedback
          }).eq('id', args.feedbackId).eq('user_id', userId)
          if (modifyFeedbackError) throw modifyFeedbackError
          responseText += `Modified feedback\n`
          break
        case 'addGoalStep':
          const { error: addStepError } = await supabaseClient.from('goal_steps').insert({
            id: Date.now().toString(),
            user_id: userId,
            goal_id: args.goalId,
            step_text: args.title || 'Untitled Step',
            is_completed: false,
            sort_order: args.orderIndex || 0
          })
          if (addStepError) throw addStepError
          responseText += `Added goal step: ${args.title || 'Untitled Step'}\n`
          break
        case 'deleteGoalStep':
          const { error: deleteStepError } = await supabaseClient.from('goal_steps').delete().eq('id', args.stepId).eq('user_id', userId)
          if (deleteStepError) throw deleteStepError
          responseText += `Deleted goal step\n`
          break
        case 'modifyGoalStep':
          const { error: modifyStepError } = await supabaseClient.from('goal_steps').update({
            step_text: args.newTitle,
            is_completed: args.newIsCompleted,
            sort_order: args.newOrderIndex
          }).eq('id', args.stepId).eq('user_id', userId)
          if (modifyStepError) throw modifyStepError
          responseText += `Modified goal step: ${args.newTitle}\n`
          break
        case 'updateAppColors':
          // Handle theme update - this might not be stored in DB, but could be handled separately
          responseText += `Updated app colors\n`
          break
        case 'addPersonalityTrait':
          const { error: addTraitError } = await supabaseClient.from('personality_traits').insert({
            id: Date.now().toString(),
            user_id: userId,
            trait: args.trait || 'No trait'
          })
          if (addTraitError) throw addTraitError
          responseText += `Added personality trait: ${args.trait || 'No trait'}\n`
          break
        case 'deletePersonalityTrait':
          const { error: deleteTraitError } = await supabaseClient.from('personality_traits').delete().eq('id', args.traitId).eq('user_id', userId)
          if (deleteTraitError) throw deleteTraitError
          responseText += `Deleted personality trait\n`
          break
        case 'modifyPersonalityTrait':
          const { error: modifyTraitError } = await supabaseClient.from('personality_traits').update({
            trait: args.newTrait
          }).eq('id', args.traitId).eq('user_id', userId)
          if (modifyTraitError) throw modifyTraitError
          responseText += `Modified personality trait: ${args.newTrait}\n`
          break
        case 'addAdditionalInfo':
          const { error: addInfoError } = await supabaseClient.from('additional_info').insert({
            id: Date.now().toString(),
            user_id: userId,
            info: args.info || 'No info'
          })
          if (addInfoError) throw addInfoError
          responseText += `Added additional info: ${args.info || 'No info'}\n`
          break
        case 'deleteAdditionalInfo':
          const { error: deleteInfoError } = await supabaseClient.from('additional_info').delete().eq('id', args.infoId).eq('user_id', userId)
          if (deleteInfoError) throw deleteInfoError
          responseText += `Deleted additional info\n`
          break
        case 'modifyAdditionalInfo':
          const { error: modifyInfoError } = await supabaseClient.from('additional_info').update({
            info: args.newInfo
          }).eq('id', args.infoId).eq('user_id', userId)
          if (modifyInfoError) throw modifyInfoError
          responseText += `Modified additional info: ${args.newInfo}\n`
          break
        case 'addReminder':
          const { error: addReminderError } = await supabaseClient.from('reminders').insert({
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
          if (addReminderError) throw addReminderError
          responseText += `Added reminder: ${args.title || 'Untitled Reminder'}\n`
          break
        case 'deleteReminder':
          const { error: deleteReminderError } = await supabaseClient.from('reminders').delete().eq('id', args.reminderId).eq('user_id', userId)
          if (deleteReminderError) throw deleteReminderError
          responseText += `Deleted reminder\n`
          break
        case 'modifyReminder':
          const { error: modifyReminderError } = await supabaseClient.from('reminders').update({
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
          if (modifyReminderError) throw modifyReminderError
          responseText += `Modified reminder: ${args.newTitle}\n`
          break
      }
    }

    // Update the timer prompt with response and mark as sent
    const { error: updateError } = await supabaseClient
      .from('timer_prompts')
      .update({
        response: responseText || response.text(),
        sent: true
      })
      .eq('id', timerPromptId)

    if (updateError) throw updateError

    // If this is a recurring timer prompt, reschedule for next occurrence
    if (timerPrompt.is_recurring) {
      const { error: rescheduleError } = await supabaseClient.rpc('reschedule_recurring_timer_prompt', {
        timer_prompt_id: timerPromptId
      })

      if (rescheduleError) {
        console.error('Failed to reschedule recurring timer prompt:', rescheduleError)
        // Don't throw error here as the main execution was successful
      }
    }

    return new Response(
      JSON.stringify({ success: true, response: responseText || response.text() }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : 'Unknown error' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})
