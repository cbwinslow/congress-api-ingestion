-- GovInfo.gov PostgreSQL Migration Script
-- Comprehensive schema for GovInfo.gov bulk data
-- Version: 1.0.0
-- Date: 2025-12-15

-- Enable extensions for enhanced functionality
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- Create schema for GovInfo.gov data
CREATE SCHEMA IF NOT EXISTS govinfo_gov;

-- Set search path
SET search_path TO govinfo_gov, public;

-- Collections table
CREATE TABLE IF NOT EXISTS govinfo_gov.collections (
    id SERIAL PRIMARY KEY,
    collection_code VARCHAR(50) UNIQUE NOT NULL,
    collection_name TEXT NOT NULL,
    description TEXT,
    package_count INTEGER DEFAULT 0,
    last_updated TIMESTAMP,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Collections index
CREATE INDEX IF NOT EXISTS idx_collections_code ON govinfo_gov.collections(collection_code);
CREATE INDEX IF NOT EXISTS idx_collections_name ON govinfo_gov.collections(collection_name);

-- Packages table
CREATE TABLE IF NOT EXISTS govinfo_gov.packages (
    id SERIAL PRIMARY KEY,
    package_id VARCHAR(100) UNIQUE NOT NULL,
    collection_code VARCHAR(50) NOT NULL,
    package_title TEXT NOT NULL,
    package_type VARCHAR(50),
    publication_date TIMESTAMP,
    last_modified TIMESTAMP,
    download_url VARCHAR(255),
    file_size BIGINT,
    file_format VARCHAR(20),
    checksum VARCHAR(100),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (collection_code) REFERENCES govinfo_gov.collections(collection_code) ON DELETE CASCADE
);

-- Packages index
CREATE INDEX IF NOT EXISTS idx_packages_collection ON govinfo_gov.packages(collection_code);
CREATE INDEX IF NOT EXISTS idx_packages_type ON govinfo_gov.packages(package_type);
CREATE INDEX IF NOT EXISTS idx_packages_date ON govinfo_gov.packages(publication_date);
CREATE INDEX IF NOT EXISTS idx_packages_format ON govinfo_gov.packages(file_format);

-- Granules table
CREATE TABLE IF NOT EXISTS govinfo_gov.granules (
    id SERIAL PRIMARY KEY,
    granule_id VARCHAR(100) UNIQUE NOT NULL,
    package_id VARCHAR(100) NOT NULL,
    granule_title TEXT,
    granule_type VARCHAR(50),
    file_name VARCHAR(255),
    file_size BIGINT,
    file_format VARCHAR(20),
    download_url VARCHAR(255),
    checksum VARCHAR(100),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (package_id) REFERENCES govinfo_gov.packages(package_id) ON DELETE CASCADE
);

-- Granules index
CREATE INDEX IF NOT EXISTS idx_granules_package ON govinfo_gov.granules(package_id);
CREATE INDEX IF NOT EXISTS idx_granules_type ON govinfo_gov.granules(granule_type);
CREATE INDEX IF NOT EXISTS idx_granules_format ON govinfo_gov.granules(file_format);

-- Content files table
CREATE TABLE IF NOT EXISTS govinfo_gov.content_files (
    id SERIAL PRIMARY KEY,
    content_id VARCHAR(100) UNIQUE NOT NULL,
    granule_id VARCHAR(100),
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(512),
    file_size BIGINT,
    file_format VARCHAR(20),
    download_url VARCHAR(255),
    checksum VARCHAR(100),
    content_type VARCHAR(100),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (granule_id) REFERENCES govinfo_gov.granules(granule_id) ON DELETE CASCADE
);

-- Content files index
CREATE INDEX IF NOT EXISTS idx_content_granule ON govinfo_gov.content_files(granule_id);
CREATE INDEX IF NOT EXISTS idx_content_format ON govinfo_gov.content_files(file_format);
CREATE INDEX IF NOT EXISTS idx_content_type ON govinfo_gov.content_files(content_type);

-- Metadata table
CREATE TABLE IF NOT EXISTS govinfo_gov.metadata (
    id SERIAL PRIMARY KEY,
    metadata_id VARCHAR(100) UNIQUE NOT NULL,
    package_id VARCHAR(100),
    metadata_type VARCHAR(50) NOT NULL,
    metadata_content JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (package_id) REFERENCES govinfo_gov.packages(package_id) ON DELETE CASCADE
);

-- Metadata index
CREATE INDEX IF NOT EXISTS idx_metadata_package ON govinfo_gov.metadata(package_id);
CREATE INDEX IF NOT EXISTS idx_metadata_type ON govinfo_gov.metadata(metadata_type);

-- Ingestion log table
CREATE TABLE IF NOT EXISTS govinfo_gov.ingestion_log (
    id SERIAL PRIMARY KEY,
    ingestion_type VARCHAR(50) NOT NULL,
    collection_code VARCHAR(50),
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    records_processed INTEGER DEFAULT 0,
    records_success INTEGER DEFAULT 0,
    records_failed INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'running',
    error_message TEXT,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (collection_code) REFERENCES govinfo_gov.collections(collection_code) ON DELETE SET NULL
);

-- Ingestion log index
CREATE INDEX IF NOT EXISTS idx_ingestion_type ON govinfo_gov.ingestion_log(ingestion_type);
CREATE INDEX IF NOT EXISTS idx_ingestion_collection ON govinfo_gov.ingestion_log(collection_code);
CREATE INDEX IF NOT EXISTS idx_ingestion_status ON govinfo_gov.ingestion_log(status);
CREATE INDEX IF NOT EXISTS idx_ingestion_time ON govinfo_gov.ingestion_log(start_time);

-- Collection statistics table
CREATE TABLE IF NOT EXISTS govinfo_gov.collection_stats (
    id SERIAL PRIMARY KEY,
    collection_code VARCHAR(50) UNIQUE NOT NULL,
    total_packages INTEGER DEFAULT 0,
    total_granules INTEGER DEFAULT 0,
    total_files INTEGER DEFAULT 0,
    total_size BIGINT DEFAULT 0,
    last_updated TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (collection_code) REFERENCES govinfo_gov.collections(collection_code) ON DELETE CASCADE
);

-- Collection statistics index
CREATE INDEX IF NOT EXISTS idx_stats_collection ON govinfo_gov.collection_stats(collection_code);

-- Package statistics table
CREATE TABLE IF NOT EXISTS govinfo_gov.package_stats (
    id SERIAL PRIMARY KEY,
    package_id VARCHAR(100) UNIQUE NOT NULL,
    granule_count INTEGER DEFAULT 0,
    file_count INTEGER DEFAULT 0,
    total_size BIGINT DEFAULT 0,
    last_updated TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (package_id) REFERENCES govinfo_gov.packages(package_id) ON DELETE CASCADE
);

-- Package statistics index
CREATE INDEX IF NOT EXISTS idx_package_stats_id ON govinfo_gov.package_stats(package_id);

-- Create triggers for automatic timestamp updates
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to all tables
CREATE TRIGGER update_collections_timestamp
BEFORE UPDATE ON govinfo_gov.collections
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_packages_timestamp
BEFORE UPDATE ON govinfo_gov.packages
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_granules_timestamp
BEFORE UPDATE ON govinfo_gov.granules
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_content_timestamp
BEFORE UPDATE ON govinfo_gov.content_files
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_metadata_timestamp
BEFORE UPDATE ON govinfo_gov.metadata
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_ingestion_log_timestamp
BEFORE UPDATE ON govinfo_gov.ingestion_log
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_collection_stats_timestamp
BEFORE UPDATE ON govinfo_gov.collection_stats
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_package_stats_timestamp
BEFORE UPDATE ON govinfo_gov.package_stats
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- Create views for common queries
CREATE OR REPLACE VIEW govinfo_gov.collection_summary_view AS
SELECT 
    c.collection_code, 
    c.collection_name, 
    c.description, 
    cs.total_packages, 
    cs.total_granules, 
    cs.total_files, 
    cs.total_size, 
    cs.last_updated
FROM govinfo_gov.collections c
LEFT JOIN govinfo_gov.collection_stats cs ON c.collection_code = cs.collection_code
ORDER BY c.collection_name;

CREATE OR REPLACE VIEW govinfo_gov.package_summary_view AS
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
FROM govinfo_gov.packages p
JOIN govinfo_gov.collections c ON p.collection_code = c.collection_code
LEFT JOIN govinfo_gov.package_stats ps ON p.package_id = ps.package_id
ORDER BY p.publication_date DESC;

-- Create materialized views for performance
CREATE MATERIALIZED VIEW IF NOT EXISTS govinfo_gov.collection_overview_mv AS
SELECT 
    collection_code, 
    collection_name, 
    COUNT(p.id) AS package_count,
    SUM(ps.granule_count) AS total_granules,
    SUM(ps.file_count) AS total_files,
    SUM(ps.total_size) AS total_size_bytes
FROM govinfo_gov.collections c
LEFT JOIN govinfo_gov.packages p ON c.collection_code = p.collection_code
LEFT JOIN govinfo_gov.package_stats ps ON p.package_id = ps.package_id
GROUP BY collection_code, collection_name
WITH DATA;

CREATE MATERIALIZED VIEW IF NOT EXISTS govinfo_gov.package_format_stats_mv AS
SELECT 
    file_format, 
    COUNT(*) AS package_count,
    SUM(file_size) AS total_size_bytes
FROM govinfo_gov.packages
GROUP BY file_format
WITH DATA;

-- Create indexes for materialized views
CREATE INDEX IF NOT EXISTS idx_collection_overview_mv_code ON govinfo_gov.collection_overview_mv(collection_code);
CREATE INDEX IF NOT EXISTS idx_package_format_stats_mv_format ON govinfo_gov.package_format_stats_mv(file_format);

-- Create functions for common operations
CREATE OR REPLACE FUNCTION govinfo_gov.get_collection_details(collection_code_param VARCHAR(50))
RETURNS TABLE (
    collection_code VARCHAR(50),
    collection_name TEXT,
    description TEXT,
    package_count INTEGER,
    last_updated TIMESTAMP,
    total_size BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.collection_code, 
        c.collection_name, 
        c.description, 
        c.package_count, 
        c.last_updated, 
        cs.total_size
    FROM govinfo_gov.collections c
    LEFT JOIN govinfo_gov.collection_stats cs ON c.collection_code = cs.collection_code
    WHERE c.collection_code = collection_code_param;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION govinfo_gov.get_package_details(package_id_param VARCHAR(100))
RETURNS TABLE (
    package_id VARCHAR(100),
    collection_code VARCHAR(50),
    package_title TEXT,
    package_type VARCHAR(50),
    publication_date TIMESTAMP,
    file_size BIGINT,
    file_format VARCHAR(20),
    download_url VARCHAR(255),
    granule_count INTEGER,
    file_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.package_id, 
        p.collection_code, 
        p.package_title, 
        p.package_type, 
        p.publication_date, 
        p.file_size, 
        p.file_format, 
        p.download_url, 
        ps.granule_count, 
        ps.file_count
    FROM govinfo_gov.packages p
    LEFT JOIN govinfo_gov.package_stats ps ON p.package_id = ps.package_id
    WHERE p.package_id = package_id_param;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION govinfo_gov.get_granule_details(granule_id_param VARCHAR(100))
RETURNS TABLE (
    granule_id VARCHAR(100),
    package_id VARCHAR(100),
    granule_title TEXT,
    granule_type VARCHAR(50),
    file_name VARCHAR(255),
    file_size BIGINT,
    file_format VARCHAR(20),
    download_url VARCHAR(255)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        g.granule_id, 
        g.package_id, 
        g.granule_title, 
        g.granule_type, 
        g.file_name, 
        g.file_size, 
        g.file_format, 
        g.download_url
    FROM govinfo_gov.granules g
    WHERE g.granule_id = granule_id_param;
END;
$$ LANGUAGE plpgsql;

-- Create sequences for ID generation
CREATE SEQUENCE IF NOT EXISTS govinfo_gov.collection_id_seq
    INCREMENT BY 1
    START WITH 1
    MINVALUE 1
    MAXVALUE 9999999999
    CACHE 20;

CREATE SEQUENCE IF NOT EXISTS govinfo_gov.package_id_seq
    INCREMENT BY 1
    START WITH 1
    MINVALUE 1
    MAXVALUE 9999999999
    CACHE 20;

-- Set permissions
GRANT ALL PRIVILEGES ON SCHEMA govinfo_gov TO opendiscourse;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA govinfo_gov TO opendiscourse;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA govinfo_gov TO opendiscourse;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA govinfo_gov TO opendiscourse;

-- Create schema version table
CREATE TABLE IF NOT EXISTS govinfo_gov.schema_versions (
    id SERIAL PRIMARY KEY,
    version VARCHAR(20) UNIQUE NOT NULL,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description TEXT
);

-- Insert schema version
INSERT INTO govinfo_gov.schema_versions (version, description)
VALUES ('1.0.0', 'Initial GovInfo.gov schema with comprehensive data model')
ON CONFLICT (version) DO NOTHING;

-- Reset search path
SET search_path TO public;

-- Migration complete
COMMENT ON SCHEMA govinfo_gov IS 'GovInfo.gov bulk data schema - Version 1.0.0';
