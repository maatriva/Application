-- Setup database schemas for MAATRIVA Smart Cradle ecosystem

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Users Table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'caregiver', -- 'parent', 'caregiver', 'doctor', 'admin'
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Babies Table
CREATE TABLE IF NOT EXISTS babies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    birth_date DATE NOT NULL,
    gender VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Devices Table (Registry)
CREATE TABLE IF NOT EXISTS devices (
    device_id VARCHAR(100) PRIMARY KEY,
    device_name VARCHAR(255) NOT NULL,
    type VARCHAR(100) NOT NULL, -- 'hub', 'sock', 'camera', 'environmental'
    firmware_version VARCHAR(50) NOT NULL,
    protocol VARCHAR(50) NOT NULL, -- 'BLE', 'Wi-Fi'
    battery INTEGER, -- 0-100, nullable
    paired BOOLEAN NOT NULL DEFAULT FALSE,
    last_seen TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status VARCHAR(50) NOT NULL DEFAULT 'offline' -- 'online', 'offline', 'error'
);

-- 4. Device Assignments
CREATE TABLE IF NOT EXISTS device_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id VARCHAR(100) NOT NULL REFERENCES devices(device_id) ON DELETE CASCADE,
    baby_id UUID NOT NULL REFERENCES babies(id) ON DELETE CASCADE,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(device_id, baby_id)
);

-- 5. Caregivers (Baby Access Mappings)
CREATE TABLE IF NOT EXISTS caregivers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    baby_id UUID NOT NULL REFERENCES babies(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    access_level VARCHAR(50) NOT NULL DEFAULT 'monitor', -- 'view-only', 'monitor', 'manage'
    status VARCHAR(50) NOT NULL DEFAULT 'pending', -- 'pending', 'accepted'
    invited_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(baby_id, user_id)
);

-- 6. Telemetry Table (Time-Series)
CREATE TABLE IF NOT EXISTS telemetry (
    timestamp TIMESTAMPTZ NOT NULL,
    device_id VARCHAR(100) NOT NULL,
    baby_id UUID,
    sensor_type VARCHAR(100) NOT NULL, -- 'heart_rate', 'breathing_rate', 'body_temperature', etc.
    value NUMERIC NOT NULL,
    unit VARCHAR(50) NOT NULL,
    quality VARCHAR(50) NOT NULL, -- 'good', 'fair', 'poor', 'invalid'
    battery INTEGER,
    signal_strength INTEGER
);

-- Convert telemetry table into a TimescaleDB hypertable partitioned by time (7 days chunk interval)
SELECT create_hypertable('telemetry', 'timestamp', chunk_time_interval => INTERVAL '7 days', if_not_exists => TRUE);

-- Create hypertable indexing
CREATE INDEX IF NOT EXISTS idx_telemetry_device_time ON telemetry (device_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_telemetry_baby_time ON telemetry (baby_id, timestamp DESC);

-- 7. Alerts Table
CREATE TABLE IF NOT EXISTS alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id VARCHAR(100) NOT NULL,
    baby_id UUID,
    severity VARCHAR(50) NOT NULL, -- 'warning', 'danger', 'emergency'
    type VARCHAR(100) NOT NULL, -- 'high_fever', 'apnea', 'unsafe_posture', etc.
    message TEXT NOT NULL,
    value NUMERIC,
    threshold_limit NUMERIC,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    acknowledged BOOLEAN NOT NULL DEFAULT FALSE,
    acknowledged_by UUID REFERENCES users(id),
    acknowledged_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_alerts_baby_ack ON alerts (baby_id, acknowledged);

-- 8. Notification History
CREATE TABLE IF NOT EXISTS notification_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    alert_id UUID REFERENCES alerts(id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'sent', -- 'sent', 'failed', 'retrying'
    sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    retry_count INTEGER NOT NULL DEFAULT 0
);

-- 9. Audit Logs
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(255) NOT NULL,
    target_table VARCHAR(100),
    target_id UUID,
    details TEXT,
    ip_address VARCHAR(45),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 10. Music Tracks Table
CREATE TABLE IF NOT EXISTS music_tracks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL DEFAULT 'Lullabies',
    language VARCHAR(100) NOT NULL DEFAULT 'English',
    duration INTEGER NOT NULL DEFAULT 0,
    file_size INTEGER NOT NULL DEFAULT 0,
    audio_format VARCHAR(20) NOT NULL DEFAULT 'mp3',
    bitrate INTEGER,
    artist VARCHAR(255) NOT NULL DEFAULT 'Maatriva Sound Studio',
    album VARCHAR(255),
    storage_url TEXT NOT NULL,
    file_hash VARCHAR(64),
    thumbnail TEXT,
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    uploaded_by UUID REFERENCES users(id) ON DELETE SET NULL,
    is_premium BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    play_count INTEGER NOT NULL DEFAULT 0,
    favourite_count INTEGER NOT NULL DEFAULT 0,
    target_age_group VARCHAR(100),
    tags TEXT[] DEFAULT ARRAY[]::TEXT[]
);

CREATE INDEX IF NOT EXISTS idx_music_category ON music_tracks(category);
CREATE INDEX IF NOT EXISTS idx_music_language ON music_tracks(language);
CREATE INDEX IF NOT EXISTS idx_music_file_hash ON music_tracks(file_hash);

-- 11. Music Batch Jobs Table
CREATE TABLE IF NOT EXISTS music_batch_jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    status VARCHAR(50) NOT NULL DEFAULT 'processing',
    total_files INTEGER NOT NULL,
    success_count INTEGER NOT NULL DEFAULT 0,
    failed_count INTEGER NOT NULL DEFAULT 0,
    details JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

