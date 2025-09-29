#!/bin/bash
# health-check.sh
# Performs health checks on all tenant services

set -e

# Source environment variables
if [ -f "/home/cyber/aiqso-platform/.env" ]; then
    source /home/cyber/aiqso-platform/.env
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "============================================"
echo "AIQSO Platform Health Check"
echo "$(date)"
echo "============================================"

# Get all active tenant services
SERVICES=$(psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -t -c "
SELECT ts.id, t.subdomain, s.service_key, ts.container_id, ts.ip_address
FROM tenant_services ts
JOIN tenants t ON ts.tenant_id = t.id
JOIN services s ON ts.service_id = s.id
WHERE ts.status = 'active'
ORDER BY t.subdomain, s.service_key;
")

TOTAL=0
HEALTHY=0
UNHEALTHY=0

while IFS='|' read -r service_id subdomain service_key container_id ip_address; do
    # Trim whitespace
    service_id=$(echo $service_id | xargs)
    subdomain=$(echo $subdomain | xargs)
    service_key=$(echo $service_key | xargs)
    container_id=$(echo $container_id | xargs)
    ip_address=$(echo $ip_address | xargs)

    [ -z "$service_id" ] && continue

    TOTAL=$((TOTAL + 1))

    printf "%-20s %-15s [%3s] " "$subdomain" "$service_key" "$container_id"

    # Check container status
    CONTAINER_STATUS=$(pct status $container_id 2>/dev/null | awk '{print $2}')

    if [ "$CONTAINER_STATUS" != "running" ]; then
        echo -e "${RED}FAILED${NC} - Container not running ($CONTAINER_STATUS)"
        UNHEALTHY=$((UNHEALTHY + 1))

        # Log to database
        psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c "
        UPDATE tenant_services
        SET status = 'stopped', last_health_check = NOW()
        WHERE id = '$service_id';" >/dev/null
        continue
    fi

    # Check HTTP endpoint (if applicable)
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://$ip_address 2>/dev/null || echo "000")

    if [ "$HTTP_STATUS" -ge 200 ] && [ "$HTTP_STATUS" -lt 400 ]; then
        echo -e "${GREEN}HEALTHY${NC} - HTTP $HTTP_STATUS"
        HEALTHY=$((HEALTHY + 1))

        # Update last health check
        psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c "
        UPDATE tenant_services
        SET last_health_check = NOW()
        WHERE id = '$service_id';" >/dev/null
    else
        echo -e "${YELLOW}DEGRADED${NC} - HTTP $HTTP_STATUS"
        UNHEALTHY=$((UNHEALTHY + 1))
    fi

done <<< "$SERVICES"

echo "============================================"
echo -e "Total Services: $TOTAL"
echo -e "${GREEN}Healthy: $HEALTHY${NC}"
echo -e "${RED}Unhealthy: $UNHEALTHY${NC}"
echo "============================================"

# Exit with error if any services are unhealthy
if [ $UNHEALTHY -gt 0 ]; then
    exit 1
fi

exit 0