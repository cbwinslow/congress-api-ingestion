#!/bin/bash
# PostgreSQL Firewall Configuration Script
# Idempotent commands for enabling PostgreSQL connections

set -e

echo "=== PostgreSQL Firewall Configuration ==="

# Check if ufw is available
if command -v ufw &> /dev/null; then
    echo "Configuring UFW firewall..."
    
    # Enable PostgreSQL port (5432)
    sudo ufw allow 5432/tcp comment 'PostgreSQL database'
    
    # Allow connections from Netbird IP (100.90.251.120)
    sudo ufw allow from 100.90.251.120 to any port 5432 comment 'Netbird PostgreSQL access'
    
    # Enable firewall if not already enabled
    sudo ufw --force enable
    
    # Show status
    sudo ufw status
    
elif command -v iptables &> /dev/null; then
    echo "Configuring iptables firewall..."
    
    # Allow PostgreSQL port
    sudo iptables -A INPUT -p tcp --dport 5432 -j ACCEPT
    
    # Allow connections from Netbird IP
    sudo iptables -A INPUT -p tcp -s 100.90.251.120 --dport 5432 -j ACCEPT
    
    # Save rules (if iptables-persistent is installed)
    if command -v iptables-save &> /dev/null; then
        sudo iptables-save | sudo tee /etc/iptables/rules.v4
    fi
    
    echo "iptables rules added"
    
elif command -v firewall-cmd &> /dev/null; then
    echo "Configuring firewalld firewall..."
    
    # Add PostgreSQL service
    sudo firewall-cmd --permanent --add-service=postgresql
    
    # Add rich rule for Netbird IP
    sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="100.90.251.120" port port="5432" protocol="tcp" accept'
    
    # Reload firewall
    sudo firewall-cmd --reload
    
    echo "firewalld configured"
    
else
    echo "No firewall detected. PostgreSQL should be accessible if service is running."
fi

echo "=== Firewall configuration complete ==="
echo ""
echo "Next steps:"
echo "1. Ensure PostgreSQL is running and listening on the correct interface"
echo "2. Check PostgreSQL configuration: /etc/postgresql/*/main/postgresql.conf"
echo "3. Verify pg_hba.conf allows connections from Netbird IP"
echo ""
