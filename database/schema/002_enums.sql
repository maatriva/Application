-- ============================================
-- MAATRIVA DATABASE ENUMS
-- ============================================

-- User roles
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('parent', 'caregiver', 'doctor', 'admin');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Device types
DO $$ BEGIN
    CREATE TYPE device_type AS ENUM ('hub', 'sock', 'camera', 'environmental');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Device status
DO $$ BEGIN
    CREATE TYPE device_status AS ENUM ('online', 'offline', 'error');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Caregiver access level
DO $$ BEGIN
    CREATE TYPE access_level AS ENUM ('view-only', 'monitor', 'manage');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Caregiver invitation/request status
DO $$ BEGIN
    CREATE TYPE caregiver_status AS ENUM ('pending', 'accepted');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Sensor telemetry data quality
DO $$ BEGIN
    CREATE TYPE quality_level AS ENUM ('good', 'fair', 'poor', 'invalid');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Alert severity
DO $$ BEGIN
    CREATE TYPE alert_severity AS ENUM ('warning', 'danger', 'emergency');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Notification delivery status
DO $$ BEGIN
    CREATE TYPE notification_status AS ENUM ('sent', 'failed', 'retrying');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Subscription tier
DO $$ BEGIN
    CREATE TYPE subscription_tier AS ENUM ('free', 'premium', 'family');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Subscription billing status
DO $$ BEGIN
    CREATE TYPE subscription_status AS ENUM ('active', 'canceled', 'expired', 'past_due');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Sleep stage mapping
DO $$ BEGIN
    CREATE TYPE sleep_stage AS ENUM ('awake', 'light', 'deep', 'rem');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
