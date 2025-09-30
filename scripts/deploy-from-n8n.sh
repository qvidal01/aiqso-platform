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

# Source environment
source /root/.aiqso.env

# Change to scripts directory
cd /root/aiqso-platform/scripts

# Execute deployment
./deploy-service.sh "$TENANT_ID" "$SERVICE_KEY"