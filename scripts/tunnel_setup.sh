#!/bin/bash

# SSH Tunnel Setup Script for Congress API Database Access
# This script helps set up SSH tunneling to connect to PostgreSQL database

set -e

echo "========================================"
echo "SSH Tunnel Setup for Congress API"
echo "========================================"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[i]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Get VM IP address
VM_IP=$(curl -s ifconfig.me)
if [ -z "$VM_IP" ]; then
    VM_IP=$(hostname -I | awk '{print $1}')
fi

print_info "Your VM IP address: $VM_IP"

# Check SSH service
if systemctl is-active --quiet ssh; then
    print_status "SSH service is running"
else
    print_error "SSH service is not running"
    print_info "Starting SSH service..."
    systemctl start ssh
    systemctl enable ssh
    print_status "SSH service started and enabled"
fi

# Check SSH port
if netstat -tln | grep -q ":22 "; then
    print_status "SSH is listening on port 22"
else
    print_error "SSH is not listening on port 22"
fi

# Generate SSH key pair if not exists
if [ ! -f "$HOME/.ssh/id_rsa" ]; then
    print_info "Generating SSH key pair..."
    ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/id_rsa" -N "" -C "congress-api-vm@$(hostname)"
    print_status "SSH key pair generated"
else
    print_status "SSH key pair already exists"
fi

# Display public key
print_info "Your SSH Public Key:"
echo ""
cat "$HOME/.ssh/id_rsa.pub"
echo ""

# Create tunnel setup instructions
cat > "$HOME/tunnel_instructions.txt" << 'INSTRUCTIONS'
========================================
SSH Tunnel Setup Instructions
========================================

ON YOUR COMPUTER (cbwhpz):

1. Add VM's SSH key to your computer:
   - Copy the public key above
   - Add it to ~/.ssh/authorized_keys on your computer

2. Create SSH tunnel:
   ssh -L 5433:localhost:5432 root@VM_IP_ADDRESS -N &

   Replace VM_IP_ADDRESS with: YOUR_VM_IP

3. Keep the tunnel running:
   - The tunnel will run in background
   - To stop: kill %1
   - To check: ps aux | grep ssh

4. Test PostgreSQL connection:
   psql -h localhost -p 5433 -U opendiscourse -d opendiscourse

ON THE VM:

1. Update config to use tunnel:
   Edit config/config.json:
   - Change host from "100.90.251.120" to "localhost"
   - Change port from 5432 to 5433
   - Set "use_postgresql": true

2. Test connection:
   python -c "
   import psycopg2
   try:
       conn = psycopg2.connect(
           host='localhost',
           port=5433,
           database='opendiscourse',
           user='opendiscourse',
           password='opendiscourse123'
       )
       print('✅ PostgreSQL connection successful!')
       conn.close()
   except Exception as e:
       print(f'❌ Connection failed: {e}')
   "

3. Start data ingestion:
   python main.py --ingest-collections

========================================
Troubleshooting:
========================================

- If connection refused: Check if PostgreSQL is running on your computer
- If authentication failed: Verify PostgreSQL user credentials
- If tunnel drops: Re-run the ssh command
- To check tunnel status: netstat -tln | grep 5433

========================================
INSTRUCTIONS

print_status "Tunnel setup instructions saved to: $HOME/tunnel_instructions.txt"

# Create automated tunnel test script
cat > "$HOME/scripts/test_tunnel.sh" << 'TESTEOF'
#!/bin/bash

# Test SSH Tunnel Connection

echo "Testing SSH tunnel connection..."

if netstat -tln | grep -q ":5433 "; then
    echo "✓ SSH tunnel is active (port 5433)"
    
    # Test PostgreSQL connection through tunnel
    if command -v psql &> /dev/null; then
        echo "Testing PostgreSQL connection..."
        if PGPASSWORD=opendiscourse123 psql -h localhost -p 5433 -U opendiscourse -d opendiscourse -c "SELECT 1;" > /dev/null 2>&1; then
            echo "✅ PostgreSQL connection successful through tunnel!"
            echo ""
            echo "Database Info:"
            PGPASSWORD=opendiscourse123 psql -h localhost -p 5433 -U opendiscourse -d opendiscourse -c "
            SELECT 
                'Tables: ' || count(*) as table_count
            FROM information_schema.tables 
            WHERE table_schema = 'public';
            "
        else
            echo "✗ PostgreSQL connection failed"
            echo "Make sure:"
            echo "  1. SSH tunnel is running on your computer"
            echo "  2. PostgreSQL is running on your computer"
            echo "  3. Credentials are correct"
        fi
    else
        echo "psql client not available, skipping database test"
    fi
else
    echo "✗ SSH tunnel not detected (port 5433 not listening)"
    echo ""
    echo "To set up the tunnel, run on your computer:"
    echo "  ssh -L 5433:localhost:5432 root@VM_IP_ADDRESS -N &"
    echo ""
    echo "Replace VM_IP_ADDRESS with your VM's IP"
fi
TESTEOF

chmod +x "$HOME/scripts/test_tunnel.sh"
print_status "Tunnel test script created"

echo ""
echo "========================================"
echo "Next Steps:"
echo "========================================"
echo "1. Copy the SSH public key above"
echo "2. Add it to ~/.ssh/authorized_keys on your computer"
echo "3. Run the SSH tunnel command on your computer:"
echo "   ssh -L 5433:localhost:5432 root@${VM_IP} -N &"
echo "4. Test the tunnel:"
echo "   bash $HOME/scripts/test_tunnel.sh"
echo "5. Update config and start ingesting data!"
echo "========================================"
