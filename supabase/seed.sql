-- Seed data for testing

-- Test users (passwords will need to be created through Auth)
INSERT INTO users (id, email, username, total_balance, withdrawable_balance, subscription_status, region, age_verified) VALUES
  ('11111111-1111-1111-1111-111111111111', 'free@test.com', 'test_free', 1000, 800, 'free', 'United States', true),
  ('22222222-2222-2222-2222-222222222222', 'premium@test.com', 'test_premium', 5000, 4500, 'premium', 'United States', true),
  ('33333333-3333-3333-3333-333333333333', 'rich@test.com', 'test_rich', 10000, 9000, 'free', 'United States', true),
  ('44444444-4444-4444-4444-444444444444', 'friend1@test.com', 'friend_one', 750, 600, 'free', 'Canada', true),
  ('55555555-5555-5555-5555-555555555555', 'friend2@test.com', 'friend_two', 2000, 1800, 'premium', 'United Kingdom', true);

-- Test friendships
INSERT INTO friendships (requester_id, recipient_id, status, accepted_at) VALUES
  ('11111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444444', 'accepted', NOW()),
  ('11111111-1111-1111-1111-111111111111', '55555555-5555-5555-5555-555555555555', 'accepted', NOW()),
  ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'accepted', NOW()),
  ('33333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 'pending', NULL);

-- Test activity templates
INSERT INTO activity_templates (id, name, category, is_premium, default_rules, icon_name, suggested_stakes) VALUES
  ('a1111111-1111-1111-1111-111111111111', 'Test Chess', 'Board Games', false, 'Standard chess rules for testing', 'crown', ARRAY[50, 100, 200]),
  ('a2222222-2222-2222-2222-222222222222', 'Test Poker', 'Card Games', false, 'Texas Hold''em test rules', 'suit.heart.fill', ARRAY[100, 200, 500]),
  ('a3333333-3333-3333-3333-333333333333', 'Test Basketball', 'Sports', false, 'First to 21 points', 'basketball.fill', ARRAY[50, 100, 250]),
  ('a4444444-4444-4444-4444-444444444444', 'Premium Chess', 'Premium', true, 'High stakes chess', 'crown.fill', ARRAY[500, 1000, 2000]);

-- Test matches
INSERT INTO matches (id, creator_id, activity_type, activity_template_id, stake_amount, total_pot, status, created_at) VALUES
  ('m1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Test Chess', 'a1111111-1111-1111-1111-111111111111', 100, 200, 'active', NOW() - INTERVAL '1 hour'),
  ('m2222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222', 'Test Poker', 'a2222222-2222-2222-2222-222222222222', 200, 600, 'voting', NOW() - INTERVAL '2 hours'),
  ('m3333333-3333-3333-3333-333333333333', '44444444-4444-4444-4444-444444444444', 'Test Basketball', 'a3333333-3333-3333-3333-333333333333', 50, 50, 'pending', NOW() - INTERVAL '10 minutes');

-- Test match participants
INSERT INTO match_participants (match_id, user_id, stake_amount, joined_at) VALUES
  ('m1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 100, NOW() - INTERVAL '1 hour'),
  ('m1111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444444', 100, NOW() - INTERVAL '50 minutes'),
  ('m2222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222', 200, NOW() - INTERVAL '2 hours'),
  ('m2222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 200, NOW() - INTERVAL '1 hour 50 minutes'),
  ('m2222222-2222-2222-2222-222222222222', '55555555-5555-5555-5555-555555555555', 200, NOW() - INTERVAL '1 hour 45 minutes'),
  ('m3333333-3333-3333-3333-333333333333', '44444444-4444-4444-4444-444444444444', 50, NOW() - INTERVAL '10 minutes');

-- Test transactions
INSERT INTO transactions (user_id, amount, type, created_at) VALUES
  ('11111111-1111-1111-1111-111111111111', 500, 'deposit', NOW() - INTERVAL '7 days'),
  ('11111111-1111-1111-1111-111111111111', -100, 'match_stake', NOW() - INTERVAL '1 hour'),
  ('22222222-2222-2222-2222-222222222222', 2000, 'deposit', NOW() - INTERVAL '14 days'),
  ('22222222-2222-2222-2222-222222222222', -200, 'match_stake', NOW() - INTERVAL '2 hours'),
  ('22222222-2222-2222-2222-222222222222', 500, 'match_payout', NOW() - INTERVAL '1 day'),
  ('44444444-4444-4444-4444-444444444444', 300, 'deposit', NOW() - INTERVAL '3 days'),
  ('44444444-4444-4444-4444-444444444444', -50, 'match_stake', NOW() - INTERVAL '10 minutes');

-- Test match activities
INSERT INTO match_activities (match_id, user_id, activity_type, message) VALUES
  ('m1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'create', 'test_free created the match'),
  ('m1111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444444', 'join', 'friend_one joined the match'),
  ('m1111111-1111-1111-1111-111111111111', NULL, 'start', 'Match has started!'),
  ('m2222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222', 'create', 'test_premium created the match'),
  ('m2222222-2222-2222-2222-222222222222', NULL, 'voting', 'Voting phase has begun');

-- Update match voting data for testing
UPDATE match_participants SET has_voted = true, vote_for_user_id = '22222222-2222-2222-2222-222222222222' 
WHERE match_id = 'm2222222-2222-2222-2222-222222222222' AND user_id = '11111111-1111-1111-1111-111111111111';

UPDATE match_participants SET has_voted = true, vote_for_user_id = '22222222-2222-2222-2222-222222222222' 
WHERE match_id = 'm2222222-2222-2222-2222-222222222222' AND user_id = '55555555-5555-5555-5555-555555555555';

-- Add some platform fees
INSERT INTO platform_wallet (fee_amount, match_id) VALUES
  (10, 'm2222222-2222-2222-2222-222222222222');

-- Grant permissions for testing
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO postgres, anon, authenticated, service_role;