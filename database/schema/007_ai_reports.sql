-- ============================================
-- MAATRIVA AI REPORTS TABLE
-- ============================================

-- AI Reports Table
CREATE TABLE IF NOT EXISTS ai_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    baby_id UUID NOT NULL REFERENCES babies(id) ON DELETE CASCADE,
    report_type VARCHAR(50) NOT NULL CONSTRAINT chk_report_type CHECK (report_type IN ('daily', 'weekly', 'monthly')),
    summary TEXT NOT NULL,
    key_findings JSONB NOT NULL DEFAULT '{}'::jsonb,
    recommendations TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_date_range CHECK (start_date <= end_date)
);
