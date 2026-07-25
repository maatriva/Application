-- ============================================
-- MAATRIVA TELEMETRY (SENSOR DATA) TABLE
-- ============================================

-- Telemetry Table (base table for TimescaleDB hypertable conversion)
CREATE TABLE IF NOT EXISTS telemetry (
    timestamp TIMESTAMPTZ NOT NULL,
    device_id VARCHAR(100) NOT NULL REFERENCES devices(device_id) ON DELETE CASCADE,
    baby_id UUID REFERENCES babies(id) ON DELETE CASCADE,
    sensor_type VARCHAR(100) NOT NULL, -- e.g. 'heart_rate', 'breathing_rate', 'body_temperature', 'room_temperature', 'gas_detection', 'spo2'
    value NUMERIC NOT NULL,
    unit VARCHAR(50) NOT NULL,
    quality quality_level NOT NULL DEFAULT 'good',
    battery INTEGER,
    signal_strength INTEGER
);
