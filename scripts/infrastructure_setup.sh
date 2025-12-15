#!/bin/bash

# Congress API Infrastructure Setup Script
# This script sets up the complete infrastructure for Congress API data ingestion

set -e  # Exit on error

echo "========================================"
echo "Congress API Infrastructure Setup"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[i]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_status "Running as root"
else
    print_error "This script must be run as root"
    exit 1
fi

# Update system
print_info "Updating system packages..."
apt-get update -qq
apt-get upgrade -y -qq

# Install required packages
print_info "Installing required packages..."
apt-get install -y -qq \
    python3 \
    python3-pip \
    python3-venv \
    postgresql-client \
    sqlite3 \
    curl \
    wget \
    netcat \
    iperf3 \
    htop \
    tmux \
    git \
    ufw \
    fail2ban

print_status "System packages installed"

# Create project directory
PROJECT_DIR="/root/congress_api_project"
if [ ! -d "$PROJECT_DIR" ]; then
    mkdir -p "$PROJECT_DIR"
    print_status "Created project directory: $PROJECT_DIR"
else
    print_status "Project directory exists: $PROJECT_DIR"
fi

# Setup Python virtual environment
cd "$PROJECT_DIR"
if [ ! -d "venv" ]; then
    python3 -m venv venv
    print_status "Created Python virtual environment"
else
    print_status "Python virtual environment exists"
fi

# Activate virtual environment and install requirements
source venv/bin/activate
if [ -f "requirements.txt" ]; then
    pip install --upgrade pip -qq
    pip install -r requirements.txt -qq
    print_status "Python dependencies installed"
else
    print_error "requirements.txt not found"
fi

# Create necessary directories
mkdir -p "$PROJECT_DIR/data"
mkdir -p "$PROJECT_DIR/logs"
mkdir -p "$PROJECT_DIR/backups"
print_status "Created data, logs, and backups directories"

# Setup firewall (if not already configured)
print_info "Configuring firewall..."
if command -v ufw &> /dev/null; then
    ufw --force enable
    ufw allow 22/tcp  # SSH
    ufw allow 5432/tcp  # PostgreSQL
    ufw allow 8080/tcp  # Monitoring API (if needed)
    print_status "Firewall configured"
else
    print_error "UFW not available, skipping firewall setup"
fi

# Setup fail2ban
print_info "Configuring fail2ban..."
systemctl enable fail2ban
systemctl start fail2ban
print_status "Fail2ban configured"

# Create systemd service for automated ingestion
print_info "Creating systemd service..."
cat > /etc/systemd/system/congress-api.service << 'SERVICEEOF'
[Unit]
Description=Congress API Data Ingestion Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/congress_api_project
Environment=PATH=/root/congress_api_project/venv/bin
ExecStart=/root/congress_api_project/venv/bin/python main.py --ingest-collections
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICEEOF

systemctl daemon-reload
print_status "Systemd service created"

# Create backup cron job
print_info "Setting up automated backups..."
cat > /etc/cron.d/congress-api-backup << 'CRONEOF'
# Congress API Backup Cron Job
# Runs daily at 2 AM
0 2 * * * root /root/congress_api_project/venv/bin/python /root/congress_api_project/scripts/database_backup.py --backup >> /root/congress_api_project/logs/backup.log 2>&1
CRONEOF

print_status "Automated backup cron job created"

# Create monitoring script
cat > "$PROJECT_DIR/scripts/monitor_infrastructure.sh" << 'MONEOF'
#!/bin/bash

# Infrastructure Monitoring Script

echo "========================================"
echo "Infrastructure Status Report"
echo "========================================"

echo ""
echo "1. System Resources:"
echo "-------------------"
echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}'%)%"
echo "Memory Usage: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
echo "Disk Usage: $(df -h / | awk '/\// {print $3 "/" $2 " (" $5 " used)"}')"

echo ""
echo "2. Network Connectivity:"
echo "------------------------"
echo -n "Congress.gov API: "
if curl -s --connect-timeout 5 https://api.congress.gov/v3/ > /dev/null; then
    echo "✓ Reachable"
else
    echo "✗ Unreachable"
fi

echo -n "GovInfo API: "
if curl -s --connect-timeout 5 https://api.govinfo.gov/ > /dev/null; then
    echo "✓ Reachable"
else
    echo "✗ Unreachable"
fi

echo ""
echo "3. Database Status:"
echo "------------------"
if [ -f "/root/congress_api_project/data/congress_data.db" ]; then
    DB_SIZE=$(du -h /root/congress_api_project/data/congress_data.db | cut -f1)
    echo "SQLite Database: ✓ Exists ($DB_SIZE)"
else
    echo "SQLite Database: ✗ Not found"
fi

echo ""
echo "4. Service Status:"
echo "-----------------"
systemctl is-active --quiet congress-api && echo "Congress API Service: ✓ Running" || echo "Congress API Service: ✗ Stopped"
systemctl is-active --quiet fail2ban && echo "Fail2ban: ✓ Running" || echo "Fail2ban: ✗ Stopped"

echo ""
echo "5. Recent Log Entries:"
echo "----------------------"
if [ -f "/root/congress_api_project/logs/ingestion.log" ]; then
    tail -5 /root/congress_api_project/logs/ingestion.log
else
    echo "No log file found"
fi

echo "========================================"
MONEOF

chmod +x "$PROJECT_DIR/scripts/monitor_infrastructure.sh"
print_status "Monitoring script created"

# Network speed test
print_info "Running network speed test..."
cat > "$PROJECT_DIR/scripts/network_test.sh" << 'NETEOF'
#!/bin/bash

# Network Speed Test Script

echo "========================================"
echo "Network Speed Test"
echo "========================================"

echo ""
echo "1. Internet Speed Test:"
echo "------------------------"
if command -v iperf3 &> /dev/null; then
    echo "Testing bandwidth (this may take a minute)..."
    iperf3 -c speedtest.wdc1.us.leaseweb.net -p 5201 -t 10 -J | python3 -c "
import sys, json
data = json.load(sys.stdin)
if 'end' in data:
    sent = data['end']['sum_sent']
    received = data['end']['sum_received']
    print(f'Send: {sent["bits_per_second"]/1e6:.2f} Mbps')
    print(f'Receive: {received["bits_per_second"]/1e6:.2f} Mbps')
else:
    print('Speed test failed')
"
else
    echo "iperf3 not available, skipping speed test"
fi

echo ""
echo "2. API Response Time Test:"
echo "----------------------------"
echo -n "Congress.gov API: "
time (curl -s https://api.congress.gov/v3/ > /dev/null) 2>&1 | grep real
echo -n "GovInfo API: "
time (curl -s https://api.govinfo.gov/ > /dev/null) 2>&1 | grep real

echo ""
echo "3. Database Connection Test:"
echo "-------------------------------"
echo "Testing PostgreSQL connection..."
if command -v psql &> /dev/null; then
    PGPASSWORD=opendiscourse123 psql -h localhost -p 5432 -U opendiscourse -d opendiscourse -c "SELECT 1;" > /dev/null 2>&1 && echo "✓ PostgreSQL: Connected" || echo "✗ PostgreSQL: Connection failed"
else
    echo "psql client not available"
fi

echo "Testing SQLite database..."
if [ -f "/root/congress_api_project/data/congress_data.db" ]; then
    sqlite3 /root/congress_api_project/data/congress_data.db "SELECT 1;" > /dev/null 2>&1 && echo "✓ SQLite: Connected" || echo "✗ SQLite: Connection failed"
else
    echo "✗ SQLite: Database file not found"
fi

echo "========================================"
NETEOF

chmod +x "$PROJECT_DIR/scripts/network_test.sh"
print_status "Network test script created"

# Run initial tests
print_info "Running initial tests..."
cd "$PROJECT_DIR"
bash scripts/network_test.sh

print_status "Infrastructure setup complete!"

echo ""
echo "========================================"
echo "Setup Summary"
echo "========================================"
echo "Project Directory: $PROJECT_DIR"
echo "Virtual Environment: $PROJECT_DIR/venv"
echo "Data Directory: $PROJECT_DIR/data"
echo "Logs Directory: $PROJECT_DIR/logs"
echo "Backups Directory: $PROJECT_DIR/backups"
echo ""
echo "Available Commands:"
echo "  - Monitor: $PROJECT_DIR/scripts/monitor_infrastructure.sh"
echo "  - Network Test: $PROJECT_DIR/scripts/network_test.sh"
echo "  - Backup: python scripts/database_backup.py --backup"
echo "  - Ingest: python main.py --ingest-collections"
echo "  - Stats: python main.py --stats"
echo ""
echo "Service Management:"
echo "  - Start: systemctl start congress-api"
echo "  - Stop: systemctl stop congress-api"
echo "  - Status: systemctl status congress-api"
echo "  - Logs: journalctl -u congress-api -f"
echo "========================================"
