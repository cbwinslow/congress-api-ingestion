-- GovInfo.gov SQLite Migration Script
-- Comprehensive schema for GovInfo.gov bulk data
-- Version: 1.0.0
-- Date: 2025-12-15

-- Enable SQLite extensions
PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA temp_store = MEMORY;
PRAGMA cache_size = -20000; -- 20MB cache

-- Collections table
CREATE TABLE IF NOT EXISTS collections (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    collection_code TEXT UNIQUE NOT NULL,
    collection_name TEXT NOT NULL,
    description TEXT,
    package_count INTEGER DEFAULT 0,
    last_updated TIMESTAMP,
    metadata TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Collections index
CREATE INDEX IF NOT EXISTS idx_collections_code ON collections(collection_code);
CREATE INDEX IF NOT EXISTS idx_collections_name ON collections(collection_name);

-- Packages table
CREATE TABLE IF NOT EXISTS packages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    package_id TEXT UNIQUE NOT NULL,
    collection_code TEXT NOT NULL,
    package_title TEXT NOT NULL,
    package_type TEXT,
    publication_date TIMESTAMP,
    last_modified TIMESTAMP,
    download_url TEXT,
    file_size INTEGER,
    file_format TEXT,
    checksum TEXT,
    metadata TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (collection_code) REFERENCES collections(collection_code) ON DELETE CASCADE
);

-- Packages index
CREATE INDEX IF NOT EXISTS idx_packages_collection ON packages(collection_code);
CREATE INDEX IF NOT EXISTS idx_packages_type ON packages(package_type);
CREATE INDEX IF NOT EXISTS idx_packages_date ON packages(publication_date);
CREATE INDEX IF NOT EXISTS idx_packages_format ON packages(file_format);

-- Granules table
CREATE TABLE IF NOT EXISTS granules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    granule_id TEXT UNIQUE NOT NULL,
    package_id TEXT NOT NULL,
    granule_title TEXT,
    granule_type TEXT,
    file_name TEXT,
    file_size INTEGER,
    file_format TEXT,
    download_url TEXT,
    checksum TEXT,
    metadata TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (package_id) REFERENCES packages(package_id) ON DELETE CASCADE
);

-- Granules index
CREATE INDEX IF NOT EXISTS idx_granules_package ON granules(package_id);
CREATE INDEX IF NOT EXISTS idx_granules_type ON granules(granule_type);
CREATE INDEX IF NOT EXISTS idx_granules_format ON granules(file_format);

-- Content files table
CREATE TABLE IF NOT EXISTS content_files (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    content_id TEXT UNIQUE NOT NULL,
    granule_id TEXT,
    file_name TEXT NOT NULL,
    file_path TEXT,
    file_size INTEGER,
    file_format TEXT,
    download_url TEXT,
    checksum TEXT,
    content_type TEXT,
    metadata TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (granule_id) REFERENCES granules(granule_id) ON DELETE CASCADE
);

-- Content files index
CREATE INDEX IF NOT EXISTS idx_content_granule ON content_files(granule_id);
CREATE INDEX IF NOT EXISTS idx_content_format ON content_files(file_format);
CREATE INDEX IF NOT EXISTS idx_content_type ON content_files(content_type);

-- Metadata table
CREATE TABLE IF NOT EXISTS metadata (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    metadata_id TEXT UNIQUE NOT NULL,
    package_id TEXT,
    metadata_type TEXT NOT NULL,
    metadata_content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (package_id) REFERENCES packages(package_id) ON DELETE CASCADE
);

-- Metadata index
CREATE INDEX IF NOT EXISTS idx_metadata_package ON metadata(package_id);
CREATE INDEX IF NOT EXISTS idx_metadata_type ON metadata(metadata_type);

-- Ingestion log table
CREATE TABLE IF NOT EXISTS ingestion_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ingestion_type TEXT NOT NULL,
    collection_code TEXT,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    records_processed INTEGER DEFAULT 0,
    records_success INTEGER DEFAULT 0,
    records_failed INTEGER DEFAULT 0,
    status TEXT DEFAULT 'running',
    error_message TEXT,
    metadata TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (collection_code) REFERENCES collections(collection_code) ON DELETE SET NULL
);

-- Ingestion log index
CREATE INDEX IF NOT EXISTS idx_ingestion_type ON ingestion_log(ingestion_type);
CREATE INDEX IF NOT EXISTS idx_ingestion_collection ON ingestion_log(collection_code);
CREATE INDEX IF NOT EXISTS idx_ingestion_status ON ingestion_log(status);
CREATE INDEX IF NOT EXISTS idx_ingestion_time ON ingestion_log(start_time);

-- Collection statistics table
CREATE TABLE IF NOT EXISTS collection_stats (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    collection_code TEXT UNIQUE NOT NULL,
    total_packages INTEGER DEFAULT 0,
    total_granules INTEGER DEFAULT 0,
    total_files INTEGER DEFAULT 0,
    total_size INTEGER DEFAULT 0,
    last_updated TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (collection_code) REFERENCES collections(collection_code) ON DELETE CASCADE
);

-- Collection statistics index
CREATE INDEX IF NOT EXISTS idx_stats_collection ON collection_stats(collection_code);

-- Package statistics table
CREATE TABLE IF NOT EXISTS package_stats (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    package_id TEXT UNIQUE NOT NULL,
    granule_count INTEGER DEFAULT 0,
    file_count INTEGER DEFAULT 0,
    total_size INTEGER DEFAULT 0,
    last_updated TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (package_id) REFERENCES packages(package_id) ON DELETE CASCADE
);

-- Package statistics index
CREATE INDEX IF NOT EXISTS idx_package_stats_id ON package_stats(package_id);

-- Schema version table
CREATE TABLE IF NOT EXISTS schema_versions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    version TEXT UNIQUE NOT NULL,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description TEXT
);

-- Insert schema version
INSERT INTO schema_versions (version, description)
VALUES ('1.0.0', 'Initial GovInfo.gov SQLite schema with comprehensive data model')
ON CONFLICT(version) DO NOTHING;

-- Create triggers for automatic timestamp updates
CREATE TRIGGER IF NOT EXISTS update_collections_timestamp
AFTER UPDATE ON collections
FOR EACH ROW
BEGIN
    UPDATE collections SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_packages_timestamp
AFTER UPDATE ON packages
FOR EACH ROW
BEGIN
    UPDATE packages SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_granules_timestamp
AFTER UPDATE ON granules
FOR EACH ROW
BEGIN
    UPDATE granules SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_content_timestamp
AFTER UPDATE ON content_files
FOR EACH ROW
BEGIN
    UPDATE content_files SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_metadata_timestamp
AFTER UPDATE ON metadata
FOR EACH ROW
BEGIN
    UPDATE metadata SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_ingestion_log_timestamp
AFTER UPDATE ON ingestion_log
FOR EACH ROW
BEGIN
    UPDATE ingestion_log SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_collection_stats_timestamp
AFTER UPDATE ON collection_stats
FOR EACH ROW
BEGIN
    UPDATE collection_stats SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_package_stats_timestamp
AFTER UPDATE ON package_stats
FOR EACH ROW
BEGIN
    UPDATE package_stats SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

-- Create views for common queries
CREATE VIEW IF NOT EXISTS collection_summary_view AS
SELECT 
    c.collection_code, 
    c.collection_name, 
    c.description, 
    cs.total_packages, 
    cs.total_granules, 
    cs.total_files, 
    cs.total_size, 
    cs.last_updated
FROM collections c
LEFT JOIN collection_stats cs ON c.collection_code = cs.collection_code
ORDER BY c.collection_name;

CREATE VIEW IF NOT EXISTS package_summary_view AS
SELECT 
    p.package_id, 
    p.collection_code, 
    c.collection_name, 
    p.package_title, 
    p.package_type, 
    p.publication_date, 
    ps.granule_count, 
    ps.file_count, 
    ps.total_size
FROM packages p
JOIN collections c ON p.collection_code = c.collection_code
LEFT JOIN package_stats ps ON p.package_id = ps.package_id
ORDER BY p.publication_date DESC;

-- Create indexes for views
CREATE INDEX IF NOT EXISTS idx_collection_summary_view_code ON collection_summary_view(collection_code);
CREATE INDEX IF NOT EXISTS idx_package_summary_view_package ON package_summary_view(package_id);

-- Migration complete
COMMENT ON DATABASE govinfo_api IS 'GovInfo.gov bulk data - SQLite Version 1.0.0';
