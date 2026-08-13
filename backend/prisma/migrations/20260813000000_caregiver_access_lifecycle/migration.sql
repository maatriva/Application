-- The invitation lifetime is intentionally separate from the access lifetime.
ALTER TABLE "temporary_caregiver_permissions"
  ADD COLUMN "duration_minutes" INTEGER NOT NULL DEFAULT 30;

ALTER TABLE "temporary_caregiver_permissions"
  ADD CONSTRAINT "temporary_caregiver_permissions_duration_minutes_check"
  CHECK ("duration_minutes" BETWEEN 1 AND 10080);
