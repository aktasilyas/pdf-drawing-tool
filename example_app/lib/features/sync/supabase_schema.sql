-- =====================================================
-- ElyaNotes Sync Feature - Supabase Database Schema
-- =====================================================
-- Author: Agent-C
-- Date: 2026-01-22
-- Version: 1.0
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- Documents Table
-- =====================================================
CREATE TABLE IF NOT EXISTS documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  folder_id UUID REFERENCES folders(id) ON DELETE SET NULL,
  template_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  thumbnail_path TEXT,
  page_count INTEGER NOT NULL DEFAULT 1,
  is_favorite BOOLEAN NOT NULL DEFAULT FALSE,
  is_in_trash BOOLEAN NOT NULL DEFAULT FALSE,
  content BYTEA,
  
  -- Indexes
  CONSTRAINT documents_page_count_positive CHECK (page_count > 0)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_documents_user_id ON documents(user_id);
CREATE INDEX IF NOT EXISTS idx_documents_folder_id ON documents(folder_id);
CREATE INDEX IF NOT EXISTS idx_documents_updated_at ON documents(updated_at);
CREATE INDEX IF NOT EXISTS idx_documents_is_favorite ON documents(user_id, is_favorite) WHERE is_favorite = TRUE;
CREATE INDEX IF NOT EXISTS idx_documents_is_in_trash ON documents(user_id, is_in_trash) WHERE is_in_trash = TRUE;

-- Updated at trigger
CREATE OR REPLACE FUNCTION update_documents_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER documents_updated_at
  BEFORE UPDATE ON documents
  FOR EACH ROW
  EXECUTE FUNCTION update_documents_updated_at();

-- =====================================================
-- Folders Table
-- =====================================================
CREATE TABLE IF NOT EXISTS folders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  parent_id UUID REFERENCES folders(id) ON DELETE CASCADE,
  color_value INTEGER NOT NULL DEFAULT 4280391411, -- 0xFF2196F3
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Prevent circular references
  CONSTRAINT folders_no_self_parent CHECK (id != parent_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_folders_user_id ON folders(user_id);
CREATE INDEX IF NOT EXISTS idx_folders_parent_id ON folders(parent_id);

-- =====================================================
-- Sync Metadata Table
-- =====================================================
CREATE TABLE IF NOT EXISTS sync_metadata (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  last_sync_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for performance
CREATE INDEX IF NOT EXISTS idx_sync_metadata_last_sync_at ON sync_metadata(last_sync_at);

-- =====================================================
-- Row Level Security (RLS) Policies
-- =====================================================

-- Enable RLS
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE folders ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_metadata ENABLE ROW LEVEL SECURITY;

-- Documents policies
DROP POLICY IF EXISTS "Users can view own documents" ON documents;
CREATE POLICY "Users can view own documents" 
  ON documents FOR SELECT 
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own documents" ON documents;
CREATE POLICY "Users can insert own documents" 
  ON documents FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own documents" ON documents;
CREATE POLICY "Users can update own documents" 
  ON documents FOR UPDATE 
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own documents" ON documents;
CREATE POLICY "Users can delete own documents" 
  ON documents FOR DELETE 
  USING (auth.uid() = user_id);

-- Folders policies
DROP POLICY IF EXISTS "Users can view own folders" ON folders;
CREATE POLICY "Users can view own folders" 
  ON folders FOR SELECT 
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own folders" ON folders;
CREATE POLICY "Users can insert own folders" 
  ON folders FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own folders" ON folders;
CREATE POLICY "Users can update own folders" 
  ON folders FOR UPDATE 
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own folders" ON folders;
CREATE POLICY "Users can delete own folders" 
  ON folders FOR DELETE 
  USING (auth.uid() = user_id);

-- Sync metadata policies
DROP POLICY IF EXISTS "Users can view own sync metadata" ON sync_metadata;
CREATE POLICY "Users can view own sync metadata" 
  ON sync_metadata FOR SELECT 
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can upsert own sync metadata" ON sync_metadata;
CREATE POLICY "Users can upsert own sync metadata" 
  ON sync_metadata FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own sync metadata" ON sync_metadata;
CREATE POLICY "Users can update own sync metadata" 
  ON sync_metadata FOR UPDATE 
  USING (auth.uid() = user_id);

-- =====================================================
-- Helper Functions
-- =====================================================

-- Function to get documents modified after a specific date
CREATE OR REPLACE FUNCTION get_documents_modified_after(
  since_date TIMESTAMPTZ
)
RETURNS SETOF documents AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM documents
  WHERE user_id = auth.uid()
    AND updated_at > since_date
  ORDER BY updated_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get folders modified after a specific date
CREATE OR REPLACE FUNCTION get_folders_modified_after(
  since_date TIMESTAMPTZ
)
RETURNS SETOF folders AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM folders
  WHERE user_id = auth.uid()
    AND created_at > since_date
  ORDER BY created_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update last sync timestamp
CREATE OR REPLACE FUNCTION update_last_sync_timestamp()
RETURNS void AS $$
BEGIN
  INSERT INTO sync_metadata (user_id, last_sync_at)
  VALUES (auth.uid(), NOW())
  ON CONFLICT (user_id)
  DO UPDATE SET last_sync_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Sample Data (for testing only - remove in production)
-- =====================================================

-- Insert sample folders for testing
-- INSERT INTO folders (id, user_id, name, color_value)
-- VALUES 
--   ('00000000-0000-0000-0000-000000000001', auth.uid(), 'Work', 4283215696),
--   ('00000000-0000-0000-0000-000000000002', auth.uid(), 'Personal', 4287137928);

-- Insert sample documents for testing
-- INSERT INTO documents (id, user_id, title, template_id, folder_id)
-- VALUES 
--   ('00000000-0000-0000-0000-000000000101', auth.uid(), 'Meeting Notes', 'blank', '00000000-0000-0000-0000-000000000001'),
--   ('00000000-0000-0000-0000-000000000102', auth.uid(), 'Shopping List', 'thin_lined', '00000000-0000-0000-0000-000000000002');

-- =====================================================
-- Grants
-- =====================================================

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION get_documents_modified_after(TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION get_folders_modified_after(TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION update_last_sync_timestamp() TO authenticated;

-- =====================================================
-- Cleanup (if needed)
-- =====================================================

-- To drop all tables (USE WITH CAUTION):
-- DROP TABLE IF EXISTS documents CASCADE;
-- DROP TABLE IF EXISTS folders CASCADE;
-- DROP TABLE IF EXISTS sync_metadata CASCADE;
-- DROP FUNCTION IF EXISTS update_documents_updated_at() CASCADE;
-- DROP FUNCTION IF EXISTS get_documents_modified_after(TIMESTAMPTZ) CASCADE;
-- DROP FUNCTION IF EXISTS get_folders_modified_after(TIMESTAMPTZ) CASCADE;
-- DROP FUNCTION IF EXISTS update_last_sync_timestamp() CASCADE;

-- =====================================================
-- End of Schema
-- =====================================================
