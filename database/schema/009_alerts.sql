-- ============================================
-- MAATRIVA ALERTS TABLE
-- ============================================

-- Alerts Table
CREATE TABLE IF NOT EXISTS alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id VARCHAR(100) NOT NULL REFERENCES devices(device_id) ON DELETE CASCADE,
    baby_id UUID REFERENCES babies(id) ON DELETE CASCADE,
    severity alert_severity NOT NULL, -- 'warning', 'danger', 'emergency'
    type VARCHAR(100) NOT NULL, -- 'high_fever', 'apnea', 'unsafe_posture', etc.
    message TEXT NOT NULL,
    value NUMERIC,
    threshold_limit NUMERIC,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    acknowledged BOOLEAN NOT NULL DEFAULT FALSE,
    acknowledged_by UUID REFERENCES users(id) ON DELETE SET NULL,
    acknowledged_at TIMESTAMPTZ
);
