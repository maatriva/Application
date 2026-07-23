-- Drop the existing telemetry table
DROP TABLE IF EXISTS "telemetry" CASCADE;

-- Create the new telemetry table
CREATE TABLE "telemetry" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "device_id" VARCHAR(100) NOT NULL,
    "baby_id" UUID,
    "timestamp" TIMESTAMPTZ NOT NULL,
    "heart_rate" INTEGER,
    "respiration_rate" INTEGER,
    "body_temperature" DOUBLE PRECISION,
    "room_temperature" DOUBLE PRECISION,
    "humidity" DOUBLE PRECISION,
    "movement_detected" BOOLEAN,
    "cry_detected" BOOLEAN,
    "sleep_stage" VARCHAR(50),
    "air_quality" INTEGER,
    "battery_level" INTEGER,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "telemetry_pkey" PRIMARY KEY ("id", "timestamp")
);

-- Create indexes
CREATE INDEX "telemetry_device_id_timestamp_idx" ON "telemetry"("device_id", "timestamp" DESC);
CREATE INDEX "telemetry_baby_id_timestamp_idx" ON "telemetry"("baby_id", "timestamp" DESC);

-- Enable TimescaleDB extension and create hypertable if TimescaleDB exists
DO $$
BEGIN
    BEGIN
        CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'TimescaleDB extension not available on this server: %', SQLERRM;
    END;

    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'timescaledb') THEN
        PERFORM create_hypertable('telemetry', 'timestamp', if_not_exists => TRUE);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Failed to setup TimescaleDB hypertable, falling back to standard table: %', SQLERRM;
END $$;
