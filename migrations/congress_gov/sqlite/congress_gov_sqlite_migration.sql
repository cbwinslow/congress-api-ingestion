-- Congress.gov SQLite Migration Script
-- Comprehensive schema for Congress.gov API data
-- Version: 1.0.0
-- Date: 2025-12-15

-- Enable SQLite extensions
PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA temp_store = MEMORY;
PRAGMA cache_size = -20000; -- 20MB cache

-- Bills table
CREATE TABLE IF NOT EXISTS bills (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    bill_id TEXT UNIQUE NOT NULL,
    congress_number INTEGER NOT NULL,
    bill_type TEXT NOT NULL,
    bill_number TEXT NOT NULL,
    title TEXT NOT NULL,
    short_title TEXT,
    official_title TEXT,
    summary TEXT,
    sponsor_id TEXT,
    sponsor_name TEXT,
    sponsor_state TEXT,
    sponsor_party TEXT,
    introduced_date TIMESTAMP,
    last_action_date TIMESTAMP,
    last_action TEXT,
    status TEXT,
    url TEXT,
    pdf_url TEXT,
    text_url TEXT,
    metadata TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_bills_congress CHECK (congress_number BETWEEN 1 AND 200)
);

-- Bills index
CREATE INDEX IF NOT EXISTS idx_bills_congress ON bills(congress_number);
CREATE INDEX IF NOT EXISTS idx_bills_type ON bills(bill_type);
CREATE INDEX IF NOT EXISTS idx_bills_status ON bills(status);
CREATE INDEX IF NOT EXISTS idx_bills_date ON bills(introduced_date);

-- Legislators table
CREATE TABLE IF NOT EXISTS legislators (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    bioguide_id TEXT UNIQUE NOT NULL,
    govtrack_id TEXT,
    crp_id TEXT,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    middle_name TEXT,
    name_suffix TEXT,
    nickname TEXT,
    full_name TEXT NOT NULL,
    birth_date DATE,
    gender TEXT,
    party TEXT,
    state TEXT,
    district TEXT,
    in_office INTEGER,
    start_date DATE,
    end_date DATE,
    office TEXT,
    phone TEXT,
    fax TEXT,
    website TEXT,
    contact_form TEXT,
    twitter TEXT,
    facebook TEXT,
    youtube TEXT,
    metadata TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Legislators index
CREATE INDEX IF NOT EXISTS idx_legislators_state ON legislators(state);
CREATE INDEX IF NOT EXISTS idx_legislators_party ON legislators(party);
CREATE INDEX IF NOT EXISTS idx_legislators_in_office ON legislators(in_office);
CREATE INDEX IF NOT EXISTS idx_legislators_name ON legislators(full_name);

-- Committees table
CREATE TABLE IF NOT EXISTS committees (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    committee_id TEXT UNIQUE NOT NULL,
    congress_number INTEGER NOT NULL,
    chamber TEXT NOT NULL,
    name TEXT NOT NULL,
    full_name TEXT,
    url TEXT,
    subcommittee INTEGER DEFAULT 0,
    parent_committee_id TEXT,
    metadata TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Committees index
CREATE INDEX IF NOT EXISTS idx_committees_congress ON committees(congress_number);
CREATE INDEX IF NOT EXISTS idx_committees_chamber ON committees(chamber);
CREATE INDEX IF NOT EXISTS idx_committees_subcommittee ON committees(subcommittee);

-- Votes table
CREATE TABLE IF NOT EXISTS votes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    vote_id TEXT UNIQUE NOT NULL,
    congress_number INTEGER NOT NULL,
    chamber TEXT NOT NULL,
    session_number INTEGER NOT NULL,
    roll_call_number INTEGER NOT NULL,
    bill_number TEXT,
    question TEXT NOT NULL,
    description TEXT,
    vote_date TIMESTAMP NOT NULL,
    vote_time TIMESTAMP,
    result TEXT,
    required_members INTEGER,
    present_members INTEGER,
    yes_votes INTEGER,
    no_votes INTEGER,
    present_votes INTEGER,
    not_voting INTEGER,
    metadata TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Votes index
CREATE INDEX IF NOT EXISTS idx_votes_congress ON votes(congress_number);
CREATE INDEX IF NOT EXISTS idx_votes_chamber ON votes(chamber);
CREATE INDEX IF NOT EXISTS idx_votes_date ON votes(vote_date);
CREATE INDEX IF NOT EXISTS idx_votes_result ON votes(result);

-- Vote results table
CREATE TABLE IF NOT EXISTS vote_results (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    vote_id TEXT NOT NULL,
    legislator_id TEXT NOT NULL,
    vote_position TEXT NOT NULL,
    vote_value TEXT,
    metadata TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vote_id) REFERENCES votes(vote_id) ON DELETE CASCADE,
    FOREIGN KEY (legislator_id) REFERENCES legislators(bioguide_id) ON DELETE CASCADE
);

-- Vote results index
CREATE INDEX IF NOT EXISTS idx_vote_results_vote ON vote_results(vote_id);
CREATE INDEX IF NOT EXISTS idx_vote_results_legislator ON vote_results(legislator_id);
CREATE INDEX IF NOT EXISTS idx_vote_results_position ON vote_results(vote_position);

-- Amendments table
CREATE TABLE IF NOT EXISTS amendments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    amendment_id TEXT UNIQUE NOT NULL,
    congress_number INTEGER NOT NULL,
    chamber TEXT NOT NULL,
    amendment_number TEXT NOT NULL,
    bill_number TEXT,
    sponsor_id TEXT,
    sponsor_name TEXT,
    sponsor_state TEXT,
    sponsor_party TEXT,
    introduced_date TIMESTAMP,
    purpose TEXT,
    description TEXT,
    status TEXT,
    url TEXT,
    metadata TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Amendments index
CREATE INDEX IF NOT EXISTS idx_amendments_congress ON amendments(congress_number);
CREATE INDEX IF NOT EXISTS idx_amendments_chamber ON amendments(chamber);
CREATE INDEX IF NOT EXISTS idx_amendments_bill ON amendments(bill_number);
CREATE INDEX IF NOT EXISTS idx_amendments_date ON amendments(introduced_date);

-- Hearings table
CREATE TABLE IF NOT EXISTS hearings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    hearing_id TEXT UNIQUE NOT NULL,
    congress_number INTEGER NOT NULL,
    chamber TEXT NOT NULL,
    committee_id TEXT,
    committee_name TEXT,
    hearing_type TEXT,
    title TEXT NOT NULL,
    date TIMESTAMP NOT NULL,
    time TIMESTAMP,
    location TEXT,
    url TEXT,
    video_url TEXT,
    metadata TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Hearings index
CREATE INDEX IF NOT EXISTS idx_hearings_congress ON hearings(congress_number);
CREATE INDEX IF NOT EXISTS idx_hearings_chamber ON hearings(chamber);
CREATE INDEX IF NOT EXISTS idx_hearings_committee ON hearings(committee_id);
CREATE INDEX IF NOT EXISTS idx_hearings_date ON hearings(date);

-- Committee memberships table
CREATE TABLE IF NOT EXISTS committee_memberships (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    committee_id TEXT NOT NULL,
    legislator_id TEXT NOT NULL,
    congress_number INTEGER NOT NULL,
    chamber TEXT NOT NULL,
    role TEXT,
    start_date DATE,
    end_date DATE,
    metadata TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (committee_id) REFERENCES committees(committee_id) ON DELETE CASCADE,
    FOREIGN KEY (legislator_id) REFERENCES legislators(bioguide_id) ON DELETE CASCADE
);

-- Committee memberships index
CREATE INDEX IF NOT EXISTS idx_memberships_committee ON committee_memberships(committee_id);
CREATE INDEX IF NOT EXISTS idx_memberships_legislator ON committee_memberships(legislator_id);
CREATE INDEX IF NOT EXISTS idx_memberships_congress ON committee_memberships(congress_number);

-- Bill sponsors table
CREATE TABLE IF NOT EXISTS bill_sponsors (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    bill_id TEXT NOT NULL,
    legislator_id TEXT NOT NULL,
    sponsor_type TEXT NOT NULL,
    sponsor_order INTEGER,
    date TIMESTAMP,
    metadata TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (bill_id) REFERENCES bills(bill_id) ON DELETE CASCADE,
    FOREIGN KEY (legislator_id) REFERENCES legislators(bioguide_id) ON DELETE CASCADE
);

-- Bill sponsors index
CREATE INDEX IF NOT EXISTS idx_sponsors_bill ON bill_sponsors(bill_id);
CREATE INDEX IF NOT EXISTS idx_sponsors_legislator ON bill_sponsors(legislator_id);
CREATE INDEX IF NOT EXISTS idx_sponsors_type ON bill_sponsors(sponsor_type);

-- Bill subjects table
CREATE TABLE IF NOT EXISTS bill_subjects (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    bill_id TEXT NOT NULL,
    subject TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (bill_id) REFERENCES bills(bill_id) ON DELETE CASCADE
);

-- Bill subjects index
CREATE INDEX IF NOT EXISTS idx_subjects_bill ON bill_subjects(bill_id);
CREATE INDEX IF NOT EXISTS idx_subjects_subject ON bill_subjects(subject);

-- Bill actions table
CREATE TABLE IF NOT EXISTS bill_actions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    bill_id TEXT NOT NULL,
    action_date TIMESTAMP NOT NULL,
    action_type TEXT NOT NULL,
    action_text TEXT NOT NULL,
    chamber TEXT,
    metadata TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (bill_id) REFERENCES bills(bill_id) ON DELETE CASCADE
);

-- Bill actions index
CREATE INDEX IF NOT EXISTS idx_actions_bill ON bill_actions(bill_id);
CREATE INDEX IF NOT EXISTS idx_actions_date ON bill_actions(action_date);
CREATE INDEX IF NOT EXISTS idx_actions_type ON bill_actions(action_type);

-- Ingestion log table
CREATE TABLE IF NOT EXISTS ingestion_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ingestion_type TEXT NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    records_processed INTEGER DEFAULT 0,
    records_success INTEGER DEFAULT 0,
    records_failed INTEGER DEFAULT 0,
    status TEXT DEFAULT 'running',
    error_message TEXT,
    metadata TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Ingestion log index
CREATE INDEX IF NOT EXISTS idx_ingestion_type ON ingestion_log(ingestion_type);
CREATE INDEX IF NOT EXISTS idx_ingestion_status ON ingestion_log(status);
CREATE INDEX IF NOT EXISTS idx_ingestion_time ON ingestion_log(start_time);

-- Schema version table
CREATE TABLE IF NOT EXISTS schema_versions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    version TEXT UNIQUE NOT NULL,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description TEXT
);

-- Insert schema version
INSERT INTO schema_versions (version, description)
VALUES ('1.0.0', 'Initial Congress.gov SQLite schema with comprehensive data model')
ON CONFLICT(version) DO NOTHING;

-- Create triggers for automatic timestamp updates
CREATE TRIGGER IF NOT EXISTS update_bills_timestamp
AFTER UPDATE ON bills
FOR EACH ROW
BEGIN
    UPDATE bills SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_legislators_timestamp
AFTER UPDATE ON legislators
FOR EACH ROW
BEGIN
    UPDATE legislators SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_committees_timestamp
AFTER UPDATE ON committees
FOR EACH ROW
BEGIN
    UPDATE committees SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_votes_timestamp
AFTER UPDATE ON votes
FOR EACH ROW
BEGIN
    UPDATE votes SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_amendments_timestamp
AFTER UPDATE ON amendments
FOR EACH ROW
BEGIN
    UPDATE amendments SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_hearings_timestamp
AFTER UPDATE ON hearings
FOR EACH ROW
BEGIN
    UPDATE hearings SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_ingestion_log_timestamp
AFTER UPDATE ON ingestion_log
FOR EACH ROW
BEGIN
    UPDATE ingestion_log SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

-- Create views for common queries
CREATE VIEW IF NOT EXISTS bill_sponsors_view AS
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
FROM bills b
JOIN bill_sponsors bs ON b.bill_id = bs.bill_id
JOIN legislators l ON bs.legislator_id = l.bioguide_id
ORDER BY b.congress_number DESC, bs.sponsor_order;

CREATE VIEW IF NOT EXISTS vote_summary_view AS
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
FROM votes v
LEFT JOIN vote_results vr ON v.vote_id = vr.vote_id
GROUP BY v.vote_id, v.congress_number, v.chamber, v.vote_date, v.question, v.result
ORDER BY v.vote_date DESC;

-- Create indexes for views
CREATE INDEX IF NOT EXISTS idx_bill_sponsors_view_bill ON bill_sponsors_view(bill_id);
CREATE INDEX IF NOT EXISTS idx_vote_summary_view_vote ON vote_summary_view(vote_id);

-- Migration complete
COMMENT ON DATABASE congress_api IS 'Congress.gov API data - SQLite Version 1.0.0';
