-- ============================================
-- MAATRIVA SUBSCRIPTIONS TABLE
-- ============================================

-- Subscriptions Table
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    tier subscription_tier NOT NULL DEFAULT 'free', -- 'free', 'premium', 'family'
    status subscription_status NOT NULL DEFAULT 'active', -- 'active', 'canceled', 'expired', 'past_due'
    start_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_date TIMESTAMPTZ,
    stripe_subscription_id VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_subscription_times CHECK (end_date IS NULL OR start_date <= end_date)
);
