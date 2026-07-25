-- ============================================
-- MAATRIVA DATABASE INDEXES (RELATIONAL)
-- ============================================

-- Indexes for Users
CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);

-- Indexes for Babies
CREATE INDEX IF NOT EXISTS idx_babies_parent_id ON babies (parent_id);

-- Indexes for Device Assignments
CREATE INDEX IF NOT EXISTS idx_device_assignments_baby_id ON device_assignments (baby_id);
CREATE INDEX IF NOT EXISTS idx_device_assignments_device_id ON device_assignments (device_id);

-- Indexes for Caregivers
CREATE INDEX IF NOT EXISTS idx_caregivers_baby_id ON caregivers (baby_id);
CREATE INDEX IF NOT EXISTS idx_caregivers_user_id ON caregivers (user_id);
CREATE INDEX IF NOT EXISTS idx_caregivers_baby_user ON caregivers (baby_id, user_id);

-- Indexes for Alerts
CREATE INDEX IF NOT EXISTS idx_alerts_baby_ack ON alerts (baby_id, acknowledged);
CREATE INDEX IF NOT EXISTS idx_alerts_device_timestamp ON alerts (device_id, timestamp DESC);

-- Indexes for Notifications
CREATE INDEX IF NOT EXISTS idx_notifications_user_sent ON notification_history (user_id, sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_alert_id ON notification_history (alert_id);

-- Indexes for Sleep
CREATE INDEX IF NOT EXISTS idx_sleep_sessions_baby_time ON sleep_sessions (baby_id, start_time DESC);
CREATE INDEX IF NOT EXISTS idx_sleep_stages_session ON sleep_stages (session_id);

-- Indexes for Subscriptions
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_status ON subscriptions (user_id, status);

-- Indexes for Audit Logs
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_time ON audit_logs (user_id, timestamp DESC);
