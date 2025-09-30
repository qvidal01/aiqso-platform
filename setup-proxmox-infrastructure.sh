#!/bin/bash
# setup-proxmox-infrastructure.sh
# Run this ON the Proxmox host (192.168.0.165)
# This sets up the proper architecture where n8n can deploy services

set -e

echo "============================================"
echo "AIQSO Platform Infrastructure Setup"
echo "============================================"
echo ""
echo "This script will:"
echo "1. Clone aiqso-platform repo to Proxmox"
echo "2. Generate SSH keys for n8n container"
echo "3. Allow n8n to SSH into Proxmox host"
echo "4. Install required dependencies"
echo ""
read -p "Press Enter to continue..."

# Step 1: Clone repo to Proxmox host
echo ""
echo "Step 1: Cloning GitHub repository..."
cd /root
if [ -d "aiqso-platform" ]; then
    echo "  Repository already exists, pulling latest..."
    cd aiqso-platform
    git pull
else
    echo "  Cloning repository..."
    git clone https://github.com/qvidal01/aiqso-platform.git
fi
cd /root/aiqso-platform
chmod +x scripts/*.sh
echo "  ✓ Repository ready at /root/aiqso-platform"

# Step 2: Install PostgreSQL client if not present
echo ""
echo "Step 2: Installing PostgreSQL client..."
if ! command -v psql &> /dev/null; then
    apt-get update -qq
    apt-get install -y postgresql-client
    echo "  ✓ PostgreSQL client installed"
else
    echo "  ✓ PostgreSQL client already installed"
fi

# Step 3: Copy .env file to Proxmox
echo ""
echo "Step 3: Setting up environment variables..."
if [ ! -f "/root/.aiqso.env" ]; then
    cat > /root/.aiqso.env <<'EOF'
# AIQSO Platform Environment Variables
POSTGRES_HOST=10.10.10.150
POSTGRES_PORT=5432
POSTGRES_DB=aiqso_master
POSTGRES_USER=aiqso_admin
POSTGRES_PASSWORD=AiqsoSecure2025Platform
PGPASSWORD=AiqsoSecure2025Platform
EOF
    chmod 600 /root/.aiqso.env
    echo "  ✓ Environment file created at /root/.aiqso.env"
else
    echo "  ✓ Environment file already exists"
fi

# Step 4: Generate SSH key for n8n container
echo ""
echo "Step 4: Setting up SSH access for n8n container..."
pct exec 101 -- bash -c "
    if [ ! -f /root/.ssh/id_ed25519 ]; then
        mkdir -p /root/.ssh
        ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -N '' -C 'n8n@aiqso-platform'
        echo '  ✓ SSH key generated in n8n container'
    else
        echo '  ✓ SSH key already exists in n8n container'
    fi
"

# Step 5: Copy n8n's public key to Proxmox authorized_keys
echo ""
echo "Step 5: Authorizing n8n to access Proxmox..."
N8N_PUBLIC_KEY=$(pct exec 101 -- cat /root/.ssh/id_ed25519.pub)
mkdir -p /root/.ssh
touch /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

if ! grep -q "$N8N_PUBLIC_KEY" /root/.ssh/authorized_keys; then
    echo "$N8N_PUBLIC_KEY" >> /root/.ssh/authorized_keys
    echo "  ✓ n8n public key added to authorized_keys"
else
    echo "  ✓ n8n public key already authorized"
fi

# Step 6: Add Proxmox host to n8n's known_hosts
echo ""
echo "Step 6: Adding Proxmox to n8n known_hosts..."
pct exec 101 -- bash -c "
    mkdir -p /root/.ssh
    ssh-keyscan -H 192.168.0.165 >> /root/.ssh/known_hosts 2>/dev/null
    echo '  ✓ Proxmox host added to known_hosts'
"

# Step 7: Test SSH connection from n8n to Proxmox
echo ""
echo "Step 7: Testing SSH connection..."
pct exec 101 -- ssh -o StrictHostKeyChecking=no root@192.168.0.165 "echo '  ✓ SSH connection successful!'"

# Step 8: Install psql in n8n container
echo ""
echo "Step 8: Installing PostgreSQL client in n8n container..."
pct exec 101 -- bash -c "
    if ! command -v psql &> /dev/null; then
        apt-get update -qq
        apt-get install -y postgresql-client
        echo '  ✓ PostgreSQL client installed in n8n'
    else
        echo '  ✓ PostgreSQL client already installed in n8n'
    fi
"

echo ""
echo "============================================"
echo "✓ Infrastructure Setup Complete!"
echo "============================================"
echo ""
echo "Summary:"
echo "  ✓ Repository cloned to /root/aiqso-platform"
echo "  ✓ n8n container can SSH to Proxmox host"
echo "  ✓ PostgreSQL client installed"
echo "  ✓ Environment variables configured"
echo ""
echo "n8n can now execute deployment commands:"
echo "  ssh root@192.168.0.165 'cd /root/aiqso-platform/scripts && ./deploy-service.sh <tenant_id> <service_key>'"
echo ""
echo "Next: Update the workflow in n8n UI to use this command"
echo "============================================"