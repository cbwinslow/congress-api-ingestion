-- Congress API PostgreSQL Database Schema
-- Version: 1.0
-- Description: Comprehensive schema for GovInfo and Congress.gov data

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- Collections table (from GovInfo API)
CREATE TABLE IF NOT EXISTS collections (
    id SERIAL PRIMARY KEY,
    collection_code VARCHAR(50) UNIQUE NOT NULL,
    collection_name VARCHAR(255) NOT NULL,
    description TEXT,
    last_modified TIMESTAMP,
    package_count INTEGER DEFAULT 0,
    download_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Packages table (main data structure)
CREATE TABLE IF NOT EXISTS packages (
    id SERIAL PRIMARY KEY,
    package_id VARCHAR(255) UNIQUE NOT NULL,
    collection_code VARCHAR(50) REFERENCES collections(collection_code),
    title TEXT NOT NULL,
    summary TEXT,
    download_url TEXT,
    details_link TEXT,
    congress_session INTEGER,
    congress_number INTEGER,
    chamber VARCHAR(50),
    bill_type VARCHAR(20),
    bill_number INTEGER,
    resolution_number INTEGER,
    document_type VARCHAR(100),
    document_number VARCHAR(50),
    publication_date DATE,
    date_issued DATE,
    last_modified TIMESTAMP,
    government_author1 VARCHAR(255),
    government_author2 VARCHAR(255),
    publisher VARCHAR(255),
    branch VARCHAR(50),
    category VARCHAR(100),
    related_documents JSONB,
    metadata JSONB,
    file_metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bills table (detailed bill information)
CREATE TABLE IF NOT EXISTS bills (
    id SERIAL PRIMARY KEY,
    bill_id VARCHAR(50) UNIQUE NOT NULL,
    bill_number VARCHAR(20) NOT NULL,
    bill_type VARCHAR(10) NOT NULL,
    congress_number INTEGER NOT NULL,
    introduced_date DATE,
    sponsor_id VARCHAR(50),
    sponsor_name VARCHAR(255),
    sponsor_state VARCHAR(2),
    sponsor_party VARCHAR(50),
    title TEXT NOT NULL,
    short_title TEXT,
    official_title TEXT,
    summary TEXT,
    latest_action_date DATE,
    latest_action_text TEXT,
    status VARCHAR(100),
    status_at DATE,
    house_passage_date DATE,
    senate_passage_date DATE,
    enacted_date DATE,
    vetoed_date DATE,
    law_number VARCHAR(50),
    cbo_cost_estimate_url TEXT,
    subjects JSONB,
    committees JSONB,
    related_bills JSONB,
    amendments JSONB,
    actions JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Legislators table
CREATE TABLE IF NOT EXISTS legislators (
    id SERIAL PRIMARY KEY,
    legislator_id VARCHAR(50) UNIQUE NOT NULL,
    bioguide_id VARCHAR(20),
    thomas_id VARCHAR(20),
    govtrack_id INTEGER,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    party VARCHAR(50),
    state VARCHAR(2),
    district INTEGER,
    chamber VARCHAR(20),
    url TEXT,
    contact_form TEXT,
    phone VARCHAR(50),
    fax VARCHAR(50),
    office VARCHAR(255),
    birthday DATE,
    gender VARCHAR(20),
    leadership_role VARCHAR(100),
    next_election INTEGER,
    total_votes INTEGER DEFAULT 0,
    missed_votes INTEGER DEFAULT 0,
    total_present INTEGER DEFAULT 0,
    office_address JSONB,
    social_media JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Committees table
CREATE TABLE IF NOT EXISTS committees (
    id SERIAL PRIMARY KEY,
    committee_id VARCHAR(50) UNIQUE NOT NULL,
    committee_code VARCHAR(20),
    name VARCHAR(255) NOT NULL,
    chamber VARCHAR(20),
    committee_type VARCHAR(50),
    subcommittee BOOLEAN DEFAULT FALSE,
    parent_committee_id VARCHAR(50) REFERENCES committees(committee_id),
    url TEXT,
    phone VARCHAR(50),
    office VARCHAR(255),
    members JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Votes table
CREATE TABLE IF NOT EXISTS votes (
    id SERIAL PRIMARY KEY,
    vote_id VARCHAR(50) UNIQUE NOT NULL,
    congress_number INTEGER NOT NULL,
    session_number INTEGER,
    chamber VARCHAR(20) NOT NULL,
    roll_call_number INTEGER,
    vote_date DATE NOT NULL,
    vote_time TIME,
    question TEXT,
    description TEXT,
    vote_type VARCHAR(50),
    result VARCHAR(50),
    yeas INTEGER DEFAULT 0,
    nays INTEGER DEFAULT 0,
    present INTEGER DEFAULT 0,
    not_voting INTEGER DEFAULT 0,
    democratic_position VARCHAR(20),
    republican_position VARCHAR(20),
    bill_id VARCHAR(50),
    amendment_id VARCHAR(50),
    nomination_id VARCHAR(50),
    vote_details JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Individual vote records
CREATE TABLE IF NOT EXISTS individual_votes (
    id SERIAL PRIMARY KEY,
    vote_id VARCHAR(50) NOT NULL REFERENCES votes(vote_id),
    legislator_id VARCHAR(50) NOT NULL REFERENCES legislators(legislator_id),
    vote_position VARCHAR(20) NOT NULL,
    party VARCHAR(50),
    state VARCHAR(2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(vote_id, legislator_id)
);

-- Congressional Record table
CREATE TABLE IF NOT EXISTS congressional_record (
    id SERIAL PRIMARY KEY,
    record_id VARCHAR(255) UNIQUE NOT NULL,
    congress_number INTEGER NOT NULL,
    session_number INTEGER,
    issue_date DATE NOT NULL,
    volume_number INTEGER,
    part_number INTEGER,
    section_type VARCHAR(50),
    title TEXT,
    content TEXT,
    pdf_url TEXT,
    html_url TEXT,
    xml_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Ingestion log table
CREATE TABLE IF NOT EXISTS ingestion_log (
    id SERIAL PRIMARY KEY,
    collection_code VARCHAR(50),
    package_id VARCHAR(255),
    operation_type VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL,
    offset_value INTEGER DEFAULT 0,
    limit_value INTEGER DEFAULT 100,
    records_processed INTEGER DEFAULT 0,
    error_message TEXT,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    duration_seconds INTEGER,
    metadata JSONB
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_packages_collection ON packages(collection_code);
CREATE INDEX IF NOT EXISTS idx_packages_congress ON packages(congress_number);
CREATE INDEX IF NOT EXISTS idx_packages_chamber ON packages(chamber);
CREATE INDEX IF NOT EXISTS idx_packages_bill_type ON packages(bill_type);
CREATE INDEX IF NOT EXISTS idx_packages_publication_date ON packages(publication_date);
CREATE INDEX IF NOT EXISTS idx_packages_gin_metadata ON packages USING GIN(metadata);

CREATE INDEX IF NOT EXISTS idx_bills_congress ON bills(congress_number);
CREATE INDEX IF NOT EXISTS idx_bills_bill_type ON bills(bill_type);
CREATE INDEX IF NOT EXISTS idx_bills_status ON bills(status);
CREATE INDEX IF NOT EXISTS idx_bills_sponsor ON bills(sponsor_id);
CREATE INDEX IF NOT EXISTS idx_bills_introduced_date ON bills(introduced_date);
CREATE INDEX IF NOT EXISTS idx_bills_gin_subjects ON bills USING GIN(subjects);

CREATE INDEX IF NOT EXISTS idx_legislators_state ON legislators(state);
CREATE INDEX IF NOT EXISTS idx_legislators_party ON legislators(party);
CREATE INDEX IF NOT EXISTS idx_legislators_chamber ON legislators(chamber);
CREATE INDEX IF NOT EXISTS idx_legislators_name ON legislators(last_name, first_name);

CREATE INDEX IF NOT EXISTS idx_committees_chamber ON committees(chamber);
CREATE INDEX IF NOT EXISTS idx_committees_type ON committees(committee_type);

CREATE INDEX IF NOT EXISTS idx_votes_congress ON votes(congress_number);
CREATE INDEX IF NOT EXISTS idx_votes_chamber ON votes(chamber);
CREATE INDEX IF NOT EXISTS idx_votes_date ON votes(vote_date);
CREATE INDEX IF NOT EXISTS idx_votes_roll_call ON votes(congress_number, chamber, roll_call_number);

CREATE INDEX IF NOT EXISTS idx_individual_votes_vote_id ON individual_votes(vote_id);
CREATE INDEX IF NOT EXISTS idx_individual_votes_legislator ON individual_votes(legislator_id);

CREATE INDEX IF NOT EXISTS idx_congressional_record_date ON congressional_record(issue_date);
CREATE INDEX IF NOT EXISTS idx_congressional_record_congress ON congressional_record(congress_number);

CREATE INDEX IF NOT EXISTS idx_ingestion_log_collection ON ingestion_log(collection_code);
CREATE INDEX IF NOT EXISTS idx_ingestion_log_status ON ingestion_log(status);
CREATE INDEX IF NOT EXISTS idx_ingestion_log_started ON ingestion_log(started_at);

-- Create update trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply update triggers to all tables with updated_at column
CREATE TRIGGER update_collections_updated_at BEFORE UPDATE ON collections FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_packages_updated_at BEFORE UPDATE ON packages FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_bills_updated_at BEFORE UPDATE ON bills FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_legislators_updated_at BEFORE UPDATE ON legislators FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_committees_updated_at BEFORE UPDATE ON committees FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_votes_updated_at BEFORE UPDATE ON votes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_congressional_record_updated_at BEFORE UPDATE ON congressional_record FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert default collections (from GovInfo API)
INSERT INTO collections (collection_code, collection_name, description) VALUES
('BILLS', 'Congressional Bills', 'Legislative bills from the U.S. Congress'),
('BILLSTATUS', 'Bill Status', 'Status information for congressional bills'),
('CREC', 'Congressional Record', 'Official record of congressional proceedings'),
('CFR', 'Code of Federal Regulations', 'Codification of federal regulations'),
('FR', 'Federal Register', 'Daily federal government publications'),
('PLAW', 'Public and Private Laws', 'Enacted legislation'),
('USCODE', 'United States Code', 'Codification of federal statutes'),
('STATUTE', 'United States Statutes at Large', 'Session laws'),
('CHRG', 'Congressional Hearings', 'Congressional hearing transcripts'),
('CDOC', 'Congressional Documents', 'Congressional committee documents'),
('CCAL', 'Congressional Calendars', 'Congressional schedule information'),
('CBO', 'Congressional Budget Office', 'CBO cost estimates and reports'),
('GAOR', 'GAO Reports', 'Government Accountability Office reports'),
('GPO', 'GPO Reports', 'Government Publishing Office reports'),
('GOVMAN', 'Government Manual', 'Official government organization manual'),
('ECFR', 'e-CFR', 'Electronic Code of Federal Regulations'),
('ECFR-CFRTITLE-', 'e-CFR Titles', 'Individual CFR titles'),
('ECFR-CFRTITLE-1', 'CFR Title 1', 'General Provisions'),
('ECFR-CFRTITLE-2', 'CFR Title 2', 'Grants and Agreements'),
('ECFR-CFRTITLE-3', 'CFR Title 3', 'The President'),
('ECFR-CFRTITLE-4', 'CFR Title 4', 'Accounts'),
('ECFR-CFRTITLE-5', 'CFR Title 5', 'Administrative Personnel'),
('ECFR-CFRTITLE-6', 'CFR Title 6', 'Domestic Security'),
('ECFR-CFRTITLE-7', 'CFR Title 7', 'Agriculture'),
('ECFR-CFRTITLE-8', 'CFR Title 8', 'Aliens and Nationality'),
('ECFR-CFRTITLE-9', 'CFR Title 9', 'Animals and Animal Products'),
('ECFR-CFRTITLE-10', 'CFR Title 10', 'Energy'),
('ECFR-CFRTITLE-11', 'CFR Title 11', 'Federal Elections'),
('ECFR-CFRTITLE-12', 'CFR Title 12', 'Banks and Banking'),
('ECFR-CFRTITLE-13', 'CFR Title 13', 'Business Credit and Assistance'),
('ECFR-CFRTITLE-14', 'CFR Title 14', 'Aeronautics and Space'),
('ECFR-CFRTITLE-15', 'CFR Title 15', 'Commerce and Foreign Trade'),
('ECFR-CFRTITLE-16', 'CFR Title 16', 'Commercial Practices'),
('ECFR-CFRTITLE-17', 'CFR Title 17', 'Commodity and Securities Exchanges'),
('ECFR-CFRTITLE-18', 'CFR Title 18', 'Conservation of Power and Water Resources'),
('ECFR-CFRTITLE-19', 'CFR Title 19', 'Customs Duties'),
('ECFR-CFRTITLE-20', 'CFR Title 20', 'Employees'' Benefits'),
('ECFR-CFRTITLE-21', 'CFR Title 21', 'Food and Drugs'),
('ECFR-CFRTITLE-22', 'CFR Title 22', 'Foreign Relations'),
('ECFR-CFRTITLE-23', 'CFR Title 23', 'Highways'),
('ECFR-CFRTITLE-24', 'CFR Title 24', 'Housing and Urban Development'),
('ECFR-CFRTITLE-25', 'CFR Title 25', 'Indians'),
('ECFR-CFRTITLE-26', 'CFR Title 26', 'Internal Revenue'),
('ECFR-CFRTITLE-27', 'CFR Title 27', 'Alcohol, Tobacco Products and Firearms'),
('ECFR-CFRTITLE-28', 'CFR Title 28', 'Judicial Administration'),
('ECFR-CFRTITLE-29', 'CFR Title 29', 'Labor'),
('ECFR-CFRTITLE-30', 'CFR Title 30', 'Mineral Resources'),
('ECFR-CFRTITLE-31', 'CFR Title 31', 'Money and Finance: Treasury'),
('ECFR-CFRTITLE-32', 'CFR Title 32', 'National Defense'),
('ECFR-CFRTITLE-33', 'CFR Title 33', 'Navigation and Navigable Waters'),
('ECFR-CFRTITLE-34', 'CFR Title 34', 'Education'),
('ECFR-CFRTITLE-35', 'CFR Title 35', 'Reserved'),
('ECFR-CFRTITLE-36', 'CFR Title 36', 'Parks, Forests, and Public Property'),
('ECFR-CFRTITLE-37', 'CFR Title 37', 'Patents, Trademarks, and Copyrights'),
('ECFR-CFRTITLE-38', 'CFR Title 38', 'Pensions, Bonuses, and Veterans'' Relief'),
('ECFR-CFRTITLE-39', 'CFR Title 39', 'Postal Service'),
('ECFR-CFRTITLE-40', 'CFR Title 40', 'Protection of Environment'),
('ECFR-CFRTITLE-41', 'CFR Title 41', 'Public Contracts and Property Management'),
('ECFR-CFRTITLE-42', 'CFR Title 42', 'Public Health'),
('ECFR-CFRTITLE-43', 'CFR Title 43', 'Public Lands: Interior'),
('ECFR-CFRTITLE-44', 'CFR Title 44', 'Emergency Management and Assistance'),
('ECFR-CFRTITLE-45', 'CFR Title 45', 'Public Welfare'),
('ECFR-CFRTITLE-46', 'CFR Title 46', 'Shipping'),
('ECFR-CFRTITLE-47', 'CFR Title 47', 'Telecommunication'),
('ECFR-CFRTITLE-48', 'CFR Title 48', 'Federal Acquisition Regulations System'),
('ECFR-CFRTITLE-49', 'CFR Title 49', 'Transportation'),
('ECFR-CFRTITLE-50', 'CFR Title 50', 'Wildlife and Fisheries')
ON CONFLICT (collection_code) DO NOTHING;

