-- ============================================
-- MAATRIVA SLEEP SESSIONS & STAGES TABLES
-- ============================================

-- Sleep Sessions Table
CREATE TABLE IF NOT EXISTS sleep_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    baby_id UUID NOT NULL REFERENCES babies(id) ON DELETE CASCADE,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    sleep_score INTEGER CHECK (sleep_score >= 0 AND sleep_score <= 100),
    notes TEXT,
    CONSTRAINT chk_sleep_times CHECK (end_time IS NULL OR start_time <= end_time)
);

-- Sleep Stages Table
CREATE TABLE IF NOT EXISTS sleep_stages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES sleep_sessions(id) ON DELETE CASCADE,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    stage sleep_stage NOT NULL, -- 'awake', 'light', 'deep', 'rem'
    CONSTRAINT chk_stage_times CHECK (start_time <= end_time)
);
