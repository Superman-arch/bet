import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Check for matches that should start
    const { data: pendingMatches, error } = await supabase
      .from('matches')
      .select(`
        *,
        participants:match_participants(*)
      `)
      .eq('status', 'pending')
      .lte('created_at', new Date(Date.now() - 5 * 60 * 1000).toISOString()) // 5 minutes old

    if (error) throw error

    const startedMatches = []
    const cancelledMatches = []

    for (const match of pendingMatches || []) {
      const participantCount = match.participants.length

      if (participantCount >= 2) {
        // Start the match
        await supabase
          .from('matches')
          .update({ 
            status: 'active',
            started_at: new Date().toISOString()
          })
          .eq('id', match.id)

        // Log activity
        await supabase
          .from('match_activities')
          .insert({
            match_id: match.id,
            activity_type: 'start',
            message: 'Match has started!'
          })

        startedMatches.push(match.id)

        // Send notifications to participants
        await sendMatchStartNotifications(match)

      } else if (new Date(match.created_at) < new Date(Date.now() - 30 * 60 * 1000)) {
        // Cancel matches older than 30 minutes with insufficient players
        await supabase
          .from('matches')
          .update({ 
            status: 'cancelled',
            completed_at: new Date().toISOString()
          })
          .eq('id', match.id)

        // Refund the creator
        if (participantCount === 1) {
          await refundStake(match.participants[0])
        }

        cancelledMatches.push(match.id)
      }
    }

    return new Response(
      JSON.stringify({ 
        success: true,
        started: startedMatches,
        cancelled: cancelledMatches
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error checking match starts:', error)
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

async function sendMatchStartNotifications(match: any) {
  // Implementation for sending push notifications
  console.log(`Sending start notifications for match ${match.id}`)
}

async function refundStake(participant: any) {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  const supabase = createClient(supabaseUrl, supabaseServiceKey)

  // Create refund transaction
  await supabase
    .from('transactions')
    .insert({
      user_id: participant.user_id,
      amount: participant.stake_amount,
      type: 'match_refund',
      related_match_id: participant.match_id
    })

  // Update user balance
  await supabase
    .from('users')
    .update({
      total_balance: supabase.raw('total_balance + ?', [participant.stake_amount]),
      withdrawable_balance: supabase.raw('withdrawable_balance + ?', [participant.stake_amount])
    })
    .eq('id', participant.user_id)
}