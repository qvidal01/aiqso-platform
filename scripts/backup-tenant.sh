#!/bin/bash
# backup-tenant.sh
# Creates backups of tenant containers and databases

set -e

# Source environment variables
if [ -f "/home/cyber/aiqso-platform/.env" ]; then
    source /home/cyber/aiqso-platform/.env
fi

# Arguments
TENANT_ID=$1

if [ -z "$TENANT_ID" ]; then
    echo "Usage: $0 <tenant_id|all>"
    echo "Example: $0 550e8400-e29b-41d4-a716-446655440000"
    echo "         $0 all"
    exit 1
fi

# Backup configuration
BACKUP_DIR="/mnt/pve/syno-nfs/backups/aiqso"
DATE_STAMP=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

echo "============================================"
echo "AIQSO Tenant Backup"
echo "$(date)"
echo "============================================"

# Function to backup a single tenant
backup_tenant() {
    local tid=$1

    # Get tenant info
    TENANT_INFO=$(psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -t -c "
    SELECT subdomain, company_name FROM tenants WHERE id = '$tid';
    ")

    SUBDOMAIN=$(echo $TENANT_INFO | awk '{print $1}')

    [ -z "$SUBDOMAIN" ] && return

    echo ""
    echo "Backing up tenant: $SUBDOMAIN"
    echo "----------------------------------------"

    # Get all services for this tenant
    SERVICES=$(psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -t -c "
    SELECT ts.id, s.service_key, ts.container_id, ts.database_name
    FROM tenant_services ts
    JOIN services s ON ts.service_id = s.id
    WHERE ts.tenant_id = '$tid' AND ts.status = 'active';
    ")

    while IFS='|' read -r service_id service_key container_id database_name; do
        service_id=$(echo $service_id | xargs)
        service_key=$(echo $service_key | xargs)
        container_id=$(echo $container_id | xargs)
        database_name=$(echo $database_name | xargs)

        [ -z "$service_id" ] && continue

        BACKUP_PATH="$BACKUP_DIR/${SUBDOMAIN}_${service_key}_${DATE_STAMP}"

        echo "  Service: $service_key (Container $container_id)"

        # Backup database
        if [ -n "$database_name" ]; then
            echo "    - Backing up database: $database_name"
            pg_dump -h $POSTGRES_HOST -U $POSTGRES_USER $database_name | gzip > "${BACKUP_PATH}_db.sql.gz"
            DB_SIZE=$(stat -f%z "${BACKUP_PATH}_db.sql.gz" 2>/dev/null || stat -c%s "${BACKUP_PATH}_db.sql.gz")
        else
            DB_SIZE=0
        fi

        # Backup container snapshot
        echo "    - Creating container snapshot"
        SNAPSHOT_NAME="backup_${DATE_STAMP}"
        pct snapshot $container_id $SNAPSHOT_NAME --description "Automated backup $(date)"

        # Export snapshot to file
        echo "    - Exporting snapshot"
        vzdump $container_id --mode snapshot --compress gzip --storage syno-nfs --dumpdir $BACKUP_DIR
        SNAPSHOT_FILE=$(ls -t $BACKUP_DIR/vzdump-lxc-${container_id}-*.tar.gz | head -1)
        SNAPSHOT_SIZE=$(stat -f%z "$SNAPSHOT_FILE" 2>/dev/null || stat -c%s "$SNAPSHOT_FILE")

        # Update backup record in database
        psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB <<EOF
INSERT INTO backups (tenant_id, service_id, backup_type, file_path, file_size_bytes, status, expires_at)
VALUES (
    '$tid',
    (SELECT id FROM services WHERE service_key = '$service_key'),
    'full',
    '$SNAPSHOT_FILE',
    $SNAPSHOT_SIZE,
    'completed',
    NOW() + INTERVAL '$RETENTION_DAYS days'
);
EOF

        echo "    - Backup completed: $(basename $SNAPSHOT_FILE)"

    done <<< "$SERVICES"
}

# Backup tenant(s)
if [ "$TENANT_ID" == "all" ]; then
    TENANT_IDS=$(psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -t -c "SELECT id FROM tenants WHERE status = 'active';")

    while read -r tid; do
        tid=$(echo $tid | xargs)
        [ -z "$tid" ] && continue
        backup_tenant "$tid"
    done <<< "$TENANT_IDS"
else
    backup_tenant "$TENANT_ID"
fi

# Clean up old backups
echo ""
echo "Cleaning up backups older than $RETENTION_DAYS days..."
find $BACKUP_DIR -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete

# Update expired backup records
psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB <<EOF
UPDATE backups
SET status = 'expired'
WHERE expires_at < NOW() AND status = 'completed';
EOF

echo ""
echo "============================================"
echo "Backup Complete!"
echo "Backup location: $BACKUP_DIR"
echo "============================================"