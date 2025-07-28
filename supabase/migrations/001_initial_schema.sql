-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create custom types
CREATE TYPE subscription_status AS ENUM ('free', 'premium', 'premium_trial');
CREATE TYPE match_status AS ENUM ('pending', 'active', 'voting', 'disputed', 'completed', 'cancelled');
CREATE TYPE friendship_status AS ENUM ('pending', 'accepted', 'declined', 'blocked');
CREATE TYPE transaction_type AS ENUM ('deposit', 'withdrawal', 'match_stake', 'match_payout', 'match_refund', 'bonus', 'fee');

-- Users table with dual balance tracking
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    phone TEXT UNIQUE,
    username TEXT UNIQUE NOT NULL,
    total_balance INTEGER DEFAULT 500 CHECK (total_balance >= 0),
    withdrawable_balance INTEGER DEFAULT 0 CHECK (withdrawable_balance >= 0),
    subscription_status subscription_status DEFAULT 'free',
    subscription_expires_at TIMESTAMP WITH TIME ZONE,
    premium_trial_uses JSONB DEFAULT '{}',
    region TEXT NOT NULL,
    age_verified BOOLEAN DEFAULT false,
    profile_image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT balance_check CHECK (withdrawable_balance <= total_balance)
);

-- Activity templates
CREATE TABLE activity_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    is_premium BOOLEAN DEFAULT false,
    default_rules TEXT,
    icon_name TEXT,
    suggested_stakes INTEGER[] DEFAULT ARRAY[50, 100, 200, 500],
    free_trial_limit INTEGER DEFAULT 3,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Matches with custom rules
CREATE TABLE matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID REFERENCES users(id) ON DELETE CASCADE,
    activity_type TEXT NOT NULL,
    activity_template_id UUID REFERENCES activity_templates(id),
    custom_rules TEXT,
    stake_amount INTEGER NOT NULL CHECK (stake_amount > 0),
    total_pot INTEGER DEFAULT 0 CHECK (total_pot >= 0),
    status match_status DEFAULT 'pending',
    is_premium_only BOOLEAN DEFAULT false,
    dispute_proof_url TEXT[],
    dispute_deadline TIMESTAMP WITH TIME ZONE,
    voting_deadline TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Match participants with leave requests
CREATE TABLE match_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    stake_amount INTEGER NOT NULL CHECK (stake_amount > 0),
    is_winner BOOLEAN DEFAULT false,
    has_voted BOOLEAN DEFAULT false,
    vote_for_user_id UUID REFERENCES users(id),
    leave_requested BOOLEAN DEFAULT false,
    leave_approved_by UUID[] DEFAULT '{}',
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(match_id, user_id)
);

-- Friend relationships
CREATE TABLE friendships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_id UUID REFERENCES users(id) ON DELETE CASCADE,
    recipient_id UUID REFERENCES users(id) ON DELETE CASCADE,
    status friendship_status DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    accepted_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(requester_id, recipient_id),
    CONSTRAINT no_self_friendship CHECK (requester_id != recipient_id)
);

-- Transactions with detailed tracking
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    amount INTEGER NOT NULL,
    type transaction_type NOT NULL,
    subtype TEXT,
    related_match_id UUID REFERENCES matches(id),
    stripe_payment_intent_id TEXT,
    stripe_payout_id TEXT,
    bonus_amount INTEGER DEFAULT 0,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Platform analytics
CREATE TABLE platform_wallet (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fee_amount INTEGER NOT NULL CHECK (fee_amount >= 0),
    match_id UUID REFERENCES matches(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Regional compliance settings
CREATE TABLE compliance_settings (
    region TEXT PRIMARY KEY,
    is_allowed BOOLEAN DEFAULT true,
    age_requirement INTEGER DEFAULT 18 CHECK (age_requirement >= 0),
    max_daily_deposit INTEGER,
    max_single_stake INTEGER,
    requires_kyc BOOLEAN DEFAULT false,
    kyc_threshold INTEGER DEFAULT 5000,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- KYC verification records
CREATE TABLE kyc_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    status TEXT DEFAULT 'pending',
    verification_level INTEGER DEFAULT 0,
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    verified_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}'
);

-- Match activity log
CREATE TABLE match_activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    activity_type TEXT NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Push notification tokens
CREATE TABLE push_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    platform TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, token)
);

-- Indexes for performance
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_matches_status ON matches(status);
CREATE INDEX idx_matches_creator ON matches(creator_id);
CREATE INDEX idx_match_participants_user ON match_participants(user_id);
CREATE INDEX idx_match_participants_match ON match_participants(match_id);
CREATE INDEX idx_friendships_requester ON friendships(requester_id);
CREATE INDEX idx_friendships_recipient ON friendships(recipient_id);
CREATE INDEX idx_transactions_user ON transactions(user_id);
CREATE INDEX idx_transactions_created ON transactions(created_at);

-- Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE match_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can read their own data and update certain fields
CREATE POLICY users_read_own ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY users_update_own ON users FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Users can see matches they're part of or public matches
CREATE POLICY matches_read ON matches FOR SELECT USING (
  creator_id = auth.uid() OR
  EXISTS (SELECT 1 FROM match_participants WHERE match_id = matches.id AND user_id = auth.uid()) OR
  NOT is_premium_only
);

-- Participants can be viewed by match members
CREATE POLICY participants_read ON match_participants FOR SELECT USING (
  user_id = auth.uid() OR
  EXISTS (SELECT 1 FROM match_participants mp WHERE mp.match_id = match_participants.match_id AND mp.user_id = auth.uid())
);

-- Friendships visible to both parties
CREATE POLICY friendships_read ON friendships FOR SELECT USING (
  requester_id = auth.uid() OR recipient_id = auth.uid()
);

-- Users can only see their own transactions
CREATE POLICY transactions_read_own ON transactions FOR SELECT USING (user_id = auth.uid());

-- Functions and Triggers
-- Update timestamp trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to check match voting completion
CREATE OR REPLACE FUNCTION check_voting_completion(match_id_param UUID)
RETURNS BOOLEAN AS $$
DECLARE
    total_participants INTEGER;
    total_votes INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_participants 
    FROM match_participants 
    WHERE match_id = match_id_param;
    
    SELECT COUNT(*) INTO total_votes 
    FROM match_participants 
    WHERE match_id = match_id_param AND has_voted = true;
    
    RETURN total_participants = total_votes AND total_participants > 0;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate match winner
CREATE OR REPLACE FUNCTION calculate_match_winner(match_id_param UUID)
RETURNS UUID AS $$
DECLARE
    winner_id UUID;
BEGIN
    SELECT vote_for_user_id
    INTO winner_id
    FROM match_participants
    WHERE match_id = match_id_param AND has_voted = true
    GROUP BY vote_for_user_id
    ORDER BY COUNT(*) DESC
    LIMIT 1;
    
    RETURN winner_id;
END;
$$ LANGUAGE plpgsql;

-- Insert default compliance settings
INSERT INTO compliance_settings (region, is_allowed, age_requirement, max_daily_deposit, max_single_stake, requires_kyc) VALUES
  ('United States', true, 21, 10000, null, true),
  ('United Kingdom', true, 18, null, 5000, true),
  ('Canada', true, 19, null, null, false),
  ('Australia', true, 18, null, null, true),
  ('Germany', true, 18, null, null, true),
  ('France', true, 18, null, null, false),
  ('Spain', true, 18, null, null, false),
  ('Italy', true, 18, null, null, false),
  ('Netherlands', true, 18, null, null, false),
  ('Sweden', true, 18, null, null, false),
  ('Norway', true, 18, null, null, false),
  ('Denmark', true, 18, null, null, false);

-- Insert default activity templates
INSERT INTO activity_templates (name, category, is_premium, default_rules, icon_name) VALUES
  ('Chess', 'Board Games', false, 'Standard chess rules. Winner determined by checkmate or resignation.', 'crown'),
  ('Poker', 'Card Games', false, 'Texas Hold''em rules. Winner takes the pot.', 'suit.heart.fill'),
  ('Basketball 1v1', 'Sports', false, 'First to 21 points wins. Must win by 2.', 'basketball.fill'),
  ('FIFA Match', 'Esports', false, 'Standard FIFA rules. 12 minute halves.', 'gamecontroller.fill'),
  ('Pool', 'Sports', false, '8-ball rules. Sink the 8-ball last to win.', 'circle.fill'),
  ('Darts', 'Sports', false, '501 rules. First to reach exactly 0 wins.', 'target'),
  ('High Stakes Chess', 'Premium', true, 'Blitz chess. 5 minutes per side. No takebacks.', 'crown.fill'),
  ('Tournament Poker', 'Premium', true, 'Multi-table tournament rules. Last player standing wins.', 'star.fill');