# AIQSO Platform - Quick Start Guide

## What Has Been Built

A complete multi-tenant SaaS platform foundation with:

✅ **Database Schema** - PostgreSQL with 7 tables for tenants, services, subscriptions, backups, metrics, and audit logging
✅ **6 n8n Workflows** - Full automation for provisioning, deployment, backups, monitoring, AI content, and usage tracking
✅ **4 Bash Scripts** - Tenant provisioning, service deployment, health checks, and backups
✅ **Customer Portal** - Next.js application with landing page and dashboard
✅ **Complete Documentation** - Architecture, deployment guide, and infrastructure inventory
✅ **Network Configuration** - VLAN 1000 (containers) and VLAN 2000 (VMs) using vmbr1

## Next Steps (In Order)

### 1. Deploy Core Infrastructure (30 minutes)

```bash
# Deploy Master Database (LXC 150)
pct create 150 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname master-control-db \
  --memory 4096 --cores 2 --storage local-lvm:20 \
  --net0 name=eth0,bridge=vmbr1,tag=1000,ip=10.10.10.150/24,gw=10.10.10.1 \
  --nameserver 8.8.8.8 --unprivileged 1 --features nesting=1 --start 1

# Install PostgreSQL and import schema
pct exec 150 -- apt update && pct exec 150 -- apt install -y postgresql postgresql-contrib
# ... (see docs/deployment-guide.md for full steps)

# Deploy Vector Log Broker (LXC 200)
pct create 200 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname vector-broker \
  --memory 2048 --cores 2 --storage local-lvm:20 \
  --net0 name=eth0,bridge=vmbr1,tag=1000,ip=10.10.10.100/24,gw=10.10.10.1 \
  --nameserver 8.8.8.8 --unprivileged 1 --features nesting=1 --start 1

# Install Vector
# ... (see docs/deployment-guide.md for full steps)
```

### 2. Configure Environment Variables (5 minutes)

```bash
cd /home/cyber/aiqso-platform
cp .env.example .env
nano .env  # Fill in actual values
```

Required values:
- `POSTGRES_PASSWORD` (set during PostgreSQL setup)
- `STRIPE_SECRET_KEY` (from Stripe dashboard)
- `STRIPE_WEBHOOK_SECRET` (configure after n8n setup)

### 3. Import n8n Workflows (15 minutes)

1. Access n8n: `http://10.10.10.120:5678`
2. Import each workflow from `n8n-workflows/`
3. Configure credentials:
   - PostgreSQL connection to 10.10.10.150
   - Stripe API keys
   - NginxPM API token
4. Activate all workflows

### 4. Configure NginxPM Wildcard SSL (10 minutes)

1. Access NginxPM web interface
2. Add SSL Certificate for `*.aiqso.io` and `aiqso.io`
3. Use DNS challenge (Cloudflare recommended)
4. Save certificate ID for n8n workflows

### 5. Deploy Customer Portal (20 minutes)

```bash
# Deploy to LXC 110 or use existing container
cd /home/cyber/aiqso-platform/frontend/customer-portal
npm install
npm run build
pm2 start npm --name "aiqso-portal" -- start
pm2 save
pm2 startup
```

Configure NginxPM to route `aiqso.io` → customer portal IP:3000

### 6. Test Everything (30 minutes)

**Test 1: Database Connection**
```bash
psql -h 10.10.10.150 -U aiqso_admin -d aiqso_master -c "SELECT * FROM services;"
```

**Test 2: n8n Workflows**
- Manually trigger health monitoring workflow
- Check audit_log for entries

**Test 3: Customer Portal**
- Visit `https://aiqso.io`
- Verify landing page loads

**Test 4: End-to-End (when Stripe configured)**
- Complete signup flow
- Verify tenant provisioning
- Subscribe to a service
- Verify service deployment

## Repository Structure

```
aiqso-platform/
├── database/
│   └── master-schema.sql          # PostgreSQL schema with all tables
├── docker/
│   └── vector-config.yaml         # Vector log broker config
├── docs/
│   ├── architecture.md            # System architecture documentation
│   ├── deployment-guide.md        # Step-by-step deployment instructions
│   └── infrastructure-inventory.md # Complete infrastructure list
├── frontend/
│   └── customer-portal/           # Next.js customer portal
│       ├── src/app/
│       │   ├── page.tsx          # Landing page
│       │   └── dashboard/page.tsx # Customer dashboard
│       └── package.json
├── n8n-workflows/
│   ├── 01-customer-provisioning.json
│   ├── 02-service-deployment.json
│   ├── 03-backup-orchestration.json
│   ├── 04-health-monitoring.json
│   ├── 05-ai-content-generation.json
│   └── 06-usage-tracking.json
├── scripts/
│   ├── provision-tenant.sh       # Create new tenant
│   ├── deploy-service.sh         # Deploy service for tenant
│   ├── health-check.sh          # Check service health
│   └── backup-tenant.sh         # Backup tenant data
├── .env.example                  # Environment variables template
├── README.md                     # Project overview
└── QUICK_START.md               # This file
```

## Architecture Overview

```
Internet → NginxPM (LXC 127)
    ↓
    ├─→ aiqso.io → Customer Portal (LXC 110)
    ├─→ customer-a.aiqso.io → Customer A Dashboard (LXC 301)
    └─→ customer-a.aiqso.io/crm → Customer A CRM Service (LXC 311)

Core Services:
- Master DB: 10.10.10.150 (LXC 150)
- n8n: 10.10.10.120 (LXC 101)
- Vector: 10.10.10.100 (LXC 200)
- Ollama AI: 10.10.10.11 (LXC 119)
- Redis: 10.10.10.111 (LXC 107)

Logging:
All services → Vector → Elasticsearch/Wazuh/Synology
```

## Key Features

### Multi-Tenant Isolation
- Each customer gets their own subdomain
- Dedicated containers per service
- Separate databases per tenant per service

### Automated Operations
- Customer provisioning: Fully automated via n8n
- Service deployment: 2-5 minutes per service
- Health monitoring: Every 5 minutes with auto-restart
- Backups: Daily at 2 AM to Synology NAS

### AI-Powered
- Local Ollama LLM for content generation
- No external API costs
- Supports blog posts, social media, emails

### Service Catalog
1. **CRM Suite** ($49/mo) - EspoCRM
2. **Document Management** ($29/mo) - Paperless-NGX
3. **Email Marketing** ($29/mo) - Listmonk
4. **Calendar** ($19/mo) - CalCom
5. **Social Media Manager** ($39/mo) - Custom
6. **Content Creation** ($59/mo) - Custom + AI

## Capacity Planning

**Single Proxmox Host (192GB RAM):**
- Support 40-50 tenants with mixed services
- ~200-250 containers total
- Reserve 20% for overhead

**When to Scale:**
- Add second Proxmox host at 30+ tenants
- Implement PostgreSQL replication
- Load balance NginxPM

## Security

- All containers unprivileged
- VLAN segmentation
- TLS 1.3 for all HTTPS
- Wildcard SSL from Let's Encrypt
- Encrypted backups
- Audit logging for all actions

## Support & Troubleshooting

**Common Issues:**

1. **Container won't start**
   ```bash
   pct status [id]
   journalctl -u pve-container@[id]
   ```

2. **Database connection fails**
   ```bash
   psql -h 10.10.10.150 -U aiqso_admin -d aiqso_master
   # Check pg_hba.conf and postgresql.conf
   ```

3. **n8n workflow fails**
   - Check workflow execution logs
   - Verify credentials
   - Test database connectivity

4. **Service not accessible**
   - Check NginxPM proxy configuration
   - Verify DNS resolves correctly
   - Check container firewall

**Get Help:**
- Full docs: `docs/deployment-guide.md`
- Architecture: `docs/architecture.md`
- GitHub Issues: https://github.com/qvidal01/aiqso-platform/issues

## What's Next?

After deployment:
1. ✅ Test with 1-2 pilot customers
2. ✅ Monitor resource usage
3. ✅ Optimize workflows
4. ✅ Build Admin Portal
5. ✅ Implement billing automation
6. ✅ Create customer documentation
7. ✅ Add monitoring dashboards
8. ✅ Plan scaling strategy

## Time to Launch

**Aggressive Timeline:**
- Days 1-2: Deploy infrastructure ✅ (You are here)
- Days 3-5: Test and refine
- Days 6-8: Build custom services (Social, Content)
- Days 9-11: Admin portal and billing
- Days 12-14: Polish and launch

**Ready to begin!** 🚀