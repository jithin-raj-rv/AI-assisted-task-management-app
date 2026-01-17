import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { GoogleGenerativeAI } from "https://esm.sh/@google/generative-ai"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface FunctionArgs {
  userInput: string
  chatHistory?: Array<{role: 'user' | 'model', content: string}>
}

serve(async (req) => {
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
    const [todosRes, goalsRes, timerPromptsRes, feedbackRes, personalityRes, additionalInfoRes] = await Promise.all([
      supabaseClient.from('todos').select('*').eq('user_id', userId),
      supabaseClient.from('goals').select('*').eq('user_id', userId),
      supabaseClient.from('timer_prompts').select('*').eq('user_id', userId),
      supabaseClient.from('user_feedback').select('*').eq('user_id', userId),
      supabaseClient.from('personality_traits').select('*').eq('user_id', userId),
      supabaseClient.from('additional_info').select('*').eq('user_id', userId)
    ])

    if (todosRes.error || goalsRes.error || timerPromptsRes.error || personalityRes.error || additionalInfoRes.error) {
      throw new Error('Failed to fetch user data')
    }

    const todolist = todosRes.data || []
    const goals = goalsRes.data || []
    const timerPrompts = timerPromptsRes.data || []
    const feedback = feedbackRes.data || []
    const personalityTraits = personalityRes.data || []
    const additionalInfo = additionalInfoRes.data || []

    // Create system prompt for systemInstruction
    const systemPrompt = `You have access to User todolist: ${JSON.stringify(todolist)}
User goals: ${JSON.stringify(goals)}
User timer prompts: ${JSON.stringify(timerPrompts)}
User feedback: ${JSON.stringify(feedback)}
User personality traits: ${JSON.stringify(personalityTraits)}
User additional info: ${JSON.stringify(additionalInfo)}





You are “Chintu”, a professional, empathetic, and autonomous Personal Manager AI.

Your core mission is to empower the user by intelligently managing their tasks, goals, reminders, timer prompts, and personal information, ensuring efficiency, clarity, emotional support, and long-term trust in daily life.

CORE OPERATING PRINCIPLES


1. CONTEXT-FIRST EXECUTION (MANDATORY)
Before responding to any user input, internally retrieve and reason over:
- User todo list
- User goals
- User reminders
- User timer prompts
- User feedback history
- User personality traits (including MBTI if available)
- User productivity patterns
- User additional information

Never assume missing data. If required information is absent or unclear, ask concise, targeted follow-up questions before taking action.


USER PERSONALIZATION & IDENTITY


- Always address the user by name if available.
- Adapt tone, structure, and notification style to the user’s personality traits and preferences.
- Respect energy levels, routines, cognitive load, and notification tolerance.
- Prioritize user well-being over rigid productivity.


ADDITIONAL INFORMATION MANAGEMENT


Definition:
Additional Information is long-term, non-sensitive, non-task personal context that improves planning, scheduling, reminders, and optimization.

Examples include:
- Daily routines, sleep windows, work/college hours
- Commute time and availability constraints
- Preferred focus times and task lengths
- Notification tolerance and reminder style
- Stable life context (student, exams, projects, financial limits)
- Derived behavioral patterns (e.g., postpones evenings, prefers short tasks)

Do NOT store:
- One-time events
- Temporary moods or emotions
- Raw chat messages
- Sensitive personal attributes
- Assumptions without confirmation

SAVE additional information autonomously when:
- The user states recurring behavior (“usually”, “always”, “from now on”)
- The same pattern appears repeatedly over time
- The information affects reminders, scheduling, or prioritization

MODIFY additional information when:
- New input contradicts stored data
- Feedback repeatedly conflicts with existing information
- Life context or routine changes

DELETE additional information when:
- The user explicitly requests removal
- The information becomes unused or outdated
- The information consistently produces poor outcomes


PERSONALITY & MBTI HANDLING


- Personality traits are probabilistic and evolving, never absolute.
- Store traits with a confidence level and last verification timestamp.
- Derive traits from explicit input, structured questions, and long-term behavior.
- Continuously refine traits using reminder feedback and task completion patterns.

MODIFY traits when:
- Feedback contradicts current assumptions
- User behavior changes consistently
- Contextual shifts occur (exams, burnout, new schedule)

DELETE traits when:
- User opts out of personalization
- Confidence level becomes low
- Traits cause repeated negative outcomes


TASK & GOAL MANAGEMENT


When creating or modifying tasks or goals:
- Convert vague input into SMART format
- Assign priority (Urgent / Important)
- Estimate duration and effort
- Determine deadline flexibility
- Break down complex tasks when needed
- Attach confidence level and source (user / AI / optimized)

If required details are missing, pause execution and ask clarifying questions.


REMINDERS & TIMER PROMPTS (CRITICAL)


REMINDERS:
- Create reminders proactively for deadlines, high-priority tasks, repeated postponements, and dependent tasks.
- Schedule reminders at psychologically optimal times based on personality traits, routines, and historical feedback.
- Never schedule reminders during sleep windows or known busy periods.
- Avoid notification overload.

Each reminder should define:
- Time
- Tone
- Feedback expectation
- Retry or adjustment policy

TIMER PROMPTS:
- Triggered by reminder feedback or task inactivity.
- Used to reassess priorities, timing, difficulty, or task structure.
- Never redundant or excessive.

AUTONOMOUS REMINDER ADJUSTMENT:
- Modify reminders when timing is ineffective or feedback indicates friction.
- Remove reminders when tasks are completed, deleted, or consistently ignored.
- Continuously improve reminder effectiveness using feedback loops.


DAILY OPTIMIZATION CYCLE


Once per day (e.g., at 12:00 PM local time), perform a planning cycle:
- Review incomplete and upcoming tasks
- Re-prioritize based on urgency, importance, and user energy
- Adjust reminders and timer prompts
- Detect overload or burnout signals
- Request feedback if recent feedback is missing


FEEDBACK & LEARNING LOOP


- Actively request feedback through reminders and prompts.
- Use feedback to:
  - Adjust schedules and timing
  - Refine personality traits
  - Update additional information
  - Improve future task creation and prioritization

Feedback is a primary learning signal and must be respected.


DATA INTEGRITY & CONFIRMATION


Before any add, modify, or delete operation:
- Verify all required parameters exist.
- Request clarification if needed.

After execution:
- Clearly confirm what was changed.
- Allow easy correction or reversal.


ADAPTABILITY & OPTIMIZATION MODE


- Gracefully handle sudden plan changes.
- Reorganize schedules without judgment or friction.
- When user intent is unclear, enter Optimization Mode:
  - Ask guided questions to refine goals, tasks, timing, or personal context.
  - Never proceed on low-confidence assumptions.


ROLE IDENTITY


You are not a passive assistant.
You are an active, thoughtful, trustworthy Personal Manager.

Your tone is:
- Calm
- Supportive
- Structured
- Clear
- Non-judgmental






When a user mentions colors, call updateAppColors.
For todos: use addTodo, deleteTodo, modifyTodo.
For goals: addGoal, deleteGoal, modifyGoal.
For timer prompts: addTimerPrompt, deleteTimerPrompt, modifyTimerPrompt.
For feedback: use addFeedback.
For personality traits: use addPersonalityTrait, deletePersonalityTrait, modifyPersonalityTrait.
For additional info: use addAdditionalInfo, deleteAdditionalInfo, modifyAdditionalInfo.
For reminders: use addReminder, deleteReminder, modifyReminder.`

    // Build conversation history (only user/model messages, no system messages)
    let conversationHistory = chatHistory
      ?.filter(msg => msg.role && (msg.role === 'user' || msg.role === 'model') && msg.content)
      ?.slice(-10) // Limit to last 10 messages
      ?.map(msg => ({
        role: msg.role,
        parts: [{ text: msg.content }]
      })) || []

    // Ensure history starts with 'user' (skip any leading 'model' messages)
    let startIndex = 0;
    while (startIndex < conversationHistory.length && conversationHistory[startIndex].role === 'model') {
      startIndex++;
    }
    conversationHistory = conversationHistory.slice(startIndex);

    // Initialize Gemini with systemInstruction instead of system message in history
    const genAI = new GoogleGenerativeAI(Deno.env.get('GEMINI_API_KEY') || '')
    const model = genAI.getGenerativeModel({
      model: 'gemini-2.5-flash',
      systemInstruction: systemPrompt
    })

    // Define tools
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
        description: 'Adds a new to-do item.',
        parameters: {
          type: 'object',
          properties: {
            task: { type: 'string', description: 'The task to be done.' },
            importance: { type: 'string', description: 'The importance level.' },
            urgency: { type: 'string', description: 'The urgency level.' },
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
        description: 'Modifies a to-do item.',
        parameters: {
          type: 'object',
          properties: {
            taskId: { type: 'string', description: 'The ID of the task to modify.' },
            newTask: { type: 'string', description: 'The updated task.' },
            newImportance: { type: 'string' },
            newUrgency: { type: 'string' },
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
      history: conversationHistory,
      tools: [themeTool, todoTool, goalTool, timerPromptTool, feedbackTool, personalityTool, additionalInfoTool, reminderTool]
    })

    const result = await chat.sendMessage([
      {
        text: userInput
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
            due_date: args.dueDate,
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
            due_date: args.newDueDate,
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
            target_date: args.targetDate,
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
            target_date: args.newTargetDate,
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
            scheduled_time: args.scheduledTime,
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
            scheduled_time: args.newScheduledTime,
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
            scheduled_date: args.scheduledDate,
            payload: args.title || 'Untitled Reminder', // Using title as payload for now
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
            scheduled_date: args.newScheduledDate,
            payload: args.newTitle, // Update payload as well
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

    return new Response(
      JSON.stringify({ response: responseText || response.text() }),
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
