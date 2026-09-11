-- CreateTable
CREATE TABLE "temporary_caregiver_permissions" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "parent_id" UUID NOT NULL,
    "caregiver_id" UUID,
    "baby_id" UUID NOT NULL,
    "invitation_token" VARCHAR(255),
    "invitation_token_hash" VARCHAR(255),
    "invitation_expires_at" TIMESTAMPTZ,
    "permission" VARCHAR(50) NOT NULL DEFAULT 'LIVE_MONITOR_ONLY',
    "permissions" JSONB DEFAULT '{}',
    "duration_minutes" INTEGER NOT NULL DEFAULT 30,
    "granted_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expires_at" TIMESTAMPTZ NOT NULL,
    "accepted_at" TIMESTAMPTZ,
    "revoked_at" TIMESTAMPTZ,
    "revoked_by" UUID,
    "status" VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    "revoked" BOOLEAN NOT NULL DEFAULT false,
    "can_view_live_monitoring" BOOLEAN NOT NULL DEFAULT true,
    "can_view_camera" BOOLEAN NOT NULL DEFAULT false,
    "can_receive_alerts" BOOLEAN NOT NULL DEFAULT false,
    "can_view_telemetry" BOOLEAN NOT NULL DEFAULT false,
    "can_view_custom_lullabies" BOOLEAN NOT NULL DEFAULT false,
    "can_play_music" BOOLEAN NOT NULL DEFAULT false,
    "can_control_cradle" BOOLEAN NOT NULL DEFAULT false,
    "can_view_health_history" BOOLEAN NOT NULL DEFAULT false,
    "can_use_ai" BOOLEAN NOT NULL DEFAULT false,
    "last_active_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "temporary_caregiver_permissions_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "temporary_caregiver_permissions_duration_minutes_check"
        CHECK ("duration_minutes" BETWEEN 1 AND 10080)
);

-- CreateIndex
CREATE UNIQUE INDEX "temporary_caregiver_permissions_invitation_token_key"
ON "temporary_caregiver_permissions"("invitation_token");

CREATE INDEX "temporary_caregiver_permissions_caregiver_id_baby_id_status_revoked_expires_at_idx"
ON "temporary_caregiver_permissions"("caregiver_id", "baby_id", "status", "revoked", "expires_at");

CREATE INDEX "temporary_caregiver_permissions_invitation_token_idx"
ON "temporary_caregiver_permissions"("invitation_token");

CREATE INDEX "temporary_caregiver_permissions_invitation_token_hash_idx"
ON "temporary_caregiver_permissions"("invitation_token_hash");

-- AddForeignKey
ALTER TABLE "temporary_caregiver_permissions"
ADD CONSTRAINT "temporary_caregiver_permissions_parent_id_fkey"
FOREIGN KEY ("parent_id") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "temporary_caregiver_permissions"
ADD CONSTRAINT "temporary_caregiver_permissions_caregiver_id_fkey"
FOREIGN KEY ("caregiver_id") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "temporary_caregiver_permissions"
ADD CONSTRAINT "temporary_caregiver_permissions_baby_id_fkey"
FOREIGN KEY ("baby_id") REFERENCES "babies"("id")
ON DELETE CASCADE ON UPDATE CASCADE;