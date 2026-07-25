-- ============================================
-- MAATRIVA NOTIFICATION HISTORY TABLE
-- ============================================

-- Notification History Table
CREATE TABLE IF NOT EXISTS notification_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    alert_id UUID REFERENCES alerts(id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    status notification_status NOT NULL DEFAULT 'sent', -- 'sent', 'failed', 'retrying'
    sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    retry_count INTEGER NOT NULL DEFAULT 0
);
