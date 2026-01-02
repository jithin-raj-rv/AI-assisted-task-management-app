import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { GoogleGenerativeAI } from "https://esm.sh/@google/generative-ai"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface FunctionArgs {
  userId: string
  userInput: string
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { userId, userInput }: FunctionArgs = await req.json()

    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Fetch user data
    const [todosRes, goalsRes, settingsRes] = await Promise.all([
      supabaseClient.from('todos').select('*').eq('user_id', userId),
      supabaseClient.from('goals').select('*').eq('user_id', userId),
      supabaseClient.from('user_settings').select('*').eq('user_id', userId)
    ])

    if (todosRes.error || goalsRes.error || settingsRes.error) {
      throw new Error('Failed to fetch user data')
    }

    const todolist = todosRes.data || []
    const goals = goalsRes.data || []
    const settings = settingsRes.data || []

    const personality = settings.find(s => s.setting_key === 'personality')?.setting_value || []
    const additionalInfo = settings.find(s => s.setting_key === 'additional_info')?.setting_value || []

    // Initialize Gemini
    const genAI = new GoogleGenerativeAI(Deno.env.get('GEMINI_API_KEY') || '')
    const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' })

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
            dueDate: { type: 'string', description: 'Due date in ISO format.' }
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
            newDueDate: { type: 'string' }
          },
          required: ['taskId', 'newTask']
        }
      }]
    }

    // Similar for goalTool, personalityTool, additionalInfoTool

    const generationConfig = {
      temperature: 1,
      topP: 0.95,
      topK: 64,
      maxOutputTokens: 8192,
      responseMimeType: 'text/plain',
    }

    const chat = model.startChat({
      generationConfig,
      history: []
    })

    const result = await chat.sendMessage([
      {
        text: `You have access to User todolist: ${JSON.stringify(todolist)}
User goals: ${JSON.stringify(goals)}
User personality: ${JSON.stringify(personality)}
User additional info: ${JSON.stringify(additionalInfo)}

You are a professional Personal manager. When a user mentions colors, call updateAppColors.
For todos: use addTodo, deleteTodo, modifyTodo.
For goals: addGoal, deleteGoal, modifyGoal.
For personality: addPersonality, deletePersonality, modifyPersonality.
For additional info: addAdditionalInfo, deleteAdditionalInfo, modifyAdditionalInfo.`
      },
      {
        text: userInput
      }
    ])

    const response = await result.response
    const functionCalls = response.functionCalls()

    let responseText = ''

    for (const call of functionCalls) {
      if (call.name === 'addTodo') {
        const { task, importance, urgency, description, dueDate } = call.args
        const { error } = await supabaseClient.from('todos').insert({
          user_id: userId,
          task_name: task,
          importance,
          urgency,
          description,
          due_date: dueDate
        })
        if (error) throw error
        responseText += `Added todo: ${task}\n`
      }
      // Handle other function calls similarly
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
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})
