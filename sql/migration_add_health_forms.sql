-- ===========================================================================
-- OIKAD - Migration: Student health questionnaire (stoixia.docx)
-- Ηλεκτρονική φόρμα υγειονομικών στοιχείων
-- ===========================================================================
-- Run this in Supabase SQL Editor on existing databases.
-- Fresh installs: setup_database.sql already includes this table
-- (see section 16); running this file again is safe (IF NOT EXISTS).

CREATE TABLE IF NOT EXISTS student_health_forms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID UNIQUE NOT NULL REFERENCES dormitory_students(id) ON DELETE CASCADE,

    -- Προσωπικά (προσυμπληρώνονται από την αίτηση, αλλά φυλάσσονται κι εδώ)
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    father_name VARCHAR(255),
    mother_name VARCHAR(255),
    birth_date DATE,
    blood_type VARCHAR(10),

    -- Ιστορικό
    recent_surgeries TEXT,

    -- Εμβόλια
    hepatitis_covered BOOLEAN,
    hepatitis_date DATE,
    tetanus_covered BOOLEAN,
    tetanus_date DATE,
    meningitis_covered BOOLEAN,
    meningitis_date DATE,

    -- Ασθένειες / αγωγή / δίαιτα
    serious_illness BOOLEAN,
    serious_illness_details TEXT,
    medication TEXT,
    special_diet BOOLEAN,
    special_diet_details TEXT,

    -- Παθήσεις (λίστα επιλογών + ελεύθερο κείμενο)
    conditions TEXT[] DEFAULT ARRAY[]::TEXT[],
    conditions_details TEXT,
    other_observations TEXT,

    -- Συναίνεση
    consent_accepted BOOLEAN DEFAULT false,
    consent_date TIMESTAMP WITH TIME ZONE,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_student_health_forms_student_id
    ON student_health_forms(student_id);

DROP TRIGGER IF EXISTS update_student_health_forms_updated_at ON student_health_forms;
CREATE TRIGGER update_student_health_forms_updated_at
    BEFORE UPDATE ON student_health_forms
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

ALTER TABLE student_health_forms ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own health forms" ON student_health_forms;
CREATE POLICY "Users can manage their own health forms"
    ON student_health_forms FOR ALL
    TO authenticated
    USING (auth.uid()::text = (SELECT auth_user_id::text FROM dormitory_students WHERE id = student_id))
    WITH CHECK (auth.uid()::text = (SELECT auth_user_id::text FROM dormitory_students WHERE id = student_id));

DROP POLICY IF EXISTS "Allow anonymous health form access" ON student_health_forms;
CREATE POLICY "Allow anonymous health form access"
    ON student_health_forms FOR ALL
    TO anon
    USING (true)
    WITH CHECK (true);

GRANT ALL ON student_health_forms TO authenticated;
GRANT ALL ON student_health_forms TO anon;

COMMENT ON TABLE student_health_forms IS 'Ηλεκτρονική φόρμα υγειονομικών στοιχείων (stoixia.docx)';
