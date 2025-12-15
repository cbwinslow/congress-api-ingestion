#!/bin/bash

# SSH Connection Diagnostic Script
# This script diagnoses SSH connection issues between user's computer and VM

echo "========================================"
echo "SSH Connection Diagnostic Report"
echo "========================================"
echo "Generated: $(date)"
echo ""

# Get VM IP address
VM_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

echo "## 1. VM Network Information"
echo "----------------------------"
echo "VM Public IP: $VM_IP"
echo "VM Hostname: $(hostname)"
echo ""

# Check SSH daemon status
echo "## 2. SSH Daemon Status"
echo "------------------------"
if ps aux | grep -q "[s]shd:"; then
    echo "[✓] SSH daemon is running"
    ps aux | grep "[s]shd:" | head -5
else
    echo "[✗] SSH daemon is NOT running"
fi
echo ""

# Check SSH listening ports
echo "## 3. SSH Listening Ports"
echo "--------------------------"
if command -v netstat &> /dev/null; then
    netstat -tlnp | grep sshd 2>/dev/null || echo "No SSH ports found with netstat"
else
    echo "netstat not available, checking with lsof..."
    lsof -i :22,2222 2>/dev/null || echo "No SSH ports found"
fi
echo ""

# Check SSH configuration
echo "## 4. SSH Configuration"
echo "------------------------"
if [ -f "/etc/ssh/sshd_config" ]; then
    echo "[✓] SSH config file exists"
    echo ""
    echo "Key settings:"
    grep -E "^(Port|PermitRootLogin|PasswordAuthentication|PubkeyAuthentication)" /etc/ssh/sshd_config 2>/dev/null || echo "No key settings found"
else
    echo "[✗] SSH config file not found"
fi
echo ""

# Check SSH keys
echo "## 5. SSH Keys"
echo "---------------"
if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
    echo "[✓] SSH public key exists"
    echo "Public key content:"
    cat $HOME/.ssh/id_ed25519.pub
else
    echo "[⚠] SSH public key not found"
fi
echo ""

# Check Docker environment
echo "## 6. Docker Environment Check"
echo "--------------------------------"
if [ -f "/.dockerenv" ]; then
    echo "[⚠] Running inside Docker container"
    echo ""
    echo "Docker-specific issues:"
    echo "  1. SSH ports may not be exposed to host"
    echo "  2. Container networking may be restricted"
    echo "  3. Need to map ports: -p 2222:2222"
    echo ""
    echo "To fix: Run container with port mapping"
    echo "  docker run -p 2222:22 ..."
    echo "  docker run -p 2222:2222 ..."
else
    echo "[✓] Not running in Docker (or privileged container)"
fi
echo ""

# Generate diagnostic summary
echo "## 7. Diagnostic Summary"
echo "----------------------------"
echo ""
echo "### Most Likely Issues:"
echo ""

ISSUE_COUNT=0

if ! ps aux | grep -q "[s]shd:"; then
    ISSUE_COUNT=$((ISSUE_COUNT + 1))
    echo "${ISSUE_COUNT}. SSH daemon is not running"
    echo "   Solution: Start SSH with '/usr/sbin/sshd -D &'"
    echo ""
fi

if [ -f "/.dockerenv" ]; then
    ISSUE_COUNT=$((ISSUE_COUNT + 1))
    echo "${ISSUE_COUNT}. Running in Docker container without port exposure"
    echo "   Solution: Run container with '-p 2222:2222' or '-p 22:22'"
    echo "   Example: docker run -p 2222:22 ..."
    echo ""
fi

echo "### Recommended Next Steps:"
echo ""
echo "1. Test port accessibility from your computer:"
echo "   nc -zv $VM_IP 22"
echo "   nc -zv $VM_IP 2222"
echo ""
echo "2. If ports are accessible, test SSH connection:"
echo "   ssh -v root@$VM_IP -p 2222"
echo ""
echo "3. If connection works, set up tunnel:"
echo "   ssh -L 5433:localhost:5432 root@$VM_IP -p 2222 -N &"
echo ""
echo "4. Test PostgreSQL through tunnel:"
echo "   psql -h localhost -p 5433 -U opendiscourse -d opendiscourse -c 'SELECT 1;'"
echo ""

echo "### Alternative Solutions:"
echo ""
echo "If SSH still doesn't work:"
echo ""
echo "A. Use Congress.gov API with SQLite (no SSH needed)"
echo "   - I can start ingesting data into SQLite immediately"
echo "   - Migrate to PostgreSQL later when SSH is working"
echo ""
echo "B. Use reverse SSH tunnel (VM connects to your computer)"
echo "   - On your computer: ssh -R 5433:localhost:5432 user@your-computer -N &"
echo ""
echo "C. Use ngrok or similar tunneling service"
echo "   - Expose SSH port through ngrok"
echo ""
echo "========================================"
echo "End of Diagnostic Report"
echo "========================================"
echo ""
echo "Please copy this entire report and paste it back to me."
echo "I'll analyze it and provide specific solutions!"
