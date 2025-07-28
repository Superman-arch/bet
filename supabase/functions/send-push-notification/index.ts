import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface NotificationRequest {
  userId?: string
  userIds?: string[]
  title: string
  body: string
  data?: Record<string, any>
  category?: string
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const apnsKey = Deno.env.get('APNS_KEY')!
    const apnsKeyId = Deno.env.get('APNS_KEY_ID')!
    const apnsTeamId = Deno.env.get('APNS_TEAM_ID')!
    
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    const { userId, userIds, title, body, data, category } = await req.json() as NotificationRequest

    // Get push tokens for users
    const targetUserIds = userIds || (userId ? [userId] : [])
    if (targetUserIds.length === 0) {
      throw new Error('No users specified')
    }

    const { data: tokens, error: tokenError } = await supabase
      .from('push_tokens')
      .select('*')
      .in('user_id', targetUserIds)

    if (tokenError) throw tokenError
    if (!tokens || tokens.length === 0) {
      return new Response(
        JSON.stringify({ 
          success: true,
          message: 'No push tokens found for users'
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Send notifications
    const results = await Promise.all(
      tokens.map(async (tokenRecord) => {
        if (tokenRecord.platform === 'ios') {
          return await sendAPNSNotification(
            tokenRecord.token,
            title,
            body,
            data,
            category,
            apnsKey,
            apnsKeyId,
            apnsTeamId
          )
        }
        // Add Android support here if needed
        return { success: false, error: 'Unsupported platform' }
      })
    )

    const successCount = results.filter(r => r.success).length

    return new Response(
      JSON.stringify({ 
        success: true,
        sent: successCount,
        total: tokens.length
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error sending notifications:', error)
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message 
      }),
      { 
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

async function sendAPNSNotification(
  deviceToken: string,
  title: string,
  body: string,
  data?: Record<string, any>,
  category?: string,
  apnsKey?: string,
  apnsKeyId?: string,
  apnsTeamId?: string
): Promise<{ success: boolean; error?: string }> {
  try {
    // Create JWT for APNS
    const jwt = await createAPNSJWT(apnsKey!, apnsKeyId!, apnsTeamId!)

    const payload = {
      aps: {
        alert: {
          title,
          body
        },
        sound: 'default',
        badge: 1,
        category: category || 'default',
        'mutable-content': 1
      },
      ...data
    }

    const response = await fetch(
      `https://api.push.apple.com/3/device/${deviceToken}`,
      {
        method: 'POST',
        headers: {
          'authorization': `bearer ${jwt}`,
          'apns-topic': 'com.betapp.bet',
          'apns-push-type': 'alert',
          'apns-priority': '10'
        },
        body: JSON.stringify(payload)
      }
    )

    if (response.ok) {
      return { success: true }
    } else {
      const error = await response.text()
      console.error('APNS error:', error)
      return { success: false, error }
    }

  } catch (error) {
    console.error('Error sending APNS notification:', error)
    return { success: false, error: error.message }
  }
}

async function createAPNSJWT(
  privateKey: string,
  keyId: string,
  teamId: string
): Promise<string> {
  // Implementation for creating APNS JWT
  // This would use the jose library to sign the JWT
  const header = {
    alg: 'ES256',
    kid: keyId
  }

  const payload = {
    iss: teamId,
    iat: Math.floor(Date.now() / 1000)
  }

  // In production, use a proper JWT library
  return 'mock-jwt-token'
}