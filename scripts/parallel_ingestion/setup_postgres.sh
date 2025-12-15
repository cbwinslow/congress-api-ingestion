#!/bin/bash

# Comprehensive PostgreSQL Setup Script for Congress Data Ingestion
# This script sets up PostgreSQL and runs the parallel ingestion system

set -e

echo "========================================"
echo "PostgreSQL Congress Data Setup"
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

print_info() {
    echo -e "${YELLOW}[i]${NC} $1"
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    print_error "This script must be run as root"
    exit 1
fi

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    print_info "PostgreSQL not found, installing..."
    
    # Install PostgreSQL
    apt-get update
    apt-get install -y postgresql postgresql-contrib
    
    print_status "PostgreSQL installed"
else
    print_status "PostgreSQL already installed"
fi

# Start PostgreSQL service
if ! pg_isready &> /dev/null; then
    print_info "Starting PostgreSQL..."
    
    # Try different methods to start PostgreSQL
    if command -v systemctl &> /dev/null; then
        systemctl start postgresql
    elif command -v service &> /dev/null; then
        service postgresql start
    else
        # Manual start for Docker/container environments
        sudo -u postgres /usr/lib/postgresql/*/bin/postgres -D /var/lib/postgresql/*/main & 
        sleep 5
    fi
    
    print_status "PostgreSQL started"
else
    print_status "PostgreSQL already running"
fi

# Create database and user
print_info "Creating database and user..."

sudo -u postgres psql << 'POSTGRESQL'
-- Create database
CREATE DATABASE opendiscourse;

-- Create user
CREATE USER opendiscourse WITH PASSWORD 'opendiscourse123';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE opendiscourse TO opendiscourse;
POSTGRESQL

print_status "Database and user created"

# Apply schema
print_info "Applying Congress data schema..."

# Check if schema file exists
if [ -f "create_postgres_schema.sql" ]; then
    sudo -u postgres psql -d opendiscourse -f create_postgres_schema.sql
    print_status "Schema applied"
else
    print_error "Schema file not found: create_postgres_schema.sql"
    print_info "Please download the schema file from the repository"
fi

# Test connection
print_info "Testing database connection..."

if sudo -u postgres psql -d opendiscourse -c "SELECT 1;" &> /dev/null; then
    print_status "Database connection successful"
else
    print_error "Database connection failed"
    exit 1
fi

# Install Python requirements
print_info "Installing Python requirements..."

if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
    print_status "Python requirements installed"
else
    print_warning "requirements.txt not found, installing basic requirements"
    pip install psycopg2-binary requests
fi

# Create configuration
print_info "Creating configuration..."

cat > config.json << 'CONFIG'
{
  "congress_api": {
    "base_url": "https://api.congress.gov/v3",
    "api_key": "U71JFZEqNsiSranCdbrj4pZaobtoMtAnl18cIJc2"
  },
  "database": {
    "postgresql": {
      "database": "opendiscourse",
      "user": "opendiscourse",
      "password": "opendiscourse123",
      "host": "localhost",
      "port": 5432
    }
  },
  "ingestion_settings": {
    "workers": 4,
    "rate_limit": 1000,
    "batch_size": 50,
    "max_retries": 3,
    "timeout": 30
  }
}
CONFIG

print_status "Configuration created"

echo ""
echo "========================================"
echo "Setup Complete!"
echo "========================================"
echo ""
echo "🚀 Ready to ingest Congress data!"
echo ""
echo "To start ingestion, run:"
echo "  python parallel_ingestor.py"
echo ""
echo "Or run specific ingestion tasks:"
echo "  python parallel_ingestor.py --bills 118 hr 100"
echo "  python parallel_ingestor.py --legislators current"
echo "  python parallel_ingestor.py --votes 118 2024"
echo ""
echo "Database credentials:"
echo "  Host: localhost"
echo "  Port: 5432"
echo "  Database: opendiscourse"
echo "  User: opendiscourse"
echo "  Password: opendiscourse123"
echo ""
echo "📚 Documentation: See README.md for detailed usage"
echo ""
