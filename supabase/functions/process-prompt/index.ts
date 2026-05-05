import "jsr:@supabase/functions-js/edge-runtime.d.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface Message {
  role: 'user' | 'assistant' | 'system'
  content: string
}

interface FunctionArgs {
  userInput: string
  chatHistory?: Array<{ role: 'user' | 'model', content: string }>
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (req.method !== 'POST') return new Response('Method Not Allowed', { status: 405, headers: corsHeaders })

  try {
    const { userInput, chatHistory }: FunctionArgs = await req.json()

    // 1. Get OpenRouter API Key from Supabase Environment Variables
    const OPENROUTER_API_KEY = Deno.env.get('OPENROUTER_API_KEY')
    if (!OPENROUTER_API_KEY) {
      throw new Error('Missing OPENROUTER_API_KEY environment variable')
    }

    // 2. Format Chat History for OpenRouter (OpenAI format)
    // Note: We map 'model' to 'assistant' as per OpenRouter requirements
    const messages: Message[] = (chatHistory || []).map(msg => ({
      role: msg.role === 'model' ? 'assistant' : 'user',
      content: msg.content
    }))

    // Add the latest user input
    messages.push({ role: 'user', content: userInput })

    // 3. Call OpenRouter API
    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
        'HTTP-Referer': 'https://supabase.com', // Optional: OpenRouter likes to see where traffic comes from
        'X-Title': 'Supabase Edge Function',   // Optional: Your app name
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'google/gemini-2.0-flash-001', // You can change this to any OpenRouter model slug
        messages: messages,
      })
    })

    if (!response.ok) {
      const errorData = await response.json()
      console.error('OpenRouter Error:', errorData)
      return new Response(
        JSON.stringify({ error: errorData.error?.message || 'OpenRouter API Error' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: response.status }
      )
    }

    const data = await response.json()

    // 4. Extract the completion text and return it
    // We wrap it in a "response" key to make it easy for your frontend to consume
    const aiResponse = data.choices?.[0]?.message?.content || ''

    return new Response(
      JSON.stringify({ response: aiResponse }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    const msg = error instanceof Error ? error.message : String(error)
    console.error('[openrouter-proxy] Error:', msg)
    return new Response(
      JSON.stringify({ error: msg }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})