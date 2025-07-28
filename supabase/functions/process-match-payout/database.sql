-- Database function for processing match payouts
CREATE OR REPLACE FUNCTION process_match_payout(
  p_match_id UUID,
  p_winner_id UUID,
  p_payout_amount INTEGER,
  p_fee_amount INTEGER
)
RETURNS VOID AS $$
DECLARE
  v_user_balance INTEGER;
  v_user_withdrawable INTEGER;
  v_initial_stake INTEGER;
BEGIN
  -- Start transaction
  BEGIN
    -- Get winner's current balance
    SELECT total_balance, withdrawable_balance 
    INTO v_user_balance, v_user_withdrawable
    FROM users 
    WHERE id = p_winner_id 
    FOR UPDATE;

    -- Get winner's initial stake
    SELECT stake_amount 
    INTO v_initial_stake
    FROM match_participants
    WHERE match_id = p_match_id AND user_id = p_winner_id;

    -- Update winner's balance
    UPDATE users 
    SET 
      total_balance = total_balance + p_payout_amount,
      withdrawable_balance = withdrawable_balance + (p_payout_amount - v_initial_stake)
    WHERE id = p_winner_id;

    -- Create payout transaction
    INSERT INTO transactions (
      user_id,
      amount,
      type,
      related_match_id,
      metadata
    ) VALUES (
      p_winner_id,
      p_payout_amount,
      'match_payout',
      p_match_id,
      jsonb_build_object(
        'initial_stake', v_initial_stake,
        'profit', p_payout_amount - v_initial_stake
      )
    );

    -- Record platform fee if applicable
    IF p_fee_amount > 0 THEN
      INSERT INTO platform_wallet (fee_amount, match_id)
      VALUES (p_fee_amount, p_match_id);
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      -- Rollback on any error
      RAISE;
  END;
END;
$$ LANGUAGE plpgsql;

-- Function to handle dispute resolution
CREATE OR REPLACE FUNCTION resolve_match_dispute(
  p_match_id UUID,
  p_resolution TEXT,
  p_winner_id UUID DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
  IF p_resolution = 'refund' THEN
    -- Refund all participants
    INSERT INTO transactions (user_id, amount, type, related_match_id)
    SELECT 
      user_id,
      stake_amount,
      'match_refund',
      p_match_id
    FROM match_participants
    WHERE match_id = p_match_id;

    -- Update balances
    UPDATE users u
    SET 
      total_balance = u.total_balance + mp.stake_amount,
      withdrawable_balance = u.withdrawable_balance + mp.stake_amount
    FROM match_participants mp
    WHERE u.id = mp.user_id AND mp.match_id = p_match_id;

    -- Update match status
    UPDATE matches
    SET status = 'cancelled', completed_at = NOW()
    WHERE id = p_match_id;

  ELSIF p_resolution = 'award' AND p_winner_id IS NOT NULL THEN
    -- Award to specific winner after dispute review
    PERFORM process_match_payout(
      p_match_id,
      p_winner_id,
      (SELECT total_pot FROM matches WHERE id = p_match_id),
      0 -- No fees on disputed matches
    );
  END IF;
END;
$$ LANGUAGE plpgsql;