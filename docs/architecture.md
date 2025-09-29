# AIQSO Platform Architecture

## Overview

AIQSO is a multi-tenant SaaS platform built on Proxmox infrastructure. Each customer receives an isolated environment with their own subdomain and dedicated containers for subscribed services.

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Internet / User                             │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
                                 │ HTTPS (443)
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    Nginx Proxy Manager (LXC 127)                     │
│              *.aiqso.io → Dynamic Routing to Tenants                │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
           ┌─────────────────────┼─────────────────────┐
           │                     │                     │
           ▼                     ▼                     ▼
    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
    │ Customer A   │    │ Customer B   │    │ Customer C   │
    │ Dashboard    │    │ Dashboard    │    │ Dashboard    │
    │ LXC 301      │    │ LXC 302      │    │ LXC 303      │
    │ 10.10.10.51  │    │ 10.10.10.52  │    │ 10.10.10.53  │
    └──────┬───────┘    └──────┬───────┘    └──────┬───────┘
           │                   │                   │
           │  Subscribed Services (per customer):  │
           │                   │                   │
    ┌──────┴──────┬────────────┴─────┬────────────┴──────┐
    │             │                  │                    │
    ▼             ▼                  ▼                    ▼
┌─────────┐  ┌─────────┐       ┌─────────┐        ┌─────────┐
│ CRM     │  │ Docs    │       │ Email   │        │ Content │
│ LXC 311 │  │ LXC 312 │       │ LXC 313 │        │ LXC 314 │
└─────────┘  └─────────┘       └─────────┘        └─────────┘


┌─────────────────────────────────────────────────────────────────────┐
│                     Core Infrastructure (Shared)                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │ Master DB    │  │ n8n          │  │ Vector       │             │
│  │ PostgreSQL   │  │ Orchestrator │  │ Log Broker   │             │
│  │ LXC 150      │  │ LXC 101      │  │ LXC 200      │             │
│  │ 10.10.10.150 │  │ 10.10.10.120 │  │ 10.10.10.100 │             │
│  └──────────────┘  └──────────────┘  └──────────────┘             │
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │ Ollama AI    │  │ Redis Cache  │  │ Portainer    │             │
│  │ LXC 119      │  │ LXC 107      │  │ LXC 201      │             │
│  │ 10.10.10.11  │  │ 10.10.10.111 │  │ 10.10.10.247 │             │
│  └──────────────┘  └──────────────┘  └──────────────┘             │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────────────┐
│                  External Services & Monitoring                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │ Elasticsearch│  │ Wazuh        │  │ Grafana      │             │
│  │ VM 202       │  │ VM 225       │  │ External     │             │
│  │10.200.200.123│  │10.200.200.178│  │192.168.0.165 │             │
│  └──────────────┘  └──────────────┘  └──────────────┘             │
│                                                                      │
│  ┌──────────────┐                                                   │
│  │ Synology NAS │  ← Backups, NFS storage                          │
│  │192.168.0.25  │                                                   │
│  └──────────────┘                                                   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Network Architecture

### VLAN Segmentation

- **VLAN 1000** (10.10.10.0/24): Container Network
  - All LXC containers
  - Bridge: vmbr1

- **VLAN 2000** (10.200.200.0/24): Virtual Machine Network
  - VMs (Elasticsearch, Wazuh, etc.)
  - Bridge: vmbr1

- **Grid Network** (192.168.0.0/24): Management & External Services
  - Synology NAS
  - Grafana
  - Public-facing services

### Routing & Proxy

All external traffic flows through:
1. **Internet** → Public IP
2. **Router/Firewall** → Port 443/80 forwarded to Nginx Proxy Manager
3. **NginxPM** (LXC 127) → Routes based on subdomain:
   - `aiqso.io` → Main portal (LXC 110)
   - `customer-a.aiqso.io` → Customer A dashboard (LXC 301)
   - `customer-a.aiqso.io/crm` → Customer A CRM service (LXC 311)
   - `n8n.aiqso.io` → n8n automation (LXC 101)

## Data Flow

### Customer Provisioning Flow

```
1. Customer Signs Up
   ↓
2. Stripe Payment Intent Created
   ↓
3. Stripe Webhook → n8n (LXC 101)
   ↓
4. n8n: Create Tenant Record in Master DB (LXC 150)
   ↓
5. n8n: Execute provision-tenant.sh
   ↓
6. Proxmox: Create new LXC container (ID 301+)
   ↓
7. Container: Install Node.js, deploy customer dashboard
   ↓
8. n8n: Configure NginxPM route (subdomain → container IP)
   ↓
9. n8n: Send welcome email via Listmonk (LXC 104)
   ↓
10. Customer: Access https://their-subdomain.aiqso.io
```

### Service Deployment Flow

```
1. Customer subscribes to service (e.g., "CRM")
   ↓
2. Dashboard: POST to n8n webhook
   ↓
3. n8n: Validate subscription in Master DB
   ↓
4. n8n: Execute deploy-service.sh
   ↓
5. Script: Clone template or create new container
   ↓
6. Script: Configure networking, assign IP
   ↓
7. Script: Create service-specific database
   ↓
8. Script: Start container
   ↓
9. n8n: Configure NginxPM route (subdomain/service → service IP)
   ↓
10. n8n: Update Master DB (tenant_services table)
   ↓
11. n8n: Health check loop (wait for service ready)
   ↓
12. n8n: Send "Service Ready" email
   ↓
13. Customer: Access service at subdomain.aiqso.io/service
```

### Logging Flow

```
All Containers/VMs
   ↓ (syslog, http)
Vector Log Broker (LXC 200)
   ↓ (enrichment, routing)
   ├─→ Synology NAS (archive)
   ├─→ Elasticsearch (search/analysis)
   ├─→ Wazuh (security monitoring)
   └─→ Grafana Loki (visualization)
```

## Component Responsibilities

### Master Control Database (PostgreSQL - LXC 150)

**Purpose:** Central source of truth for all platform operations

**Tables:**
- `tenants`: Customer information, subdomain, status
- `services`: Available service catalog
- `subscriptions`: Stripe subscription tracking
- `tenant_services`: Deployed services per customer
- `usage_metrics`: Resource usage tracking for billing
- `backups`: Backup status and locations
- `audit_log`: All platform actions

**Access:**
- n8n workflows (all CRUD operations)
- Customer portal (read tenant/service info)
- Admin portal (full access)
- Backup scripts (read tenant info)

### n8n Automation Engine (LXC 101)

**Purpose:** Orchestrate all platform operations

**Workflows:**
1. **Customer Provisioning**: Stripe → Create tenant → Deploy container
2. **Service Deployment**: Request → Clone/create → Configure → Health check
3. **Backup Orchestration**: Daily backups of all tenants
4. **Health Monitoring**: 5-minute checks, auto-restart
5. **AI Content Generation**: Ollama integration for content services
6. **Usage Tracking**: Hourly metrics collection, monthly reports

### Vector Log Broker (LXC 200)

**Purpose:** Centralized log collection and routing

**Features:**
- Receives logs from all containers/VMs
- Enriches logs with tenant ID, service metadata
- Routes to multiple destinations simultaneously
- Handles high volume (thousands of events/second)

### Nginx Proxy Manager (LXC 127)

**Purpose:** Reverse proxy and SSL termination

**Features:**
- Wildcard SSL certificate for `*.aiqso.io`
- Dynamic routing based on subdomain
- Let's Encrypt integration
- Rate limiting, access control
- WebSocket support

### Ollama Local LLM (LXC 119)

**Purpose:** AI content generation without external API costs

**Models Available:**
- Llama 3 (default)
- Mistral
- Custom fine-tuned models

**Use Cases:**
- Blog post generation
- Social media captions
- Email campaign content
- SEO optimization

## Service Templates

### Cloneable Services (Fast Deployment)

These services have pre-configured containers that are cloned:

1. **Paperless-NGX** (LXC 102) → Document Management
   - Clone time: ~2 minutes
   - Includes: OCR, full-text search, mobile app

2. **Listmonk** (LXC 104) → Email Marketing
   - Clone time: ~1 minute
   - Includes: Campaign builder, subscriber management

3. **CalCom** (LXC 136) → Calendar & Scheduling
   - Clone time: ~1 minute
   - Includes: Online booking, calendar sync

### Custom Deployments (Built on Demand)

These are deployed fresh for each customer:

1. **EspoCRM** → CRM Suite
   - Docker image: `espocrm/espocrm:latest`
   - Deploy time: ~3-5 minutes
   - Includes: Sales pipeline, contact management

2. **Social Media Manager** → Custom Application
   - Next.js + Node.js
   - Deploy time: ~5 minutes
   - Integrates with Ollama for AI captions

3. **Content Creation Suite** → Custom Application
   - Next.js + Node.js
   - Deploy time: ~5 minutes
   - Integrates with Ollama for AI writing

## Scaling Considerations

### Vertical Scaling (Current)

- 192GB RAM per Proxmox host
- 36 cores per host
- Containers: 1-4GB RAM each
- **Current capacity:** ~50-100 tenants per host

### Horizontal Scaling (Future)

1. **Add Proxmox hosts** to cluster
2. **Distribute tenants** across hosts
3. **Replicate Master DB** with PostgreSQL streaming replication
4. **Load balance** NginxPM with HAProxy
5. **Shared storage** via Synology NAS (already configured)

### Resource Allocation

**Per Tenant (Average):**
- Dashboard: 2GB RAM, 2 CPU cores
- Per Service: 1-2GB RAM, 1-2 CPU cores
- Database: Shared PostgreSQL instance

**Example:**
- Tenant with 3 services = ~8GB RAM, 8 CPU cores
- 20 tenants = ~160GB RAM (fits on one host)

## High Availability Strategy

### Current State (Single Point of Failure)

- Single Proxmox host running all services
- Risk: Hardware failure = full outage

### HA Roadmap

1. **Phase 1:** Proxmox cluster (2+ hosts)
2. **Phase 2:** PostgreSQL replication (master-replica)
3. **Phase 3:** Shared storage (already using Synology NAS)
4. **Phase 4:** Load-balanced NginxPM
5. **Phase 5:** Multi-region deployment

## Security Architecture

### Network Security

- **Firewall:** Only ports 80/443 exposed to internet
- **VLANs:** Segmentation between containers and VMs
- **Unprivileged Containers:** All LXCs run unprivileged
- **Private Networks:** All inter-service communication on 10.x.x.x

### Data Security

- **Encryption at Rest:** PostgreSQL encryption
- **Encryption in Transit:** TLS 1.3 for all HTTPS
- **Secrets Management:** Environment variables, no hardcoded credentials
- **Backup Encryption:** Encrypted backups to Synology

### Access Control

- **Customer Isolation:** Each tenant in separate containers
- **Database Isolation:** Separate databases per tenant per service
- **API Authentication:** JWT tokens for all API calls
- **Admin Portal:** 2FA required, audit logging

### Monitoring & Alerting

- **Wazuh:** Security monitoring, intrusion detection
- **Vector:** Centralized logging
- **Grafana:** Real-time metrics, alerting
- **n8n:** Automated health checks, auto-remediation

## Backup & Disaster Recovery

### Backup Strategy

**Daily Backups (2 AM):**
1. PostgreSQL dump per tenant database
2. LXC container snapshots
3. Compress and upload to Synology NAS

**Retention:**
- Daily: 30 days
- Weekly: 12 weeks
- Monthly: 12 months

**Backup Locations:**
- Primary: Synology NAS (192.168.0.25)
- Secondary: (Future) Cloud storage (S3/B2)

### Recovery Procedures

**Service-Level Recovery:**
```bash
# Restore from most recent backup
./scripts/restore-service.sh <tenant_id> <service_key>
```

**Tenant-Level Recovery:**
```bash
# Restore entire tenant (all services)
./scripts/restore-tenant.sh <tenant_id>
```

**Platform-Level Recovery:**
```bash
# Restore master database
pg_restore -h 10.10.10.150 -U aiqso_admin -d aiqso_master backup.sql

# Restore all containers from snapshots
./scripts/restore-all.sh
```

## Performance Optimization

### Database Optimization

- Indexes on frequently queried columns
- Connection pooling (PgBouncer future consideration)
- Regular VACUUM and ANALYZE
- Query optimization for n8n workflows

### Container Optimization

- Memory limits to prevent resource hogging
- CPU shares for fair allocation
- Disk I/O limits where appropriate
- Container restart policies

### Caching Strategy

- Redis (LXC 107) for:
  - Session storage
  - API response caching
  - Rate limiting counters
  - Real-time metrics

## Compliance & Data Governance

### GDPR Compliance

- **Right to Access:** Customer dashboard shows all data
- **Right to Erasure:** Automated tenant deletion workflow
- **Data Portability:** Export functionality in dashboard
- **Consent:** Explicit opt-in for marketing emails

### Data Retention

- Active tenant data: Indefinite
- Cancelled tenant data: 90 days grace period
- Backups: Per retention policy
- Logs: 90 days (longer in archive)

## Future Enhancements

1. **Kubernetes Migration:** Migrate from LXC to K8s for better orchestration
2. **Multi-Region:** Deploy in multiple geographic regions
3. **Advanced Analytics:** ML-based usage prediction, cost optimization
4. **Marketplace:** Allow third-party service integrations
5. **White-Label:** Allow partners to rebrand platform