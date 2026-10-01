-- ===========================================================================
-- OIKAD - Migration: Add school registration number
-- Αριθμός Μητρώου Σχολής
-- ===========================================================================
-- Run this in Supabase SQL Editor on existing databases.
-- setup_database.sql already contains this column for fresh installs.

ALTER TABLE dormitory_students
    ADD COLUMN IF NOT EXISTS school_registration_number VARCHAR(50);

CREATE INDEX IF NOT EXISTS idx_dormitory_students_school_reg
    ON dormitory_students(school_registration_number);

-- Backfill: keep existing rows valid (column is nullable, no backfill needed).
-- Names must be stored in capitals: normalize existing data.
UPDATE dormitory_students
SET
    name = UPPER(name),
    family_name = UPPER(family_name),
    father_name = UPPER(father_name),
    mother_name = UPPER(mother_name)
WHERE name IS NOT NULL OR family_name IS NOT NULL;
