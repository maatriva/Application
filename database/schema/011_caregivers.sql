-- ============================================
-- MAATRIVA CAREGIVERS TABLE
-- ============================================

-- Caregivers (Baby Access Mappings)
CREATE TABLE IF NOT EXISTS caregivers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    baby_id UUID NOT NULL REFERENCES babies(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    access_level access_level NOT NULL DEFAULT 'monitor', -- 'view-only', 'monitor', 'manage'
    status caregiver_status NOT NULL DEFAULT 'pending', -- 'pending', 'accepted'
    invited_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(baby_id, user_id)
);
