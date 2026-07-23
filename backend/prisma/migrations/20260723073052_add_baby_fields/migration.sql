/*
  Warnings:

  - You are about to drop the column `first_name` on the `users` table. All the data in the column will be lost.
  - You are about to drop the column `last_name` on the `users` table. All the data in the column will be lost.
  - Added the required column `full_name` to the `users` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "babies" ADD COLUMN     "birth_height" DOUBLE PRECISION,
ADD COLUMN     "birth_weight" DOUBLE PRECISION,
ADD COLUMN     "blood_group" TEXT,
ADD COLUMN     "deleted_at" TIMESTAMPTZ,
ADD COLUMN     "photo_url" TEXT;

-- AlterTable
ALTER TABLE "users" DROP COLUMN "first_name",
DROP COLUMN "last_name",
ADD COLUMN     "full_name" TEXT NOT NULL,
ALTER COLUMN "role" SET DEFAULT 'PARENT';
