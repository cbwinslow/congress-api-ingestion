-- Congress.gov PostgreSQL Migration Script
-- Comprehensive schema for Congress.gov API data
-- Version: 1.0.0
-- Date: 2025-12-15

-- Enable extensions for enhanced functionality
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- Create schema for Congress.gov data
CREATE SCHEMA IF NOT EXISTS congress_gov;

-- Set search path
SET search_path TO congress_gov, public;

-- Bills table
CREATE TABLE IF NOT EXISTS congress_gov.bills (
    id SERIAL PRIMARY KEY,
    bill_id VARCHAR(50) UNIQUE NOT NULL,
    congress_number INTEGER NOT NULL,
    bill_type VARCHAR(10) NOT NULL,
    bill_number VARCHAR(10) NOT NULL,
    title TEXT NOT NULL,
    short_title TEXT,
    official_title TEXT,
    summary TEXT,
    sponsor_id VARCHAR(50),
    sponsor_name VARCHAR(100),
    sponsor_state VARCHAR(2),
    sponsor_party VARCHAR(10),
    introduced_date TIMESTAMP,
    last_action_date TIMESTAMP,
    last_action TEXT,
    status VARCHAR(50),
    url VARCHAR(255),
    pdf_url VARCHAR(255),
    text_url VARCHAR(255),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_bills_congress CHECK (congress_number BETWEEN 1 AND 200)
);

-- Bills index
CREATE INDEX IF NOT EXISTS idx_bills_congress ON congress_gov.bills(congress_number);
CREATE INDEX IF NOT EXISTS idx_bills_type ON congress_gov.bills(bill_type);
CREATE INDEX IF NOT EXISTS idx_bills_status ON congress_gov.bills(status);
CREATE INDEX IF NOT EXISTS idx_bills_date ON congress_gov.bills(introduced_date);

-- Legislators table
CREATE TABLE IF NOT EXISTS congress_gov.legislators (
    id SERIAL PRIMARY KEY,
    bioguide_id VARCHAR(50) UNIQUE NOT NULL,
    govtrack_id VARCHAR(50),
    crp_id VARCHAR(50),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    name_suffix VARCHAR(10),
    nickname VARCHAR(100),
    full_name VARCHAR(200) NOT NULL,
    birth_date DATE,
    gender VARCHAR(20),
    party VARCHAR(10),
    state VARCHAR(2),
    district VARCHAR(10),
    in_office BOOLEAN,
    start_date DATE,
    end_date DATE,
    office VARCHAR(100),
    phone VARCHAR(20),
    fax VARCHAR(20),
    website VARCHAR(255),
    contact_form VARCHAR(255),
    twitter VARCHAR(50),
    facebook VARCHAR(100),
    youtube VARCHAR(100),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Legislators index
CREATE INDEX IF NOT EXISTS idx_legislators_state ON congress_gov.legislators(state);
CREATE INDEX IF NOT EXISTS idx_legislators_party ON congress_gov.legislators(party);
CREATE INDEX IF NOT EXISTS idx_legislators_in_office ON congress_gov.legislators(in_office);
CREATE INDEX IF NOT EXISTS idx_legislators_name ON congress_gov.legislators(full_name);

-- Committees table
CREATE TABLE IF NOT EXISTS congress_gov.committees (
    id SERIAL PRIMARY KEY,
    committee_id VARCHAR(50) UNIQUE NOT NULL,
    congress_number INTEGER NOT NULL,
    chamber VARCHAR(20) NOT NULL,
    name TEXT NOT NULL,
    full_name TEXT,
    url VARCHAR(255),
    subcommittee BOOLEAN DEFAULT FALSE,
    parent_committee_id VARCHAR(50),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Committees index
CREATE INDEX IF NOT EXISTS idx_committees_congress ON congress_gov.committees(congress_number);
CREATE INDEX IF NOT EXISTS idx_committees_chamber ON congress_gov.committees(chamber);
CREATE INDEX IF NOT EXISTS idx_committees_subcommittee ON congress_gov.committees(subcommittee);

-- Votes table
CREATE TABLE IF NOT EXISTS congress_gov.votes (
    id SERIAL PRIMARY KEY,
    vote_id VARCHAR(50) UNIQUE NOT NULL,
    congress_number INTEGER NOT NULL,
    chamber VARCHAR(20) NOT NULL,
    session_number INTEGER NOT NULL,
    roll_call_number INTEGER NOT NULL,
    bill_number VARCHAR(20),
    question TEXT NOT NULL,
    description TEXT,
    vote_date TIMESTAMP NOT NULL,
    vote_time TIMESTAMP,
    result VARCHAR(50),
    required_members INTEGER,
    present_members INTEGER,
    yes_votes INTEGER,
    no_votes INTEGER,
    present_votes INTEGER,
    not_voting INTEGER,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Votes index
CREATE INDEX IF NOT EXISTS idx_votes_congress ON congress_gov.votes(congress_number);
CREATE INDEX IF NOT EXISTS idx_votes_chamber ON congress_gov.votes(chamber);
CREATE INDEX IF NOT EXISTS idx_votes_date ON congress_gov.votes(vote_date);
CREATE INDEX IF NOT EXISTS idx_votes_result ON congress_gov.votes(result);

-- Vote results table
CREATE TABLE IF NOT EXISTS congress_gov.vote_results (
    id SERIAL PRIMARY KEY,
    vote_id VARCHAR(50) NOT NULL,
    legislator_id VARCHAR(50) NOT NULL,
    vote_position VARCHAR(20) NOT NULL,
    vote_value VARCHAR(10),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vote_id) REFERENCES congress_gov.votes(vote_id) ON DELETE CASCADE,
    FOREIGN KEY (legislator_id) REFERENCES congress_gov.legislators(bioguide_id) ON DELETE CASCADE
);

-- Vote results index
CREATE INDEX IF NOT EXISTS idx_vote_results_vote ON congress_gov.vote_results(vote_id);
CREATE INDEX IF NOT EXISTS idx_vote_results_legislator ON congress_gov.vote_results(legislator_id);
CREATE INDEX IF NOT EXISTS idx_vote_results_position ON congress_gov.vote_results(vote_position);

-- Amendments table
CREATE TABLE IF NOT EXISTS congress_gov.amendments (
    id SERIAL PRIMARY KEY,
    amendment_id VARCHAR(50) UNIQUE NOT NULL,
    congress_number INTEGER NOT NULL,
    chamber VARCHAR(20) NOT NULL,
    amendment_number VARCHAR(20) NOT NULL,
    bill_number VARCHAR(20),
    sponsor_id VARCHAR(50),
    sponsor_name VARCHAR(100),
    sponsor_state VARCHAR(2),
    sponsor_party VARCHAR(10),
    introduced_date TIMESTAMP,
    purpose TEXT,
    description TEXT,
    status VARCHAR(50),
    url VARCHAR(255),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Amendments index
CREATE INDEX IF NOT EXISTS idx_amendments_congress ON congress_gov.amendments(congress_number);
CREATE INDEX IF NOT EXISTS idx_amendments_chamber ON congress_gov.amendments(chamber);
CREATE INDEX IF NOT EXISTS idx_amendments_bill ON congress_gov.amendments(bill_number);
CREATE INDEX IF NOT EXISTS idx_amendments_date ON congress_gov.amendments(introduced_date);

-- Hearings table
CREATE TABLE IF NOT EXISTS congress_gov.hearings (
    id SERIAL PRIMARY KEY,
    hearing_id VARCHAR(50) UNIQUE NOT NULL,
    congress_number INTEGER NOT NULL,
    chamber VARCHAR(20) NOT NULL,
    committee_id VARCHAR(50),
    committee_name TEXT,
    hearing_type VARCHAR(50),
    title TEXT NOT NULL,
    date TIMESTAMP NOT NULL,
    time TIMESTAMP,
    location TEXT,
    url VARCHAR(255),
    video_url VARCHAR(255),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Hearings index
CREATE INDEX IF NOT EXISTS idx_hearings_congress ON congress_gov.hearings(congress_number);
CREATE INDEX IF NOT EXISTS idx_hearings_chamber ON congress_gov.hearings(chamber);
CREATE INDEX IF NOT EXISTS idx_hearings_committee ON congress_gov.hearings(committee_id);
CREATE INDEX IF NOT EXISTS idx_hearings_date ON congress_gov.hearings(date);

-- Committee memberships table
CREATE TABLE IF NOT EXISTS congress_gov.committee_memberships (
    id SERIAL PRIMARY KEY,
    committee_id VARCHAR(50) NOT NULL,
    legislator_id VARCHAR(50) NOT NULL,
    congress_number INTEGER NOT NULL,
    chamber VARCHAR(20) NOT NULL,
    role VARCHAR(50),
    start_date DATE,
    end_date DATE,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (committee_id) REFERENCES congress_gov.committees(committee_id) ON DELETE CASCADE,
    FOREIGN KEY (legislator_id) REFERENCES congress_gov.legislators(bioguide_id) ON DELETE CASCADE
);

-- Committee memberships index
CREATE INDEX IF NOT EXISTS idx_memberships_committee ON congress_gov.committee_memberships(committee_id);
CREATE INDEX IF NOT EXISTS idx_memberships_legislator ON congress_gov.committee_memberships(legislator_id);
CREATE INDEX IF NOT EXISTS idx_memberships_congress ON congress_gov.committee_memberships(congress_number);

-- Bill sponsors table
CREATE TABLE IF NOT EXISTS congress_gov.bill_sponsors (
    id SERIAL PRIMARY KEY,
    bill_id VARCHAR(50) NOT NULL,
    legislator_id VARCHAR(50) NOT NULL,
    sponsor_type VARCHAR(20) NOT NULL,
    sponsor_order INTEGER,
    date TIMESTAMP,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (bill_id) REFERENCES congress_gov.bills(bill_id) ON DELETE CASCADE,
    FOREIGN KEY (legislator_id) REFERENCES congress_gov.legislators(bioguide_id) ON DELETE CASCADE
);

-- Bill sponsors index
CREATE INDEX IF NOT EXISTS idx_sponsors_bill ON congress_gov.bill_sponsors(bill_id);
CREATE INDEX IF NOT EXISTS idx_sponsors_legislator ON congress_gov.bill_sponsors(legislator_id);
CREATE INDEX IF NOT EXISTS idx_sponsors_type ON congress_gov.bill_sponsors(sponsor_type);

-- Bill subjects table
CREATE TABLE IF NOT EXISTS congress_gov.bill_subjects (
    id SERIAL PRIMARY KEY,
    bill_id VARCHAR(50) NOT NULL,
    subject VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (bill_id) REFERENCES congress_gov.bills(bill_id) ON DELETE CASCADE
);

-- Bill subjects index
CREATE INDEX IF NOT EXISTS idx_subjects_bill ON congress_gov.bill_subjects(bill_id);
CREATE INDEX IF NOT EXISTS idx_subjects_subject ON congress_gov.bill_subjects(subject);

-- Bill actions table
CREATE TABLE IF NOT EXISTS congress_gov.bill_actions (
    id SERIAL PRIMARY KEY,
    bill_id VARCHAR(50) NOT NULL,
    action_date TIMESTAMP NOT NULL,
    action_type VARCHAR(100) NOT NULL,
    action_text TEXT NOT NULL,
    chamber VARCHAR(20),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (bill_id) REFERENCES congress_gov.bills(bill_id) ON DELETE CASCADE
);

-- Bill actions index
CREATE INDEX IF NOT EXISTS idx_actions_bill ON congress_gov.bill_actions(bill_id);
CREATE INDEX IF NOT EXISTS idx_actions_date ON congress_gov.bill_actions(action_date);
CREATE INDEX IF NOT EXISTS idx_actions_type ON congress_gov.bill_actions(action_type);

-- Ingestion log table
CREATE TABLE IF NOT EXISTS congress_gov.ingestion_log (
    id SERIAL PRIMARY KEY,
    ingestion_type VARCHAR(50) NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    records_processed INTEGER DEFAULT 0,
    records_success INTEGER DEFAULT 0,
    records_failed INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'running',
    error_message TEXT,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Ingestion log index
CREATE INDEX IF NOT EXISTS idx_ingestion_type ON congress_gov.ingestion_log(ingestion_type);
CREATE INDEX IF NOT EXISTS idx_ingestion_status ON congress_gov.ingestion_log(status);
CREATE INDEX IF NOT EXISTS idx_ingestion_time ON congress_gov.ingestion_log(start_time);

-- Create triggers for automatic timestamp updates
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to all tables
CREATE TRIGGER update_bills_timestamp
BEFORE UPDATE ON congress_gov.bills
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_legislators_timestamp
BEFORE UPDATE ON congress_gov.legislators
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_committees_timestamp
BEFORE UPDATE ON congress_gov.committees
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_votes_timestamp
BEFORE UPDATE ON congress_gov.votes
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_amendments_timestamp
BEFORE UPDATE ON congress_gov.amendments
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_hearings_timestamp
BEFORE UPDATE ON congress_gov.hearings
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_ingestion_log_timestamp
BEFORE UPDATE ON congress_gov.ingestion_log
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- Create views for common queries
CREATE OR REPLACE VIEW congress_gov.bill_sponsors_view AS
SELECT 
    b.bill_id, 
    b.title, 
    b.congress_number, 
    l.bioguide_id, 
    l.full_name, 
    l.party, 
    l.state, 
    bs.sponsor_type, 
    bs.sponsor_order
FROM congress_gov.bills b
JOIN congress_gov.bill_sponsors bs ON b.bill_id = bs.bill_id
JOIN congress_gov.legislators l ON bs.legislator_id = l.bioguide_id
ORDER BY b.congress_number DESC, bs.sponsor_order;

CREATE OR REPLACE VIEW congress_gov.vote_summary_view AS
SELECT 
    v.vote_id, 
    v.congress_number, 
    v.chamber, 
    v.vote_date, 
    v.question, 
    v.result, 
    COUNT(vr.id) AS total_votes,
    SUM(CASE WHEN vr.vote_position = 'Yea' THEN 1 ELSE 0 END) AS yea_votes,
    SUM(CASE WHEN vr.vote_position = 'Nay' THEN 1 ELSE 0 END) AS nay_votes,
    SUM(CASE WHEN vr.vote_position = 'Present' THEN 1 ELSE 0 END) AS present_votes,
    SUM(CASE WHEN vr.vote_position = 'Not Voting' THEN 1 ELSE 0 END) AS not_voting
FROM congress_gov.votes v
LEFT JOIN congress_gov.vote_results vr ON v.vote_id = vr.vote_id
GROUP BY v.vote_id, v.congress_number, v.chamber, v.vote_date, v.question, v.result
ORDER BY v.vote_date DESC;

-- Create materialized views for performance
CREATE MATERIALIZED VIEW IF NOT EXISTS congress_gov.bill_stats_mv AS
SELECT 
    congress_number, 
    bill_type, 
    COUNT(*) AS bill_count,
    SUM(CASE WHEN status = 'Enacted' THEN 1 ELSE 0 END) AS enacted_count,
    SUM(CASE WHEN status = 'Introduced' THEN 1 ELSE 0 END) AS introduced_count,
    SUM(CASE WHEN status = 'Failed' THEN 1 ELSE 0 END) AS failed_count
FROM congress_gov.bills
GROUP BY congress_number, bill_type
WITH DATA;

CREATE MATERIALIZED VIEW IF NOT EXISTS congress_gov.legislator_stats_mv AS
SELECT 
    state, 
    party, 
    COUNT(*) AS legislator_count,
    SUM(CASE WHEN in_office THEN 1 ELSE 0 END) AS current_count,
    SUM(CASE WHEN NOT in_office THEN 1 ELSE 0 END) AS former_count
FROM congress_gov.legislators
GROUP BY state, party
WITH DATA;

-- Create indexes for materialized views
CREATE INDEX IF NOT EXISTS idx_bill_stats_mv_congress ON congress_gov.bill_stats_mv(congress_number);
CREATE INDEX IF NOT EXISTS idx_legislator_stats_mv_state ON congress_gov.legislator_stats_mv(state);

-- Create functions for common operations
CREATE OR REPLACE FUNCTION congress_gov.get_bill_details(bill_id_param VARCHAR(50))
RETURNS TABLE (
    bill_id VARCHAR(50),
    title TEXT,
    congress_number INTEGER,
    bill_type VARCHAR(10),
    status VARCHAR(50),
    introduced_date TIMESTAMP,
    last_action_date TIMESTAMP,
    last_action TEXT,
    sponsor_name VARCHAR(200),
    sponsor_party VARCHAR(10),
    sponsor_state VARCHAR(2),
    subject_count INTEGER,
    action_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.bill_id, 
        b.title, 
        b.congress_number, 
        b.bill_type, 
        b.status, 
        b.introduced_date, 
        b.last_action_date, 
        b.last_action, 
        l.full_name AS sponsor_name, 
        l.party AS sponsor_party, 
        l.state AS sponsor_state, 
        (SELECT COUNT(*) FROM congress_gov.bill_subjects WHERE bill_id = b.bill_id) AS subject_count, 
        (SELECT COUNT(*) FROM congress_gov.bill_actions WHERE bill_id = b.bill_id) AS action_count
    FROM congress_gov.bills b
    LEFT JOIN congress_gov.bill_sponsors bs ON b.bill_id = bs.bill_id AND bs.sponsor_type = 'primary'
    LEFT JOIN congress_gov.legislators l ON bs.legislator_id = l.bioguide_id
    WHERE b.bill_id = bill_id_param;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION congress_gov.get_legislator_votes(legislator_id_param VARCHAR(50), congress_param INTEGER)
RETURNS TABLE (
    vote_id VARCHAR(50),
    vote_date TIMESTAMP,
    question TEXT,
    result VARCHAR(50),
    vote_position VARCHAR(20)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        v.vote_id, 
        v.vote_date, 
        v.question, 
        v.result, 
        vr.vote_position
    FROM congress_gov.votes v
    JOIN congress_gov.vote_results vr ON v.vote_id = vr.vote_id
    WHERE vr.legislator_id = legislator_id_param
    AND v.congress_number = congress_param
    ORDER BY v.vote_date DESC;
END;
$$ LANGUAGE plpgsql;

-- Create sequences for ID generation
CREATE SEQUENCE IF NOT EXISTS congress_gov.bill_id_seq
    INCREMENT BY 1
    START WITH 1
    MINVALUE 1
    MAXVALUE 9999999999
    CACHE 20;

CREATE SEQUENCE IF NOT EXISTS congress_gov.legislator_id_seq
    INCREMENT BY 1
    START WITH 1
    MINVALUE 1
    MAXVALUE 9999999999
    CACHE 20;

-- Set permissions
GRANT ALL PRIVILEGES ON SCHEMA congress_gov TO opendiscourse;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA congress_gov TO opendiscourse;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA congress_gov TO opendiscourse;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA congress_gov TO opendiscourse;

-- Create schema version table
CREATE TABLE IF NOT EXISTS congress_gov.schema_versions (
    id SERIAL PRIMARY KEY,
    version VARCHAR(20) UNIQUE NOT NULL,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description TEXT
);

-- Insert schema version
INSERT INTO congress_gov.schema_versions (version, description)
VALUES ('1.0.0', 'Initial Congress.gov schema with comprehensive data model')
ON CONFLICT (version) DO NOTHING;

-- Reset search path
SET search_path TO public;

-- Migration complete
COMMENT ON SCHEMA congress_gov IS 'Congress.gov API data schema - Version 1.0.0';
