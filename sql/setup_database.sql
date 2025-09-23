-- ===========================================================================
-- OIKAD - Complete Supabase Database Setup
-- ===========================================================================
-- Dormitory Registration System Database Schema
--
-- This script sets up the complete OIKAD system database including:
-- • Student dormitory registration
-- • Document upload and management
-- • Authentication integration
-- • Row Level Security (RLS)
-- • Storage policies
--
-- Run this script in your Supabase SQL Editor
-- ===========================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ===========================================================================
-- 1. DORMITORY STUDENTS TABLE
-- ===========================================================================

-- Main table for dormitory student registrations
CREATE TABLE IF NOT EXISTS dormitory_students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Personal Information
    name VARCHAR(255) NOT NULL,
    family_name VARCHAR(255) NOT NULL,
    father_name VARCHAR(255),
    mother_name VARCHAR(255),
    birth_date DATE NOT NULL,
    birth_place VARCHAR(255),

    -- Identity Documents
    id_card_number VARCHAR(50) NOT NULL,
    issuing_authority VARCHAR(255),
    tax_number VARCHAR(50),

    -- Academic Information
    university VARCHAR(255),
    department VARCHAR(255),
    year_of_study VARCHAR(10),
    has_other_degree BOOLEAN DEFAULT false,

    -- Contact Information
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(50),

    -- Parent Information
    father_job VARCHAR(255),
    mother_job VARCHAR(255),
    parent_address TEXT,
    parent_city VARCHAR(255),
    parent_region VARCHAR(255),
    parent_postal VARCHAR(20),
    parent_country VARCHAR(255),
    parent_phone VARCHAR(50),

    -- Application Status
    application_status VARCHAR(50) DEFAULT 'draft'
        CHECK (application_status IN ('draft', 'submitted', 'under_review', 'approved', 'rejected', 'cancelled')),

    -- Consent & Legal
    terms_accepted BOOLEAN DEFAULT false,
    privacy_policy_accepted BOOLEAN DEFAULT false,
    data_processing_consent BOOLEAN DEFAULT false,
    consent_date TIMESTAMP WITH TIME ZONE,

    -- Authentication
    auth_user_id UUID,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================================================
-- 2. DOCUMENT CATEGORIES TABLE
-- ===========================================================================

-- Predefined document types for uploads
CREATE TABLE IF NOT EXISTS document_categories (
    id SERIAL PRIMARY KEY,
    category_key VARCHAR(50) UNIQUE NOT NULL,
    name_en VARCHAR(255) NOT NULL,
    name_el VARCHAR(255) NOT NULL,
    description_en TEXT,
    description_el TEXT,
    is_required BOOLEAN DEFAULT false,
    max_file_size_mb INTEGER DEFAULT 10,
    allowed_extensions TEXT[] DEFAULT ARRAY['jpg', 'jpeg', 'png', 'pdf'],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================================================
-- 3. STUDENT DOCUMENTS TABLE
-- ===========================================================================

-- Individual uploaded documents with metadata
CREATE TABLE IF NOT EXISTS student_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES dormitory_students(id) ON DELETE CASCADE,
    category_id INTEGER REFERENCES document_categories(id) ON DELETE RESTRICT,

    -- File Information
    file_name VARCHAR(255) NOT NULL,
    original_file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    file_type VARCHAR(50) NOT NULL,
    mime_type VARCHAR(100) NOT NULL,

    -- Upload Status
    upload_status VARCHAR(20) DEFAULT 'pending'
        CHECK (upload_status IN ('pending', 'uploaded', 'verified', 'rejected')),
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    verified_at TIMESTAMP WITH TIME ZONE,
    verified_by UUID,
    rejection_reason TEXT,

    -- File Processing
    compressed_size_bytes BIGINT DEFAULT 0,
    compression_ratio DECIMAL(5,2) DEFAULT 0.00,
    metadata JSONB DEFAULT '{}',

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================================================
-- 4. DOCUMENT SUBMISSIONS TABLE
-- ===========================================================================

-- Document submission sessions with consent tracking
CREATE TABLE IF NOT EXISTS document_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES dormitory_students(id) ON DELETE CASCADE,

    -- Submission Details
    submission_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    submission_status VARCHAR(20) DEFAULT 'draft'
        CHECK (submission_status IN ('draft', 'submitted', 'under_review', 'approved', 'rejected')),

    -- Consent Information
    consent_accepted BOOLEAN NOT NULL DEFAULT false,
    consent_text TEXT,
    consent_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Metadata
    selected_categories INTEGER[] DEFAULT ARRAY[]::INTEGER[],
    notes TEXT,
    submitted_by_ip INET,
    user_agent TEXT,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================================================
-- 5. INDEXES FOR PERFORMANCE
-- ===========================================================================

-- Dormitory Students Indexes
CREATE INDEX IF NOT EXISTS idx_dormitory_students_auth_user_id ON dormitory_students(auth_user_id);
CREATE INDEX IF NOT EXISTS idx_dormitory_students_email ON dormitory_students(email);
CREATE INDEX IF NOT EXISTS idx_dormitory_students_id_card ON dormitory_students(id_card_number);
CREATE INDEX IF NOT EXISTS idx_dormitory_students_application_status ON dormitory_students(application_status);
CREATE INDEX IF NOT EXISTS idx_dormitory_students_created_at ON dormitory_students(created_at);

-- Document System Indexes
CREATE INDEX IF NOT EXISTS idx_student_documents_student_id ON student_documents(student_id);
CREATE INDEX IF NOT EXISTS idx_student_documents_category_id ON student_documents(category_id);
CREATE INDEX IF NOT EXISTS idx_student_documents_upload_status ON student_documents(upload_status);
CREATE INDEX IF NOT EXISTS idx_student_documents_uploaded_at ON student_documents(uploaded_at);

CREATE INDEX IF NOT EXISTS idx_document_submissions_student_id ON document_submissions(student_id);
CREATE INDEX IF NOT EXISTS idx_document_submissions_submission_date ON document_submissions(submission_date);
CREATE INDEX IF NOT EXISTS idx_document_submissions_status ON document_submissions(submission_status);

-- Student Receipts Table
CREATE TABLE IF NOT EXISTS student_receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES dormitory_students(id) ON DELETE CASCADE,

    -- File Information
    file_name VARCHAR(255) NOT NULL,
    original_file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    file_type VARCHAR(50) NOT NULL,
    mime_type VARCHAR(100) NOT NULL,

    -- Receipt Information
    concerns_month SMALLINT CHECK (concerns_month >= 1 AND concerns_month <= 12),
    concerns_year INTEGER,

    -- Compression Information
    compressed_size_bytes BIGINT DEFAULT 0,
    compression_ratio NUMERIC DEFAULT 0.00,

    -- Metadata and Timestamps
    metadata JSONB DEFAULT '{}'::jsonb,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Student Receipts Indexes
CREATE INDEX IF NOT EXISTS idx_student_receipts_student_id ON student_receipts(student_id);
CREATE INDEX IF NOT EXISTS idx_student_receipts_concerns_year ON student_receipts(concerns_year);
CREATE INDEX IF NOT EXISTS idx_student_receipts_concerns_month ON student_receipts(concerns_month);
CREATE INDEX IF NOT EXISTS idx_student_receipts_uploaded_at ON student_receipts(uploaded_at);

-- ===========================================================================
-- 6. UNIQUE CONSTRAINTS
-- ===========================================================================

-- Prevent duplicate registrations
CREATE UNIQUE INDEX IF NOT EXISTS idx_dormitory_students_email_unique
    ON dormitory_students(email)
    WHERE application_status != 'cancelled';

CREATE UNIQUE INDEX IF NOT EXISTS idx_dormitory_students_id_card_unique
    ON dormitory_students(id_card_number)
    WHERE application_status != 'cancelled';

-- ===========================================================================
-- 7. TRIGGERS AND FUNCTIONS
-- ===========================================================================

-- Function to update the updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

-- Apply triggers to all tables with updated_at columns
CREATE TRIGGER update_dormitory_students_updated_at
    BEFORE UPDATE ON dormitory_students
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_document_categories_updated_at
    BEFORE UPDATE ON document_categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_student_documents_updated_at
    BEFORE UPDATE ON student_documents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_document_submissions_updated_at
    BEFORE UPDATE ON document_submissions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_student_receipts_updated_at
    BEFORE UPDATE ON student_receipts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ===========================================================================
-- 8. VIEWS FOR APPLICATION COMPATIBILITY
-- ===========================================================================

-- Compatibility view for document system (legacy 'students' table references)
CREATE OR REPLACE VIEW students AS
SELECT
    id,
    name,
    family_name,
    email,
    phone,
    birth_date,
    id_card_number,
    university,
    department,
    year_of_study,
    application_status,
    auth_user_id,
    created_at,
    updated_at
FROM dormitory_students;

-- Application summary view
CREATE OR REPLACE VIEW application_summary AS
SELECT
    d.id,
    d.name,
    d.family_name,
    d.email,
    d.university,
    d.department,
    d.application_status,
    d.created_at,
    COUNT(sd.id) as total_documents,
    COUNT(CASE WHEN sd.upload_status = 'uploaded' THEN 1 END) as uploaded_documents,
    COUNT(CASE WHEN sd.upload_status = 'verified' THEN 1 END) as verified_documents,
    MAX(ds.submission_date) as last_submission_date,
    BOOL_OR(ds.consent_accepted) as has_consent
FROM dormitory_students d
LEFT JOIN student_documents sd ON d.id = sd.student_id
LEFT JOIN document_submissions ds ON d.id = ds.student_id
GROUP BY d.id, d.name, d.family_name, d.email, d.university, d.department, d.application_status, d.created_at;

-- ===========================================================================
-- 9. ROW LEVEL SECURITY (RLS)
-- ===========================================================================

-- Enable RLS on all tables
ALTER TABLE dormitory_students ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_submissions ENABLE ROW LEVEL SECURITY;

-- ===========================================================================
-- 10. RLS POLICIES
-- ===========================================================================

-- Dormitory Students Policies
CREATE POLICY "Users can manage their own applications"
    ON dormitory_students FOR ALL
    TO authenticated
    USING (auth.uid() = auth_user_id)
    WITH CHECK (auth.uid() = auth_user_id);

CREATE POLICY "Allow anonymous access to dormitory applications"
    ON dormitory_students FOR ALL
    TO anon
    USING (true)
    WITH CHECK (true);

-- Document Categories Policies (Read-only for all)
CREATE POLICY "Allow all users to read document categories"
    ON document_categories FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Allow anonymous users to read document categories"
    ON document_categories FOR SELECT
    TO anon
    USING (true);

-- Student Documents Policies
CREATE POLICY "Users can manage their own documents"
    ON student_documents FOR ALL
    TO authenticated
    USING (auth.uid()::text = (SELECT auth_user_id::text FROM dormitory_students WHERE id = student_id))
    WITH CHECK (auth.uid()::text = (SELECT auth_user_id::text FROM dormitory_students WHERE id = student_id));

CREATE POLICY "Allow anonymous document access"
    ON student_documents FOR ALL
    TO anon
    USING (true)
    WITH CHECK (true);

-- Document Submissions Policies
CREATE POLICY "Users can manage their own submissions"
    ON document_submissions FOR ALL
    TO authenticated
    USING (auth.uid()::text = (SELECT auth_user_id::text FROM dormitory_students WHERE id = student_id))
    WITH CHECK (auth.uid()::text = (SELECT auth_user_id::text FROM dormitory_students WHERE id = student_id));

CREATE POLICY "Allow anonymous submission access"
    ON document_submissions FOR ALL
    TO anon
    USING (true)
    WITH CHECK (true);

-- ===========================================================================
-- 11. PERMISSIONS
-- ===========================================================================

-- Grant permissions for authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON dormitory_students TO authenticated;
GRANT SELECT ON document_categories TO authenticated;
GRANT ALL ON student_documents TO authenticated;
GRANT ALL ON document_submissions TO authenticated;
GRANT SELECT ON students TO authenticated;
GRANT SELECT ON application_summary TO authenticated;

-- Grant permissions for anonymous users
GRANT USAGE ON SCHEMA public TO anon;
GRANT ALL ON dormitory_students TO anon;
GRANT SELECT ON document_categories TO anon;
GRANT ALL ON student_documents TO anon;
GRANT ALL ON document_submissions TO anon;
GRANT SELECT ON students TO anon;
GRANT SELECT ON application_summary TO anon;

-- Grant sequence permissions
GRANT USAGE, SELECT ON SEQUENCE document_categories_id_seq TO authenticated, anon;

-- ===========================================================================
-- 12. PREDEFINED DATA
-- ===========================================================================

-- Insert document categories
INSERT INTO document_categories (category_key, name_en, name_el, description_en, description_el, is_required, max_file_size_mb) VALUES
('student_photo', 'Student Photo', 'Φωτογραφία Φοιτητή', 'Recent passport-style photograph', 'Πρόσφατη φωτογραφία τύπου διαβατηρίου', true, 5),
('id_front', 'ID Card (Front)', 'Ταυτότητα (Μπροστά)', 'Front side of ID card', 'Μπροστινή όψη ταυτότητας', false, 5),
('id_back', 'ID Card (Back)', 'Ταυτότητα (Πίσω)', 'Back side of ID card', 'Πίσω όψη ταυτότητας', false, 5),
('passport', 'Passport', 'Διαβατήριο', 'Passport document', 'Έγγραφο διαβατηρίου', false, 5),
('medical_certificate', 'Medical Certificate', 'Ιατρικό Πιστοποιητικό', 'Medical certificate from authorized physician', 'Ιατρικό πιστοποιητικό από εξουσιοδοτημένο γιατρό', true, 10)
ON CONFLICT (category_key) DO NOTHING;

-- ===========================================================================
-- 13. STORAGE BUCKET SETUP (for file uploads)
-- ===========================================================================

-- Create storage bucket for student documents
INSERT INTO storage.buckets (id, name, public)
VALUES ('student-documents', 'student-documents', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for student documents
CREATE POLICY "Allow authenticated users to upload documents"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'student-documents');

CREATE POLICY "Allow anonymous users to upload documents"
    ON storage.objects FOR INSERT
    TO anon
    WITH CHECK (bucket_id = 'student-documents');

CREATE POLICY "Allow all users to read documents"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'student-documents');

-- ===========================================================================
-- 14. COMMENTS FOR DOCUMENTATION
-- ===========================================================================

COMMENT ON TABLE dormitory_students IS 'Main table for dormitory student registration applications';
COMMENT ON COLUMN dormitory_students.auth_user_id IS 'UUID of the authenticated user from Supabase Auth';
COMMENT ON COLUMN dormitory_students.application_status IS 'Current status of the dormitory application';
COMMENT ON COLUMN dormitory_students.consent_date IS 'Date when user gave consent for data processing';

COMMENT ON TABLE document_categories IS 'Predefined categories for document uploads';
COMMENT ON TABLE student_documents IS 'Individual uploaded files with metadata';
COMMENT ON TABLE document_submissions IS 'Document submission sessions with consent tracking';

COMMENT ON VIEW students IS 'Compatibility view for legacy code referencing students table';
COMMENT ON VIEW application_summary IS 'Summary view of applications with document counts';

-- ===========================================================================
-- 15. SETUP COMPLETE
-- ===========================================================================

-- Display success message
DO $$
BEGIN
    RAISE NOTICE '==========================================================';
    RAISE NOTICE 'OIKAD Database Setup Completed Successfully!';
    RAISE NOTICE '==========================================================';
    RAISE NOTICE 'Tables Created:';
    RAISE NOTICE '• dormitory_students (main registration table)';
    RAISE NOTICE '• document_categories (document types)';
    RAISE NOTICE '• student_documents (uploaded files)';
    RAISE NOTICE '• document_submissions (submission tracking)';
    RAISE NOTICE '';
    RAISE NOTICE 'Views Created:';
    RAISE NOTICE '• students (compatibility view)';
    RAISE NOTICE '• application_summary (dashboard data)';
    RAISE NOTICE '';
    RAISE NOTICE 'Security:';
    RAISE NOTICE '• Row Level Security (RLS) enabled';
    RAISE NOTICE '• Policies configured for authenticated & anonymous users';
    RAISE NOTICE '• Storage bucket "student-documents" created';
    RAISE NOTICE '';
    RAISE NOTICE 'Next Steps:';
    RAISE NOTICE '1. Configure your Flutter app with Supabase URL and Anon Key';
    RAISE NOTICE '2. Test authentication and document upload features';
    RAISE NOTICE '3. Customize document categories if needed';
    RAISE NOTICE '==========================================================';
END $$;
