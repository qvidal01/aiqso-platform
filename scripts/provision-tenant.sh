#!/bin/bash
# provision-tenant.sh
# Provisions a new tenant with customer dashboard container

set -e

# Source environment variables
if [ -f "/home/cyber/aiqso-platform/.env" ]; then
    source /home/cyber/aiqso-platform/.env
fi

# Arguments
TENANT_ID=$1
SUBDOMAIN=$2
COMPANY_NAME=$3
CONTACT_EMAIL=$4

if [ -z "$TENANT_ID" ] || [ -z "$SUBDOMAIN" ] || [ -z "$COMPANY_NAME" ] || [ -z "$CONTACT_EMAIL" ]; then
    echo "Usage: $0 <tenant_id> <subdomain> <company_name> <contact_email>"
    echo "Example: $0 550e8400-e29b-41d4-a716-446655440000 acmecorp 'Acme Corp' admin@acme.com"
    exit 1
fi

# Configuration
CONTAINER_START_ID=300
NETWORK_BASE="10.10.10"
GATEWAY="10.10.10.1"
STORAGE_POOL="local-lvm"
TEMPLATE="local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"

# Find next available container ID
echo "Finding next available container ID..."
NEXT_ID=$(pct list | awk 'NR>1 {print $1}' | sort -n | awk -v start=$CONTAINER_START_ID 'BEGIN{id=start} $1==id{id++} END{print id}')

# Find next available IP
echo "Finding next available IP address..."
USED_IPS=$(pct list | grep -oP "$NETWORK_BASE\.\K[0-9]+" | sort -n)
NEXT_IP_SUFFIX=50
for ip in $USED_IPS; do
    if [ $ip -ge $NEXT_IP_SUFFIX ]; then
        NEXT_IP_SUFFIX=$((ip + 1))
    fi
done
IP_ADDRESS="$NETWORK_BASE.$NEXT_IP_SUFFIX"

echo "============================================"
echo "Provisioning Tenant"
echo "============================================"
echo "Tenant ID:     $TENANT_ID"
echo "Subdomain:     $SUBDOMAIN"
echo "Company:       $COMPANY_NAME"
echo "Email:         $CONTACT_EMAIL"
echo "Container ID:  $NEXT_ID"
echo "IP Address:    $IP_ADDRESS"
echo "============================================"

# Create customer dashboard container
echo "Creating customer dashboard container..."
pct create $NEXT_ID $TEMPLATE \
    --hostname "$SUBDOMAIN-dashboard" \
    --memory 2048 \
    --cores 2 \
    --storage $STORAGE_POOL:10 \
    --net0 name=eth0,bridge=vmbr1,tag=1000,ip=$IP_ADDRESS/24,gw=$GATEWAY \
    --nameserver 8.8.8.8 \
    --unprivileged 1 \
    --features nesting=1 \
    --description "AIQSO Customer Dashboard - $COMPANY_NAME"

# Start container
echo "Starting container..."
pct start $NEXT_ID

# Wait for container to be ready
echo "Waiting for container to boot..."
sleep 10

# Install dependencies
echo "Installing Node.js and dependencies..."
pct exec $NEXT_ID -- bash -c "apt update && apt install -y curl"
pct exec $NEXT_ID -- bash -c "curl -fsSL https://deb.nodesource.com/setup_20.x | bash -"
pct exec $NEXT_ID -- bash -c "apt install -y nodejs git"

# Update database
echo "Updating master database..."
psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB <<EOF
UPDATE tenants
SET status = 'active'
WHERE id = '$TENANT_ID';

INSERT INTO tenant_services (tenant_id, service_id, container_id, container_name, ip_address, status, provisioned_at)
SELECT '$TENANT_ID', id, $NEXT_ID, '$SUBDOMAIN-dashboard', '$IP_ADDRESS'::inet, 'active', NOW()
FROM services WHERE service_key = 'dashboard'
ON CONFLICT (tenant_id, service_id) DO NOTHING;
EOF

echo "============================================"
echo "Provisioning Complete!"
echo "============================================"
echo "Container ID:  $NEXT_ID"
echo "IP Address:    $IP_ADDRESS"
echo "Subdomain:     $SUBDOMAIN.aiqso.io"
echo ""
echo "Next steps:"
echo "1. Configure NginxPM for $SUBDOMAIN.aiqso.io → $IP_ADDRESS"
echo "2. Deploy customer portal app to container $NEXT_ID"
echo "3. Send welcome email to $CONTACT_EMAIL"
echo "============================================"