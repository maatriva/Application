-- ============================================
-- MAATRIVA TIMESCALEDB HYPERTABLES
-- ============================================

-- Convert telemetry table into a TimescaleDB hypertable partitioned by time (7 days chunk interval)
SELECT create_hypertable('telemetry', 'timestamp', chunk_time_interval => INTERVAL '7 days', if_not_exists => TRUE);

-- Create hypertable indexing
CREATE INDEX IF NOT EXISTS idx_telemetry_device_time ON telemetry (device_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_telemetry_baby_time ON telemetry (baby_id, timestamp DESC);
