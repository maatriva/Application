-- ============================================
-- MAATRIVA DATABASE VIEWS
-- ============================================

-- Daily Sleep Summary View
CREATE OR REPLACE VIEW v_daily_sleep_summary AS
SELECT 
    b.id AS baby_id,
    b.name AS baby_name,
    DATE(s.start_time) AS sleep_date,
    ROUND(SUM(EXTRACT(EPOCH FROM (COALESCE(s.end_time, NOW()) - s.start_time))/60)::NUMERIC, 2) AS total_sleep_minutes,
    ROUND(AVG(s.sleep_score), 1) AS avg_sleep_score
FROM babies b
JOIN sleep_sessions s ON s.baby_id = b.id
GROUP BY b.id, b.name, DATE(s.start_time);

-- Device Health Status View
CREATE OR REPLACE VIEW v_device_health_status AS
SELECT 
    d.device_id,
    d.device_name,
    d.type AS device_type,
    d.firmware_version,
    d.protocol,
    d.battery,
    d.status AS connection_status,
    d.last_seen,
    d.paired,
    da.baby_id,
    b.name AS baby_name
FROM devices d
LEFT JOIN device_assignments da ON da.device_id = d.device_id
LEFT JOIN babies b ON b.id = da.baby_id;

-- Telemetry Hourly Aggregates View (Hourly average, min, max)
CREATE OR REPLACE VIEW v_telemetry_hourly_aggregates AS
SELECT 
    date_trunc('hour', timestamp) AS hourly_timestamp,
    device_id,
    baby_id,
    sensor_type,
    ROUND(AVG(value)::NUMERIC, 2) AS avg_value,
    ROUND(MIN(value)::NUMERIC, 2) AS min_value,
    ROUND(MAX(value)::NUMERIC, 2) AS max_value,
    unit
FROM telemetry
GROUP BY date_trunc('hour', timestamp), device_id, baby_id, sensor_type, unit;
