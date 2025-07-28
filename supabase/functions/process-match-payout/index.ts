import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface PayoutRequest {
  matchId: string
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    const { matchId } = await req.json() as PayoutRequest

    // 1. Get match details
    const { data: match, error: matchError } = await supabase
      .from('matches')
      .select(`
        *,
        participants:match_participants(
          *,
          user:users(*)
        )
      `)
      .eq('id', matchId)
      .single()

    if (matchError) throw matchError
    if (!match) throw new Error('Match not found')

    // 2. Check if all participants have voted
    const totalParticipants = match.participants.length
    const votedParticipants = match.participants.filter((p: any) => p.has_voted).length

    if (match.status !== 'voting') {
      throw new Error('Match is not in voting phase')
    }

    // Check if voting deadline has passed
    const votingDeadline = new Date(match.voting_deadline)
    const now = new Date()
    const allVoted = totalParticipants === votedParticipants

    if (!allVoted && now < votingDeadline) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          message: 'Voting still in progress' 
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 3. Calculate vote results
    const voteCount: Record<string, number> = {}
    match.participants.forEach((p: any) => {
      if (p.has_voted && p.vote_for_user_id) {
        voteCount[p.vote_for_user_id] = (voteCount[p.vote_for_user_id] || 0) + 1
      }
    })

    // 4. Determine winner or if disputed
    const sortedVotes = Object.entries(voteCount).sort((a, b) => b[1] - a[1])
    const isDisputed = sortedVotes.length > 1 && sortedVotes[0][1] === sortedVotes[1][1]

    if (isDisputed) {
      // Handle dispute
      const disputeDeadline = new Date()
      disputeDeadline.setHours(disputeDeadline.getHours() + 24)

      await supabase
        .from('matches')
        .update({ 
          status: 'disputed',
          dispute_deadline: disputeDeadline.toISOString()
        })
        .eq('id', matchId)

      // Send dispute notifications
      await sendDisputeNotifications(match.participants, match)

      return new Response(
        JSON.stringify({ 
          success: true, 
          disputed: true,
          message: 'Match is disputed. Players have 24 hours to submit evidence.' 
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 5. Process payout
    const winnerId = sortedVotes[0][0]
    const winner = match.participants.find((p: any) => p.user_id === winnerId)
    
    // Calculate fees
    const hasNonPremiumUsers = match.participants.some((p: any) => 
      p.user?.subscription_status === 'free'
    )
    const feePercentage = hasNonPremiumUsers ? 0.02 : 0
    const feeAmount = Math.floor(match.total_pot * feePercentage)
    const payoutAmount = match.total_pot - feeAmount

    // Begin transaction
    const { error: transactionError } = await supabase.rpc('process_match_payout', {
      p_match_id: matchId,
      p_winner_id: winnerId,
      p_payout_amount: payoutAmount,
      p_fee_amount: feeAmount
    })

    if (transactionError) throw transactionError

    // Update match status
    await supabase
      .from('matches')
      .update({ 
        status: 'completed',
        completed_at: new Date().toISOString()
      })
      .eq('id', matchId)

    // Update winner flag
    await supabase
      .from('match_participants')
      .update({ is_winner: true })
      .eq('match_id', matchId)
      .eq('user_id', winnerId)

    // Send payout notifications
    await sendPayoutNotifications(match.participants, winner, payoutAmount)

    // Log match activity
    await supabase
      .from('match_activities')
      .insert({
        match_id: matchId,
        activity_type: 'payout',
        message: `${winner.user.username} won ${payoutAmount} tokens!`
      })

    return new Response(
      JSON.stringify({ 
        success: true,
        winner_id: winnerId,
        payout_amount: payoutAmount,
        fee_amount: feeAmount
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error processing payout:', error)
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

async function sendPayoutNotifications(participants: any[], winner: any, amount: number) {
  // Implementation for sending push notifications
  console.log(`Sending payout notifications: ${winner.user.username} won ${amount} tokens`)
}

async function sendDisputeNotifications(participants: any[], match: any) {
  // Implementation for sending dispute notifications
  console.log(`Sending dispute notifications for match ${match.id}`)
}