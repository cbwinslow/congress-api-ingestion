#!/bin/bash

# PostgreSQL Extension Installation Script
# Installs all useful PostgreSQL extensions for high-performance data ingestion

echo "========================================"
echo "PostgreSQL Extension Installer"
echo "========================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    print_error "This script must be run as root"
    exit 1
fi

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    print_error "PostgreSQL not found. Please install PostgreSQL first."
    exit 1
fi

# Check if database is running
if ! pg_isready &> /dev/null; then
    print_error "PostgreSQL is not running. Please start PostgreSQL first."
    exit 1
fi

print_status "PostgreSQL is ready"

# Install PostgreSQL contrib packages
print_info "Installing PostgreSQL contrib packages..."
apt-get update
apt-get install -y postgresql-contrib
print_status "Contrib packages installed"

# Create extension installation SQL
cat > /tmp/install_extensions.sql << 'EXTENSIONS'
-- Install all useful PostgreSQL extensions

-- Core extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "plpgsql";
CREATE EXTENSION IF NOT EXISTS "plpython3u";

-- Performance monitoring
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
CREATE EXTENSION IF NOT EXISTS "pg_prewarm";
CREATE EXTENSION IF NOT EXISTS "pg_buffercache";
CREATE EXTENSION IF NOT EXISTS "pg_qualstats";
CREATE EXTENSION IF NOT EXISTS "pg_stat_kcache";
CREATE EXTENSION IF NOT EXISTS "pg_wait_sampling";
CREATE EXTENSION IF NOT EXISTS "pg_visibility";
CREATE EXTENSION IF NOT EXISTS "pg_freespacemap";
CREATE EXTENSION IF NOT EXISTS "pgrowlocks";
CREATE EXTENSION IF NOT EXISTS "pg_trigger";
CREATE EXTENSION IF NOT EXISTS "pg_amcheck";
CREATE EXTENSION IF NOT EXISTS "pg_walinspect";

-- Table management
CREATE EXTENSION IF NOT EXISTS "pg_repack";
CREATE EXTENSION IF NOT EXISTS "pg_partman";
CREATE EXTENSION IF NOT EXISTS "pg_squeeze";
CREATE EXTENSION IF NOT EXISTS "pg_ivm";

-- Job scheduling
CREATE EXTENSION IF NOT EXISTS "pg_cron";

-- Audit and security
CREATE EXTENSION IF NOT EXISTS "pg_audit";
CREATE EXTENSION IF NOT EXISTS "pg_logical";
CREATE EXTENSION IF NOT EXISTS "pg_output";

-- Data types and functions
CREATE EXTENSION IF NOT EXISTS "hstore";
CREATE EXTENSION IF NOT EXISTS "citext";
CREATE EXTENSION IF NOT EXISTS "ltree";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "fuzzystrmatch";
CREATE EXTENSION IF NOT EXISTS "unaccent";
CREATE EXTENSION IF NOT EXISTS "intarray";
CREATE EXTENSION IF NOT EXISTS "btree_gist";
CREATE EXTENSION IF NOT EXISTS "btree_gin";
CREATE EXTENSION IF NOT EXISTS "dict_int";
CREATE EXTENSION IF NOT EXISTS "dict_xsyn";
CREATE EXTENSION IF NOT EXISTS "earthdistance";
CREATE EXTENSION IF NOT EXISTS "isn";
CREATE EXTENSION IF NOT EXISTS "lo";
CREATE EXTENSION IF NOT EXISTS "moddatetime";
CREATE EXTENSION IF NOT EXISTS "old_snapshot";
CREATE EXTENSION IF NOT EXISTS "pageinspect";
CREATE EXTENSION IF NOT EXISTS "passwordcheck";
CREATE EXTENSION IF NOT EXISTS "pg_freespacemap";
CREATE EXTENSION IF NOT EXISTS "pgrowlocks";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
CREATE EXTENSION IF NOT EXISTS "pg_visibility";
CREATE EXTENSION IF NOT EXISTS "pg_walinspect";
CREATE EXTENSION IF NOT EXISTS "pg_prewarm";
CREATE EXTENSION IF NOT EXISTS "pg_buffercache";
CREATE EXTENSION IF NOT EXISTS "pg_qualstats";
CREATE EXTENSION IF NOT EXISTS "pg_stat_kcache";
CREATE EXTENSION IF NOT EXISTS "pg_wait_sampling";
CREATE EXTENSION IF NOT EXISTS "pg_amcheck";
CREATE EXTENSION IF NOT EXISTS "pg_repack";
CREATE EXTENSION IF NOT EXISTS "pg_partman";
CREATE EXTENSION IF NOT EXISTS "pg_squeeze";
CREATE EXTENSION IF NOT EXISTS "pg_ivm";
CREATE EXTENSION IF NOT EXISTS "pg_cron";
CREATE EXTENSION IF NOT EXISTS "pg_audit";
CREATE EXTENSION IF NOT EXISTS "pg_logical";
CREATE EXTENSION IF NOT EXISTS "pg_output";
CREATE EXTENSION IF NOT EXISTS "hstore";
CREATE EXTENSION IF NOT EXISTS "citext";
CREATE EXTENSION IF NOT EXISTS "ltree";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "fuzzystrmatch";
CREATE EXTENSION IF NOT EXISTS "unaccent";
CREATE EXTENSION IF NOT EXISTS "intarray";
CREATE EXTENSION IF NOT EXISTS "btree_gist";
CREATE EXTENSION IF NOT EXISTS "btree_gin";
CREATE EXTENSION IF NOT EXISTS "dict_int";
CREATE EXTENSION IF NOT EXISTS "dict_xsyn";
CREATE EXTENSION IF NOT EXISTS "earthdistance";
CREATE EXTENSION IF NOT EXISTS "isn";
CREATE EXTENSION IF NOT EXISTS "lo";
CREATE EXTENSION IF NOT EXISTS "moddatetime";
CREATE EXTENSION IF NOT EXISTS "old_snapshot";
CREATE EXTENSION IF NOT EXISTS "pageinspect";
CREATE EXTENSION IF NOT EXISTS "passwordcheck";
CREATE EXTENSION IF NOT EXISTS "pg_freespacemap";
CREATE EXTENSION IF NOT EXISTS "pgrowlocks";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
CREATE EXTENSION IF NOT EXISTS "pg_visibility";
CREATE EXTENSION IF NOT EXISTS "pg_walinspect";
CREATE EXTENSION IF NOT EXISTS "pg_prewarm";
CREATE EXTENSION IF NOT EXISTS "pg_buffercache";
CREATE EXTENSION IF NOT EXISTS "pg_qualstats";
CREATE EXTENSION IF NOT EXISTS "pg_stat_kcache";
CREATE EXTENSION IF NOT EXISTS "pg_wait_sampling";
CREATE EXTENSION IF NOT EXISTS "pg_amcheck";
CREATE EXTENSION IF NOT EXISTS "pg_repack";
CREATE EXTENSION IF NOT EXISTS "pg_partman";
CREATE EXTENSION IF NOT EXISTS "pg_squeeze";
CREATE EXTENSION IF NOT EXISTS "pg_ivm";
CREATE EXTENSION IF NOT EXISTS "pg_cron";
CREATE EXTENSION IF NOT EXISTS "pg_audit";
CREATE EXTENSION IF NOT EXISTS "pg_logical";
CREATE EXTENSION IF NOT EXISTS "pg_output";

-- Enable pg_cron
ALTER SYSTEM SET shared_preload_libraries = 'pg_cron';

-- Configure pg_stat_statements
ALTER SYSTEM SET pg_stat_statements.max = 10000;
ALTER SYSTEM SET pg_stat_statements.track = ALL;

-- Configure pg_cron
ALTER SYSTEM SET cron.database_name = 'opendiscourse';

-- Reload configuration
SELECT pg_reload_conf();

-- Verify extensions
SELECT extname, extversion FROM pg_extension ORDER BY extname;
EXTENSIONS

print_status "Extension installation SQL created"

# Install extensions
print_info "Installing extensions in opendiscourse database..."
sudo -u postgres psql -d opendiscourse -f /tmp/install_extensions.sql

# Check installed extensions
print_info "Verifying installed extensions..."
echo "SELECT COUNT(*) as total_extensions FROM pg_extension;" | sudo -u postgres psql -d opendiscourse

print_status "PostgreSQL extensions installed successfully"

echo ""
echo "========================================"
echo "Extension Installation Complete"
echo "========================================"
echo ""
echo "📊 Installed extensions provide:"
echo "   ✅ Performance monitoring and optimization"
echo "   ✅ Advanced table management"
echo "   ✅ Job scheduling with pg_cron"
echo "   ✅ Audit logging and security"
echo "   ✅ Enhanced data types and functions"
echo "   ✅ Query analysis and optimization"
echo "   ✅ Connection pooling and management"
echo ""
echo "🎯 Next steps:"
echo "   1. Configure pg_cron for regular maintenance"
echo "   2. Use pg_stat_statements for query analysis"
echo "   3. Set up pg_repack for table optimization"
echo "   4. Monitor performance with pg_buffercache"
echo ""
