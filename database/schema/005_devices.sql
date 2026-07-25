-- ============================================
-- MAATRIVA DEVICES & ASSIGNMENTS TABLES
-- ============================================

-- Devices Table (Registry)
CREATE TABLE IF NOT EXISTS devices (
    device_id VARCHAR(100) PRIMARY KEY,
    device_name VARCHAR(255) NOT NULL,
    type device_type NOT NULL, -- 'hub', 'sock', 'camera', 'environmental'
    firmware_version VARCHAR(50) NOT NULL,
    protocol VARCHAR(50) NOT NULL, -- 'BLE', 'Wi-Fi'
    battery INTEGER, -- 0-100, nullable
    paired BOOLEAN NOT NULL DEFAULT FALSE,
    last_seen TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status device_status NOT NULL DEFAULT 'offline' -- 'online', 'offline', 'error'
);

-- Device Assignments
CREATE TABLE IF NOT EXISTS device_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id VARCHAR(100) NOT NULL REFERENCES devices(device_id) ON DELETE CASCADE,
    baby_id UUID NOT NULL REFERENCES babies(id) ON DELETE CASCADE,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(device_id, baby_id)
);
