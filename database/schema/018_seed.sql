-- ============================================
-- MAATRIVA DATABASE SEED DATA
-- ============================================

-- Disable audit logging triggers temporarily during seeding to avoid noise in audit logs
ALTER TABLE users DISABLE TRIGGER tr_audit_users;
ALTER TABLE devices DISABLE TRIGGER tr_audit_devices;
ALTER TABLE device_assignments DISABLE TRIGGER tr_audit_device_assignments;
ALTER TABLE caregivers DISABLE TRIGGER tr_audit_caregivers;
ALTER TABLE subscriptions DISABLE TRIGGER tr_audit_subscriptions;

-- 1. Insert Users
INSERT INTO users (id, email, password_hash, role, first_name, last_name) VALUES
('a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'sarah@gmail.com', '$2a$10$T8Zq/7Wp4p1tK3C835X5x.9rZ2jD7U5YQ0uN0p5/3E/2uW3.P6GKG', 'parent', 'Sarah', 'Connor'),
('b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', 'john@gmail.com', '$2a$10$T8Zq/7Wp4p1tK3C835X5x.9rZ2jD7U5YQ0uN0p5/3E/2uW3.P6GKG', 'parent', 'John', 'Connor'),
('c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f', 'nanny@gmail.com', '$2a$10$tJ0rYyP5d1.vP/lEqE.RDO3qF.N51RmsH/q6W1XkE7D.V.l6z1Cae', 'caregiver', 'Mary', 'Poppins'),
('d4e5f6a7-b8c9-0d1e-2f3a-4b5c6d7e8f9a', 'doctor@maatriva.com', '$2a$10$tJ0rYyP5d1.vP/lEqE.RDO3qF.N51RmsH/q6W1XkE7D.V.l6z1Cae', 'doctor', 'Dr. Julius', 'Hibbert')
ON CONFLICT (id) DO NOTHING;

-- 2. Insert Babies
INSERT INTO babies (id, parent_id, name, birth_date, gender) VALUES
('f6a7b8c9-d0e1-2f3a-4b5c-6d7e8f9a0b1c', 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'Leo Connor', '2026-01-15', 'Male'),
('a7b8c9d0-e1f2-3a4b-5c6d-7e8f9a0b1c2d', 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', 'Liam Connor', '2026-03-22', 'Male')
ON CONFLICT (id) DO NOTHING;

-- 3. Insert Devices
INSERT INTO devices (device_id, device_name, type, firmware_version, protocol, battery, paired, last_seen, status) VALUES
('cradle_001', 'Leo Smart Cradle Hub', 'hub', '1.2.4', 'Wi-Fi', 98, TRUE, NOW() - INTERVAL '5 minutes', 'online'),
('sock_001', 'Leo Biometric Sock Sensor', 'sock', '1.0.8', 'BLE', 82, TRUE, NOW() - INTERVAL '4 minutes', 'online'),
('camera_001', 'Liam Smart Camera Monitor', 'camera', '2.0.1', 'Wi-Fi', 100, TRUE, NOW() - INTERVAL '10 minutes', 'online'),
('env_002', 'Liam Air Quality Monitor', 'environmental', '1.1.0', 'Wi-Fi', NULL, FALSE, NOW() - INTERVAL '1 hour', 'offline')
ON CONFLICT (device_id) DO NOTHING;

-- 4. Insert Device Assignments
INSERT INTO device_assignments (id, device_id, baby_id) VALUES
('11111111-2222-3333-4444-555555555555', 'cradle_001', 'f6a7b8c9-d0e1-2f3a-4b5c-6d7e8f9a0b1c'),
('22222222-3333-4444-5555-666666666666', 'sock_001', 'f6a7b8c9-d0e1-2f3a-4b5c-6d7e8f9a0b1c'),
('33333333-4444-5555-6666-777777777777', 'camera_001', 'a7b8c9d0-e1f2-3a4b-5c6d-7e8f9a0b1c2d')
ON CONFLICT (id) DO NOTHING;

-- 5. Insert Caregivers (Accepted and Pending invites)
INSERT INTO caregivers (id, baby_id, user_id, access_level, status, invited_by) VALUES
('88888888-8888-8888-8888-888888888888', 'f6a7b8c9-d0e1-2f3a-4b5c-6d7e8f9a0b1c', 'c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f', 'monitor', 'accepted', 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d'),
('99999999-9999-9999-9999-999999999999', 'a7b8c9d0-e1f2-3a4b-5c6d-7e8f9a0b1c2d', 'd4e5f6a7-b8c9-0d1e-2f3a-4b5c6d7e8f9a', 'view-only', 'pending', 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e')
ON CONFLICT (id) DO NOTHING;

-- 6. Insert Subscriptions
INSERT INTO subscriptions (id, user_id, tier, status, start_date, end_date, stripe_subscription_id) VALUES
('44444444-4444-4444-4444-444444444444', 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'premium', 'active', NOW() - INTERVAL '30 days', NOW() + INTERVAL '335 days', 'sub_1Oig294hfgbs82nf'),
('55555555-5555-5555-5555-555555555555', 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', 'free', 'active', NOW() - INTERVAL '10 days', NULL, NULL)
ON CONFLICT (id) DO NOTHING;

-- 7. Insert Sleep Sessions & Stages
INSERT INTO sleep_sessions (id, baby_id, start_time, end_time, sleep_score, notes) VALUES
('77777777-1111-1111-1111-111111111111', 'f6a7b8c9-d0e1-2f3a-4b5c-6d7e8f9a0b1c', NOW() - INTERVAL '12 hours', NOW() - INTERVAL '4 hours', 88, 'Slept soundly. Minimal waking events.'),
('77777777-2222-2222-2222-222222222222', 'a7b8c9d0-e1f2-3a4b-5c6d-7e8f9a0b1c2d', NOW() - INTERVAL '10 hours', NOW() - INTERVAL '2 hours', 72, 'Fussed slightly at 3:00 AM, but returned to sleep.')
ON CONFLICT (id) DO NOTHING;

INSERT INTO sleep_stages (id, session_id, start_time, end_time, stage) VALUES
(uuid_generate_v4(), '77777777-1111-1111-1111-111111111111', NOW() - INTERVAL '12 hours', NOW() - INTERVAL '11 hours', 'light'),
(uuid_generate_v4(), '77777777-1111-1111-1111-111111111111', NOW() - INTERVAL '11 hours', NOW() - INTERVAL '9 hours', 'deep'),
(uuid_generate_v4(), '77777777-1111-1111-1111-111111111111', NOW() - INTERVAL '9 hours', NOW() - INTERVAL '8 hours', 'rem'),
(uuid_generate_v4(), '77777777-1111-1111-1111-111111111111', NOW() - INTERVAL '8 hours', NOW() - INTERVAL '7.8 hours', 'awake'),
(uuid_generate_v4(), '77777777-1111-1111-1111-111111111111', NOW() - INTERVAL '7.8 hours', NOW() - INTERVAL '5 hours', 'deep'),
(uuid_generate_v4(), '77777777-1111-1111-1111-111111111111', NOW() - INTERVAL '5 hours', NOW() - INTERVAL '4 hours', 'light')
ON CONFLICT (id) DO NOTHING;

-- 8. Insert AI Reports
INSERT INTO ai_reports (id, baby_id, report_type, summary, key_findings, recommendations, start_date, end_date) VALUES
(uuid_generate_v4(), 'f6a7b8c9-d0e1-2f3a-4b5c-6d7e8f9a0b1c', 'daily', 
 'Leo had a highly restful sleep last night with steady vitals. Total sleep time was 8 hours.',
 '{"avg_heart_rate": 115, "avg_breath_rate": 28, "waking_count": 1}'::jsonb,
 'Leo is adapting well. Stick to the current 8 PM bedtime schedule as it aligns with his deep sleep window.',
 CURRENT_DATE - 1, CURRENT_DATE - 1)
ON CONFLICT (id) DO NOTHING;

-- 9. Insert Time-series Telemetry data (Last 2 hours of vitals)
INSERT INTO telemetry (timestamp, device_id, baby_id, sensor_type, value, unit, quality, battery, signal_strength) VALUES
-- Leo Sock Vitals (Heart Rate, Breathing, SpO2, Temp)
(NOW() - INTERVAL '1 hour', 'sock_001', 'f6a7b8c9-d0e1-2f3a-4b5c-6d7e8f9a0b1c', 'heart_rate', 112, 'BPM', 'good', 82, -45),
(NOW() - INTERVAL '50 minutes', 'sock_001', 'f6a7b8c9-d0e1-2f3a-4b5c-6d7e8f9a0b1c', 'heart_rate', 115, 'BPM', 'good', 82, -44),
(NOW() - INTERVAL '40 minutes', 'sock_001', 'f6a7b8c9-d0e1-2f3a-4b5c-6d7e8f9a0b1c', 'heart_rate', 108, 'BPM', 'good', 82, -45),
(NOW() - INTERVAL '30 minutes', 'sock_001', 'f6a7b8c9-d0e1-2f3a-4b5c-6d7e8f9a0b1c', 'heart_rate', 118, 'BPM', 'good', 81, -47),
(NOW() - INTERVAL '20 minutes', 'sock_001', 'f6a7b8c9-d0e1-2f3a-4b5c-6d7e8f9a0b1c', 'heart_rate', 114, 'BPM', 'good', 81, -46),
(NOW() - INTERVAL '10 minutes', 'sock_001', 'f6a7b8c9-d0e1-2f3a-4b5c-6d7e8f9a0b1c', 'heart_rate', 110, 'BPM', 'good', 81, -45),

(NOW() - INTERVAL '1 hour', 'sock_001', 'f6a7b8c9-d0e1-2f3a-4b5c-6d7e8f9a0b1c', 'breathing_rate', 28, 'brpm', 'good', 82, -45),
(NOW() - INTERVAL '40 minutes', 'sock_001', 'f6a7b8c9-d0e1-2f3a-4b5c-6d7e8f9a0b1c', 'breathing_rate', 30, 'brpm', 'good', 82, -45),
(NOW() - INTERVAL '20 minutes', 'sock_001', 'f6a7b8c9-d0e1-2f3a-4b5c-6d7e8f9a0b1c', 'breathing_rate', 26, 'brpm', 'good', 81, -46),

(NOW() - INTERVAL '1 hour', 'sock_001', 'f6a7b8c9-d0e1-2f3a-4b5c-6d7e8f9a0b1c', 'body_temperature', 36.8, '°C', 'good', 82, -45),
(NOW() - INTERVAL '30 minutes', 'sock_001', 'f6a7b8c9-d0e1-2f3a-4b5c-6d7e8f9a0b1c', 'body_temperature', 36.9, '°C', 'good', 81, -47),

(NOW() - INTERVAL '1 hour', 'sock_001', 'f6a7b8c9-d0e1-2f3a-4b5c-6d7e8f9a0b1c', 'spo2', 98, '%', 'good', 82, -45),
(NOW() - INTERVAL '30 minutes', 'sock_001', 'f6a7b8c9-d0e1-2f3a-4b5c-6d7e8f9a0b1c', 'spo2', 97, '%', 'good', 81, -47),

-- Room Environment (Cradle Hub Sensors)
(NOW() - INTERVAL '1 hour', 'cradle_001', 'f6a7b8c9-d0e1-2f3a-4b5c-6d7e8f9a0b1c', 'room_temperature', 21.5, '°C', 'good', 98, -32),
(NOW() - INTERVAL '30 minutes', 'cradle_001', 'f6a7b8c9-d0e1-2f3a-4b5c-6d7e8f9a0b1c', 'room_temperature', 21.8, '°C', 'good', 98, -33),
(NOW() - INTERVAL '1 hour', 'cradle_001', 'f6a7b8c9-d0e1-2f3a-4b5c-6d7e8f9a0b1c', 'gas_detection', 2.1, 'ppm', 'good', 98, -32),
(NOW() - INTERVAL '30 minutes', 'cradle_001', 'f6a7b8c9-d0e1-2f3a-4b5c-6d7e8f9a0b1c', 'gas_detection', 2.3, 'ppm', 'good', 98, -33);

-- 10. Insert Alerts
INSERT INTO alerts (id, device_id, baby_id, severity, type, message, value, threshold_limit, timestamp, acknowledged, acknowledged_by, acknowledged_at) VALUES
('73e8fa29-0129-438e-a9d2-7fb8aef82bcf', 'sock_001', 'f6a7b8c9-d0e1-2f3a-4b5c-6d7e8f9a0b1c', 'warning', 'fever_warning', 'Warning: Baby body temperature is elevated (37.9°C).', 37.9, 37.8, NOW() - INTERVAL '3 hours', TRUE, 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', NOW() - INTERVAL '2 hours 55 minutes'),
('73e8fa29-0129-438e-a9d2-7fb8aef82bc0', 'sock_001', 'f6a7b8c9-d0e1-2f3a-4b5c-6d7e8f9a0b1c', 'emergency', 'apnea_emergency', 'Emergency apnea warning: Respiration flatlined (0 breaths).', 0, 20.0, NOW() - INTERVAL '10 minutes', FALSE, NULL, NULL)
ON CONFLICT (id) DO NOTHING;

-- 11. Insert Notification History
INSERT INTO notification_history (id, user_id, alert_id, title, message, status, sent_at, retry_count) VALUES
(uuid_generate_v4(), 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', '73e8fa29-0129-438e-a9d2-7fb8aef82bcf', 'Fever Warning', 'Leo''s body temperature is slightly high: 37.9°C', 'sent', NOW() - INTERVAL '3 hours', 0),
(uuid_generate_v4(), 'c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f', '73e8fa29-0129-438e-a9d2-7fb8aef82bcf', 'Fever Warning', 'Leo''s body temperature is slightly high: 37.9°C', 'sent', NOW() - INTERVAL '3 hours', 0),
(uuid_generate_v4(), 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', '73e8fa29-0129-438e-a9d2-7fb8aef82bc0', 'APNEA EMERGENCY', 'Leo has stopped breathing. Please check the cradle immediately!', 'sent', NOW() - INTERVAL '10 minutes', 0)
ON CONFLICT (id) DO NOTHING;

-- Re-enable triggers
ALTER TABLE users ENABLE TRIGGER tr_audit_users;
ALTER TABLE devices ENABLE TRIGGER tr_audit_devices;
ALTER TABLE device_assignments ENABLE TRIGGER tr_audit_device_assignments;
ALTER TABLE caregivers ENABLE TRIGGER tr_audit_caregivers;
ALTER TABLE subscriptions ENABLE TRIGGER tr_audit_subscriptions;
