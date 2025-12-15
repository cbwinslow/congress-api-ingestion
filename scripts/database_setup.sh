#!/bin/bash
# PostgreSQL Database Setup Script
# Connects to opendiscourse database and applies migrations

set -e

# Database configuration
DB_HOST="100.90.251.120"  # Netbird IP from memories
DB_PORT="5432"
DB_NAME="opendiscourse"
DB_USER="opendiscourse"
DB_PASSWORD="opendiscourse123"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== PostgreSQL Database Setup ===${NC}"

# Function to test database connection
 test_connection() {
    echo -e "${YELLOW}Testing database connection...${NC}"
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT version();" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Database connection successful!${NC}"
        return 0
    else
        echo -e "${RED}❌ Database connection failed${NC}"
        echo -e "${YELLOW}Please ensure:${NC}"
        echo "  1. PostgreSQL is running on $DB_HOST"
        echo "  2. Firewall allows connections on port $DB_PORT"
        echo "  3. User '$DB_USER' has access to database '$DB_NAME'"
        echo "  4. Netbird is connected (if using VPN)"
        return 1
    fi
}

# Function to apply migrations
apply_migrations() {
    echo -e "${YELLOW}Applying database migrations...${NC}"
    
    if [ ! -f "../migrations/001_initial_schema.sql" ]; then
        echo -e "${RED}❌ Migration file not found${NC}"
        return 1
    fi
    
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "../migrations/001_initial_schema.sql"; then
        echo -e "${GREEN}✅ Migrations applied successfully!${NC}"
        return 0
    else
        echo -e "${RED}❌ Migration failed${NC}"
        return 1
    fi
}

# Function to show database info
show_db_info() {
    echo -e "${YELLOW}Database Information:${NC}"
    echo "  Host: $DB_HOST"
    echo "  Port: $DB_PORT"
    echo "  Database: $DB_NAME"
    echo "  User: $DB_USER"
    echo ""
}

# Function to show table counts
show_table_counts() {
    echo -e "${YELLOW}Table Record Counts:${NC}"
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" << EOF
SELECT 
    schemaname,
    tablename,
    attname AS rows
FROM pg_stats 
WHERE schemaname = 'public' 
    AND tablename IN ('collections', 'packages', 'bills', 'legislators', 'committees', 'votes')
ORDER BY tablename;
