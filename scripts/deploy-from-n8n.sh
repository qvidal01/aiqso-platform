#!/bin/bash
# deploy-from-n8n.sh
# Wrapper script for n8n to deploy services
# Usage: ./deploy-from-n8n.sh <tenant_id> <service_key>

set -e

TENANT_ID=$1
SERVICE_KEY=$2

if [ -z "$TENANT_ID" ] || [ -z "$SERVICE_KEY" ]; then
    echo "ERROR: Missing arguments"
    echo "Usage: $0 <tenant_id> <service_key>"
    exit 1
fi

# Export environment variables
export POSTGRES_HOST=10.10.10.150
export POSTGRES_PORT=5432
export POSTGRES_DB=aiqso_master
export POSTGRES_USER=aiqso_admin
export POSTGRES_PASSWORD=AiqsoSecure2025Platform
export PGPASSWORD=AiqsoSecure2025Platform

# Change to scripts directory
cd /root/aiqso-platform/scripts

# Execute deployment
./deploy-service.sh "$TENANT_ID" "$SERVICE_KEY"