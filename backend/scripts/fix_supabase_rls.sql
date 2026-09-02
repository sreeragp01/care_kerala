-- ====================================================================================
-- Supabase Database Security & RLS Remediation Script
-- Fixes:
--   1. rls_disabled_in_public (0013_rls_disabled_in_public)
--   2. sensitive_columns_exposed (0023_sensitive_columns_exposed)
--
-- Note for Django + Flutter Architecture:
-- Django connects as the PostgreSQL database owner/superuser (e.g. postgres), which
-- BYPASSES RLS by default. Enabling RLS and revoking API permissions blocks unauthenticated
-- access via Supabase's PostgREST API without affecting Django backend operations.
-- ====================================================================================

-- Step 1: Enable Row Level Security (RLS) on all existing tables in public schema
DO $$
DECLARE
    tbl record;
BEGIN
    FOR tbl IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public'
    LOOP
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;', tbl.tablename);
        RAISE NOTICE 'Enabled RLS on: public.%', tbl.tablename;
    END LOOP;
END $$;

-- Step 2: Revoke PostgREST direct access for public/anonymous Supabase roles
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon, authenticated;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM anon, authenticated;
REVOKE ALL ON ALL ROUTINES IN SCHEMA public FROM anon, authenticated;

-- Step 3: Prevent future tables/migrations from granting access to anon/authenticated roles
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON SEQUENCES FROM anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON ROUTINES FROM anon, authenticated;

-- Verification Query: Check that all public tables now have RLS enabled (rowsecurity = true)
SELECT 
    schemaname, 
    tablename, 
    rowsecurity AS rls_enabled
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;
