#!/bin/bash
# PostgreSQL Database Health Monitoring Script
# Monitors database health, performance, and ingestion status

set -e

# Database configuration
DB_HOST="100.90.251.120"
DB_PORT="5432"
DB_NAME="opendiscourse"
DB_USER="opendiscourse"
DB_PASSWORD="opendiscourse123"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== PostgreSQL Database Health Monitor ==="
echo ""

# Function to check connection
check_connection() {
    echo -e "${YELLOW}1. Database Connection:${NC}"
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✅ Connected${NC}"
        return 0
    else
        echo -e "  ${RED}❌ Connection failed${NC}"
        return 1
    fi
}

# Function to check table counts
check_table_counts() {
    echo -e "\n${YELLOW}2. Table Record Counts:${NC}"
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" << EOF
SELECT 
    'collections' as table_name, 
    COUNT(*) as record_count 
FROM collections
UNION ALL
SELECT 
    'packages', 
    COUNT(*) 
FROM packages
UNION ALL
SELECT 
    'bills', 
    COUNT(*) 
FROM bills
UNION ALL
SELECT 
    'legislators', 
    COUNT(*) 
FROM legislators
UNION ALL
SELECT 
    'votes', 
    COUNT(*) 
FROM votes
UNION ALL
SELECT 
    'ingestion_log', 
    COUNT(*) 
FROM ingestion_log
ORDER BY table_name;
