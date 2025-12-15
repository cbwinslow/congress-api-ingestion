-- Comprehensive Congress Data Schema for PostgreSQL
-- This schema supports all Congress.gov API data types

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create schema
CREATE SCHEMA IF NOT EXISTS congress;

-- Collections table (for GovInfo API)
CREATE TABLE IF NOT EXISTS congress.collections (
    id SERIAL PRIMARY KEY,
    collection_id VARCHAR(50) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    package_count INTEGER DEFAULT 0,
    last_updated TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Packages table (for GovInfo API)
CREATE TABLE IF NOT EXISTS congress.packages (
    id SERIAL PRIMARY KEY,
    package_id VARCHAR(100) UNIQUE NOT NULL,
    collection_id VARCHAR(50) NOT NULL,
    title VARCHAR(255),
    description TEXT,
    download_url VARCHAR(500),
    file_size BIGINT,
    file_type VARCHAR(50),
    publication_date TIMESTAMP,
    congress_session VARCHAR(50),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (collection_id) REFERENCES congress.collections(collection_id)
);

-- Bills table
CREATE TABLE IF NOT EXISTS congress.bills (
    id SERIAL PRIMARY KEY,
    bill_id VARCHAR(50) UNIQUE NOT NULL,
    congress INT NOT NULL,
    bill_type VARCHAR(10) NOT NULL,
    bill_number VARCHAR(10) NOT NULL,
    title VARCHAR(500) NOT NULL,
    official_title TEXT,
    short_title TEXT,
    summary TEXT,
    sponsor_id VARCHAR(50),
    sponsor_name VARCHAR(100),
    sponsor_state VARCHAR(2),
    sponsor_party VARCHAR(10),
    introduced_date DATE,
    last_action_date DATE,
    last_action TEXT,
    status VARCHAR(50),
    url VARCHAR(255),
    pdf_url VARCHAR(255),
    text_content TEXT,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Legislators table
CREATE TABLE IF NOT EXISTS congress.legislators (
    id SERIAL PRIMARY KEY,
    legislator_id VARCHAR(50) UNIQUE NOT NULL,
    bioguide_id VARCHAR(50),
    name VARCHAR(100) NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    middle_name VARCHAR(50),
    suffix VARCHAR(10),
    gender VARCHAR(20),
    birth_date DATE,
    party VARCHAR(10),
    state VARCHAR(2),
    district VARCHAR(10),
    chamber VARCHAR(10),
    title VARCHAR(20),
    phone VARCHAR(20),
    office VARCHAR(50),
    website VARCHAR(255),
    twitter VARCHAR(50),
    facebook VARCHAR(100),
    youtube VARCHAR(100),
    instagram VARCHAR(100),
    term_start DATE,
    term_end DATE,
    in_office BOOLEAN DEFAULT TRUE,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Committees table
CREATE TABLE IF NOT EXISTS congress.committees (
    id SERIAL PRIMARY KEY,
    committee_id VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    chamber VARCHAR(10),
    committee_type VARCHAR(20),
    subcommittee BOOLEAN DEFAULT FALSE,
    parent_committee_id VARCHAR(50),
    jurisdiction TEXT,
    url VARCHAR(255),
    phone VARCHAR(20),
    office VARCHAR(50),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Votes table
CREATE TABLE IF NOT EXISTS congress.votes (
    id SERIAL PRIMARY KEY,
    vote_id VARCHAR(50) UNIQUE NOT NULL,
    congress INT NOT NULL,
    session INT NOT NULL,
    roll_call INT NOT NULL,
    vote_date DATE NOT NULL,
    vote_time TIME,
    question TEXT NOT NULL,
    result VARCHAR(20),
    bill_number VARCHAR(20),
    bill_title TEXT,
    chamber VARCHAR(10),
    vote_type VARCHAR(20),
    total_votes INT,
    democratic_yes INT,
    democratic_no INT,
    republican_yes INT,
    republican_no INT,
    independent_yes INT,
    independent_no INT,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Vote positions table
CREATE TABLE IF NOT EXISTS congress.vote_positions (
    id SERIAL PRIMARY KEY,
    vote_id VARCHAR(50) NOT NULL,
    legislator_id VARCHAR(50) NOT NULL,
    name VARCHAR(100),
    party VARCHAR(10),
    state VARCHAR(2),
    district VARCHAR(10),
    vote_position VARCHAR(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vote_id) REFERENCES congress.votes(vote_id)
);

-- Bill sponsors table
CREATE TABLE IF NOT EXISTS congress.bill_sponsors (
    id SERIAL PRIMARY KEY,
    bill_id VARCHAR(50) NOT NULL,
    legislator_id VARCHAR(50) NOT NULL,
    sponsor_type VARCHAR(20) NOT NULL,
    name VARCHAR(100),
    state VARCHAR(2),
    party VARCHAR(10),
    date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (bill_id) REFERENCES congress.bills(bill_id)
);

-- Bill actions table
CREATE TABLE IF NOT EXISTS congress.bill_actions (
    id SERIAL PRIMARY KEY,
    bill_id VARCHAR(50) NOT NULL,
    action_date DATE,
    action_time TIME,
    action_type VARCHAR(50),
    action_text TEXT,
    chamber VARCHAR(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (bill_id) REFERENCES congress.bills(bill_id)
);

-- Bill subjects table
CREATE TABLE IF NOT EXISTS congress.bill_subjects (
    id SERIAL PRIMARY KEY,
    bill_id VARCHAR(50) NOT NULL,
    subject VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (bill_id) REFERENCES congress.bills(bill_id)
);

-- Committee members table
CREATE TABLE IF NOT EXISTS congress.committee_members (
    id SERIAL PRIMARY KEY,
    committee_id VARCHAR(50) NOT NULL,
    legislator_id VARCHAR(50) NOT NULL,
    name VARCHAR(100),
    party VARCHAR(10),
    state VARCHAR(2),
    district VARCHAR(10),
    role VARCHAR(50),
    rank INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (committee_id) REFERENCES congress.committees(committee_id)
);

-- Ingestion log table
CREATE TABLE IF NOT EXISTS congress.ingestion_log (
    id SERIAL PRIMARY KEY,
    data_type VARCHAR(50) NOT NULL,
    data_id VARCHAR(100),
    status VARCHAR(20) NOT NULL,
    records_processed INT DEFAULT 0,
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP,
    error_message TEXT,
    metadata JSONB
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_bills_congress ON congress.bills(congress);
CREATE INDEX IF NOT EXISTS idx_bills_type ON congress.bills(bill_type);
CREATE INDEX IF NOT EXISTS idx_bills_sponsor ON congress.bills(sponsor_id);
CREATE INDEX IF NOT EXISTS idx_bills_date ON congress.bills(introduced_date);
CREATE INDEX IF NOT EXISTS idx_legislators_state ON congress.legislators(state);
CREATE INDEX IF NOT EXISTS idx_legislators_chamber ON congress.legislators(chamber);
CREATE INDEX IF NOT EXISTS idx_legislators_party ON congress.legislators(party);
CREATE INDEX IF NOT EXISTS idx_committees_chamber ON congress.committees(chamber);
CREATE INDEX IF NOT EXISTS idx_votes_congress ON congress.votes(congress);
CREATE INDEX IF NOT EXISTS idx_votes_date ON congress.votes(vote_date);
CREATE INDEX IF NOT EXISTS idx_votes_bill ON congress.votes(bill_number);
CREATE INDEX IF NOT EXISTS idx_vote_positions_vote ON congress.vote_positions(vote_id);
CREATE INDEX IF NOT EXISTS idx_bill_sponsors_bill ON congress.bill_sponsors(bill_id);
CREATE INDEX IF NOT EXISTS idx_bill_actions_bill ON congress.bill_actions(bill_id);
CREATE INDEX IF NOT EXISTS idx_bill_subjects_bill ON congress.bill_subjects(bill_id);
CREATE INDEX IF NOT EXISTS idx_committee_members_committee ON congress.committee_members(committee_id);

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
BEFORE UPDATE ON congress.bills
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_legislators_timestamp
BEFORE UPDATE ON congress.legislators
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_committees_timestamp
BEFORE UPDATE ON congress.committees
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_votes_timestamp
BEFORE UPDATE ON congress.votes
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_packages_timestamp
BEFORE UPDATE ON congress.packages
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_collections_timestamp
BEFORE UPDATE ON congress.collections
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- Grant permissions
GRANT ALL PRIVILEGES ON SCHEMA congress TO opendiscourse;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA congress TO opendiscourse;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA congress TO opendiscourse;

-- Create views for common queries
CREATE OR REPLACE VIEW congress.recent_bills AS
SELECT b.*, l.name AS sponsor_name, l.party AS sponsor_party, l.state AS sponsor_state
FROM congress.bills b
LEFT JOIN congress.legislators l ON b.sponsor_id = l.legislator_id
ORDER BY b.introduced_date DESC
LIMIT 100;

CREATE OR REPLACE VIEW congress.active_legislators AS
SELECT * FROM congress.legislators WHERE in_office = TRUE;

CREATE OR REPLACE VIEW congress.recent_votes AS
SELECT * FROM congress.votes ORDER BY vote_date DESC LIMIT 50;

