# AIQSO Platform - Deployment Guide

## Prerequisites

- Proxmox VE 8.x installed
- Root access to Proxmox host
- Network access to 10.10.10.0/24 (VLAN 1000) and 10.200.200.0/24 (VLAN 2000)
- Synology NAS at 192.168.0.25 with NFS share configured
- Domain ownership of aiqso.io with DNS access

## Phase 1: Infrastructure Deployment

### Step 1: Deploy Master Control Database (LXC 150)

```bash
# Create PostgreSQL container on VLAN 1000
pct create 150 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname master-control-db \
  --memory 4096 \
  --cores 2 \
  --storage local-lvm:20 \
  --net0 name=eth0,bridge=vmbr1,tag=1000,ip=10.10.10.150/24,gw=10.10.10.1 \
  --nameserver 8.8.8.8 \
  --unprivileged 1 \
  --features nesting=1 \
  --description "AIQSO Master Control Database" \
  --start 1

# Wait for container to boot
sleep 15

# Enter container and install PostgreSQL
pct enter 150

# Inside container:
apt update && apt upgrade -y
apt install -y postgresql postgresql-contrib

# Configure PostgreSQL to listen on all interfaces
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf

# Allow connections from container network
echo "host    all             all             10.10.10.0/24           md5" >> /etc/postgresql/*/main/pg_hba.conf

# Restart PostgreSQL
systemctl restart postgresql

# Create database and user
sudo -u postgres psql <<EOF
CREATE DATABASE aiqso_master;
CREATE USER aiqso_admin WITH ENCRYPTED PASSWORD 'CHANGE_THIS_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE aiqso_master TO aiqso_admin;
ALTER DATABASE aiqso_master OWNER TO aiqso_admin;
\q
EOF

# Import schema
sudo -u postgres psql -d aiqso_master < /path/to/master-schema.sql

# Exit container
exit
```

### Step 2: Deploy Vector Log Broker (LXC 200)

```bash
# Create Vector log broker container on VLAN 1000
pct create 200 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname vector-broker \
  --memory 2048 \
  --cores 2 \
  --storage local-lvm:20 \
  --net0 name=eth0,bridge=vmbr1,tag=1000,ip=10.10.10.100/24,gw=10.10.10.1 \
  --nameserver 8.8.8.8 \
  --unprivileged 1 \
  --features nesting=1 \
  --description "AIQSO Vector Log Broker" \
  --start 1

# Wait for container to boot
sleep 15

# Enter container
pct enter 200

# Inside container:
apt update && apt upgrade -y
apt install -y curl

# Install Vector
curl --proto '=https' --tlsv1.2 -sSf https://sh.vector.dev | bash -s -- -y

# Copy Vector configuration
cat > /etc/vector/vector.yaml <<'EOF'
[paste contents of docker/vector-config.yaml here]
EOF

# Start and enable Vector
systemctl enable vector
systemctl start vector

# Exit container
exit
```

### Step 3: Configure Existing Services

#### Update n8n (Container 101)

```bash
# Enter n8n container
pct enter 101

# Install PostgreSQL client for workflows
apt update && apt install -y postgresql-client

# Exit container
exit
```

#### Configure NginxPM (Container 127) for Wildcard Domain

1. Access NginxPM web interface (usually at http://10.10.10.127 or configured IP)
2. Login with admin credentials
3. Navigate to SSL Certificates
4. Add Let's Encrypt Certificate:
   - Domain: `*.aiqso.io`, `aiqso.io`
   - Enable "Use a DNS Challenge"
   - Select DNS provider (Cloudflare recommended)
   - Enter API credentials
   - Save and request certificate

5. Test wildcard certificate:
   - Create test proxy host: `test.aiqso.io`
   - Forward to any existing service
   - Verify HTTPS works

## Phase 2: Import n8n Workflows

1. Access n8n web interface at http://10.10.10.120:5678
2. For each workflow file in `n8n-workflows/`:
   - Click "Workflows" → "Import from File"
   - Select the JSON file
   - Configure credentials:
     - **AIQSO Master DB**: PostgreSQL credentials for 10.10.10.150
     - **Stripe**: API keys from Stripe dashboard
     - **NginxPM API**: API token from Nginx Proxy Manager
   - Activate the workflow

3. Test each workflow:
   - **01-customer-provisioning**: Use Stripe webhook test
   - **02-service-deployment**: Send test POST to webhook
   - **03-backup-orchestration**: Manually trigger
   - **04-health-monitoring**: Wait 5 minutes for first run
   - **05-ai-content-generation**: Send test POST with AI request
   - **06-usage-tracking**: Wait for hourly trigger

## Phase 3: Configure Environment Variables

```bash
# Create .env file on Proxmox host
cd /home/cyber/aiqso-platform
cp .env.example .env

# Edit .env with actual values
nano .env

# Set required values:
# - POSTGRES_PASSWORD (from Step 1)
# - STRIPE_SECRET_KEY (from Stripe dashboard)
# - STRIPE_WEBHOOK_SECRET (from Stripe webhook configuration)
# - PROXMOX_PASSWORD (your Proxmox root password)
```

## Phase 4: Deploy Customer Portal

```bash
# Option A: Deploy to new LXC container
pct create 110 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname aiqso-portal \
  --memory 2048 \
  --cores 2 \
  --storage local-lvm:15 \
  --net0 name=eth0,bridge=vmbr1,tag=1000,ip=10.10.10.110/24,gw=10.10.10.1 \
  --nameserver 8.8.8.8 \
  --unprivileged 1 \
  --features nesting=1 \
  --description "AIQSO Customer Portal" \
  --start 1

pct enter 110

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs git

# Clone repository
cd /opt
git clone https://github.com/qvidal01/aiqso-platform.git
cd aiqso-platform/frontend/customer-portal

# Install dependencies
npm install

# Build for production
npm run build

# Install PM2 for process management
npm install -g pm2

# Start application
pm2 start npm --name "aiqso-portal" -- start
pm2 save
pm2 startup

exit

# Configure NginxPM to route aiqso.io → 10.10.10.110:3000
```

## Phase 5: Configure Stripe Webhooks

1. Login to Stripe Dashboard
2. Navigate to Developers → Webhooks
3. Add endpoint: `https://n8n.aiqso.io/webhook/stripe-webhook`
4. Select events:
   - `payment_intent.succeeded`
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
5. Copy webhook signing secret to `.env` file

## Phase 6: DNS Configuration

Configure DNS records for aiqso.io:

```
A       aiqso.io                → [Your Public IP]
A       *.aiqso.io              → [Your Public IP]
A       n8n.aiqso.io            → [Your Public IP]
CNAME   www.aiqso.io            → aiqso.io
```

## Phase 7: Firewall Configuration

On your router/firewall:

```
Allow: 443/tcp → 10.10.10.127 (NginxPM)
Allow: 80/tcp  → 10.10.10.127 (NginxPM, for Let's Encrypt)
```

On Proxmox host:

```bash
# Allow container network to access required services
iptables -A FORWARD -s 10.10.10.0/24 -j ACCEPT
iptables -A FORWARD -d 10.10.10.0/24 -j ACCEPT
```

## Phase 8: Testing

### Test 1: Customer Signup Flow

1. Navigate to `https://aiqso.io/signup`
2. Complete signup form
3. Process test payment with Stripe test card: `4242 4242 4242 4242`
4. Verify:
   - Customer dashboard is accessible
   - Subdomain works: `https://[customer].aiqso.io`
   - Database record created in `tenants` table

### Test 2: Service Deployment

1. Login to customer dashboard
2. Click "Subscribe" on a service
3. Verify:
   - Service shows "Deploying..." status
   - New container created (check with `pct list`)
   - Service becomes "Active" within 5 minutes
   - Service is accessible at subdomain URL

### Test 3: Health Monitoring

1. Wait for health check workflow to run (every 5 minutes)
2. Check logs: `psql -h 10.10.10.150 -U aiqso_admin -d aiqso_master -c "SELECT * FROM audit_log ORDER BY created_at DESC LIMIT 10;"`
3. Stop a service container: `pct stop [container-id]`
4. Wait 5 minutes
5. Verify auto-restart attempted

### Test 4: Backups

1. Manually trigger backup workflow in n8n
2. Verify backup files created: `ls -lh /mnt/pve/syno-nfs/backups/aiqso/`
3. Check backup records: `psql -h 10.10.10.150 -U aiqso_admin -d aiqso_master -c "SELECT * FROM backups ORDER BY created_at DESC;"`

## Phase 9: Production Hardening

### Security

```bash
# Enable firewall on all containers
for id in 150 200 110; do
  pct exec $id -- apt install -y ufw
  pct exec $id -- ufw default deny incoming
  pct exec $id -- ufw default allow outgoing
  pct exec $id -- ufw allow from 10.10.10.0/24
  pct exec $id -- ufw enable
done

# Configure fail2ban on customer portal
pct exec 110 -- apt install -y fail2ban
```

### Monitoring

1. Add all containers to Grafana:
   - Node exporters on each container
   - PostgreSQL exporter on LXC 150
   - Custom dashboards for tenant metrics

2. Configure alerting:
   - Service health checks
   - Disk space warnings
   - Backup failures

### Backup Strategy

```bash
# Schedule daily Proxmox backups
vzdump --all --mode snapshot --compress gzip --storage syno-nfs --mailto admin@example.com

# Add to cron:
0 3 * * * vzdump --all --mode snapshot --compress gzip --storage syno-nfs
```

## Troubleshooting

### Issue: Customer provisioning fails

**Check:**
1. n8n workflow logs
2. Database connectivity: `psql -h 10.10.10.150 -U aiqso_admin -d aiqso_master`
3. Proxmox API access
4. Available container IDs (no conflicts)

### Issue: Services not accessible

**Check:**
1. Container running: `pct status [id]`
2. NginxPM proxy host configured
3. DNS resolving correctly: `nslookup [subdomain].aiqso.io`
4. SSL certificate valid

### Issue: Backups failing

**Check:**
1. Synology NFS mount: `df -h | grep syno-nfs`
2. Disk space on NAS
3. PostgreSQL connectivity
4. Backup script permissions

## Next Steps

1. **Scale Testing**: Test with multiple concurrent customers
2. **Performance Tuning**: Optimize PostgreSQL, Redis, container resources
3. **Documentation**: Create customer onboarding guides
4. **Monitoring**: Set up comprehensive dashboards
5. **Compliance**: GDPR, data retention policies
6. **Disaster Recovery**: Test restore procedures

## Support

For issues or questions:
- GitHub Issues: https://github.com/qvidal01/aiqso-platform/issues
- Email: quinn@aiqso.io