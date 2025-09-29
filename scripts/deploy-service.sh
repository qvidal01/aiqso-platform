#!/bin/bash
# deploy-service.sh
# Deploys a service for a tenant (clones template or creates new container)

set -e

# Source environment variables
if [ -f "/home/cyber/aiqso-platform/.env" ]; then
    source /home/cyber/aiqso-platform/.env
fi

# Arguments
TENANT_ID=$1
SERVICE_KEY=$2

if [ -z "$TENANT_ID" ] || [ -z "$SERVICE_KEY" ]; then
    echo "Usage: $0 <tenant_id> <service_key>"
    echo "Example: $0 550e8400-e29b-41d4-a716-446655440000 docs"
    echo ""
    echo "Available services: crm, docs, social, content, email, calendar"
    exit 1
fi

# Get tenant and service info from database
TENANT_INFO=$(psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -t -c "SELECT subdomain, company_name FROM tenants WHERE id = '$TENANT_ID';")
SUBDOMAIN=$(echo $TENANT_INFO | awk '{print $1}')
COMPANY_NAME=$(echo $TENANT_INFO | cut -d'|' -f2)

SERVICE_INFO=$(psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -t -c "SELECT id, service_name, config_template FROM services WHERE service_key = '$SERVICE_KEY';")
SERVICE_ID=$(echo $SERVICE_INFO | awk '{print $1}')
SERVICE_NAME=$(echo $SERVICE_INFO | cut -d'|' -f2)
CONFIG=$(echo $SERVICE_INFO | cut -d'|' -f3)

# Parse config for clone_from if exists
CLONE_FROM=$(echo $CONFIG | grep -oP '"clone_from":\s*\K[0-9]+' || echo "")

# Find next available container ID and IP
NEXT_ID=$(pct list | awk 'NR>1 {print $1}' | sort -n | tail -1)
NEXT_ID=$((NEXT_ID + 1))

NETWORK_BASE="10.10.10"
USED_IPS=$(pct list | grep -oP "$NETWORK_BASE\.\K[0-9]+" | sort -n)
NEXT_IP_SUFFIX=50
for ip in $USED_IPS; do
    if [ $ip -ge $NEXT_IP_SUFFIX ]; then
        NEXT_IP_SUFFIX=$((ip + 1))
    fi
done
IP_ADDRESS="$NETWORK_BASE.$NEXT_IP_SUFFIX"

echo "============================================"
echo "Deploying Service"
echo "============================================"
echo "Tenant:        $SUBDOMAIN ($COMPANY_NAME)"
echo "Service:       $SERVICE_NAME ($SERVICE_KEY)"
echo "Container ID:  $NEXT_ID"
echo "IP Address:    $IP_ADDRESS"
echo "============================================"

# Deploy service
if [ -n "$CLONE_FROM" ]; then
    echo "Cloning from template container $CLONE_FROM..."
    pct clone $CLONE_FROM $NEXT_ID --hostname "$SUBDOMAIN-$SERVICE_KEY"
    pct set $NEXT_ID -net0 name=eth0,bridge=vmbr1,tag=1000,ip=$IP_ADDRESS/24,gw=10.10.10.1
    pct set $NEXT_ID -description "AIQSO $SERVICE_NAME - $COMPANY_NAME"
else
    echo "Creating new container from scratch..."
    # TODO: Implement custom service deployment (CRM, Social, Content)
    echo "Custom service deployment not yet implemented for $SERVICE_KEY"
    exit 1
fi

# Start container
echo "Starting container..."
pct start $NEXT_ID

# Wait for service to be ready
echo "Waiting for service to start..."
sleep 15

# Create service-specific database if needed
DB_NAME="${SUBDOMAIN}_${SERVICE_KEY}"
echo "Creating database: $DB_NAME"
psql -h $POSTGRES_HOST -U $POSTGRES_USER -d postgres <<EOF
CREATE DATABASE $DB_NAME;
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $POSTGRES_USER;
EOF

# Update master database
echo "Updating master database..."
psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB <<EOF
INSERT INTO tenant_services (tenant_id, service_id, container_id, container_name, database_name, ip_address, status, provisioned_at)
VALUES ('$TENANT_ID', '$SERVICE_ID', $NEXT_ID, '$SUBDOMAIN-$SERVICE_KEY', '$DB_NAME', '$IP_ADDRESS'::inet, 'active', NOW())
ON CONFLICT (tenant_id, service_id) DO UPDATE
SET container_id = $NEXT_ID,
    container_name = '$SUBDOMAIN-$SERVICE_KEY',
    database_name = '$DB_NAME',
    ip_address = '$IP_ADDRESS'::inet,
    status = 'active',
    provisioned_at = NOW();
EOF

echo "============================================"
echo "Service Deployment Complete!"
echo "============================================"
echo "Container ID:  $NEXT_ID"
echo "IP Address:    $IP_ADDRESS"
echo "Database:      $DB_NAME"
echo "URL:           https://$SUBDOMAIN.aiqso.io/$SERVICE_KEY"
echo ""
echo "Next steps:"
echo "1. Configure NginxPM route: $SUBDOMAIN.aiqso.io/$SERVICE_KEY → $IP_ADDRESS"
echo "2. Run health check"
echo "3. Notify customer"
echo "============================================"