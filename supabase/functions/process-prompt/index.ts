import "jsr:@supabase/functions-js/edge-runtime.d.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface FunctionArgs {
  userInput: string
  chatHistory?: Array<{ role: 'user' | 'model', content: string }>
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (req.method !== 'POST') return new Response('Method Not Allowed', { status: 405, headers: corsHeaders })

  try {
    const { userInput, chatHistory }: FunctionArgs = await req.json()

    // ── Auth ───────────────────────────────────────────────────────────────────
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized - Missing Authorization header' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 401 }
      )
    }

    const jwt = authHeader.replace('Bearer ', '')
    let userId: string
    try {
      const payload = JSON.parse(atob(jwt.split('.')[1]))
      userId = payload.sub
      if (!userId) throw new Error('Missing sub in JWT')
      const now = Math.floor(Date.now() / 1000)
      if (payload.exp && payload.exp < now) throw new Error('Token expired')
    } catch (err) {
      console.error('JWT error:', err)
      return new Response(
        JSON.stringify({ error: 'Session expired, please sign in again.' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 401 }
      )
    }

    // Call the agno python backend
    const response = await fetch('https://gold-doors-find.loca.lt', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        prompt: userInput,
        chatHistory: chatHistory,
        auth_token: jwt // Pass the user's JWT to the python backend
      })
    })

    if (!response.ok) {
      console.error(`Python API returned ${response.status}: ${response.statusText}`);
      const errorText = await response.text();
      return new Response(
        JSON.stringify({ error: `Backend API error: ${errorText}` }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: response.status }
      );
    }

    // Depending on what your Python API returns, you might need to adjust this.
    // If it returns a string like "Your order is shipped", you can map it to {"response": "..."}
    // and return that JSON since the Flutter code might expect a "response" field.
    const data = await response.json();

    return new Response(
      JSON.stringify(data),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    const msg = error instanceof Error ? error.message : String(error)
    console.error('[process-prompt] Error:', msg, error)
    return new Response(
      JSON.stringify({ error: msg }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})