# AIQSO Platform - Infrastructure Inventory

**Last Updated:** September 29, 2025

## Proxmox Hosts

| Hostname    | IP Address      | Role    | CPU                | RAM    | Storage |
|-------------|-----------------|---------|--------------------|--------|---------|
| proxhpmain  | 192.168.0.x     | Primary | 2x Xeon E5-2690 v2 | 192GB  | 36TB+   |
| (secondary) | TBD             | Backup  | 2x Xeon E5-2690 v2 | 192GB  | 36TB+   |

## Storage Pools (proxhpmain)

| Pool Name    | Type      | Mount Point     | Size  | Used  | Purpose                    |
|--------------|-----------|-----------------|-------|-------|----------------------------|
| local        | Directory | /var/lib/vz     | 1TB   | 15%   | ISOs, backups, templates   |
| local-lvm    | LVM-thin  | N/A             | 4TB   | 34.6% | VM/LXC disks              |
| nvme-thin    | LVM-thin  | N/A             | 2TB   | 5.4%  | High-speed storage         |
| syno-nfs     | NFS       | /mnt/pve/...    | 36TB  | 13.8% | Network storage, backups   |
| tank-storage | ZFS       | N/A             | 20TB  | 9.9%  | Large capacity storage     |
| tank-backups | ZFS       | N/A             | 10TB  | -     | Backup storage             |
| tank-iso     | ZFS       | N/A             | 500GB | -     | ISO storage                |

## Network Configuration

| Network          | VLAN | Subnet            | Gateway      | Purpose                   |
|------------------|------|-------------------|--------------|---------------------------|
| Grid Network     | -    | 192.168.0.0/24    | 192.168.0.1  | Management, external      |
| Container Net    | 1000 | 10.10.10.0/24     | 10.10.10.1   | LXC containers            |
| VM Network       | 2000 | 10.200.200.0/24   | 10.200.200.1 | Virtual machines          |
| DMZ              | -    | 10.255.255.0/24   | 10.255.255.1 | Isolated services         |

**Bridge:** vmbr1 (for VLANs 1000 and 2000)

## Core Infrastructure Containers (LXC)

### AIQSO Platform Core

| ID  | Hostname             | IP Address   | RAM   | CPU | Storage | Purpose                      | Status |
|-----|----------------------|--------------|-------|-----|---------|------------------------------|--------|
| 150 | master-control-db    | 10.10.10.150 | 4GB   | 2   | 20GB    | PostgreSQL master database   | NEW    |
| 200 | vector-broker        | 10.10.10.100 | 2GB   | 2   | 20GB    | Centralized log broker       | NEW    |
| 110 | aiqso-portal         | 10.10.10.110 | 2GB   | 2   | 15GB    | Customer portal website      | NEW    |

### Existing Infrastructure (Leveraged)

| ID  | Hostname             | IP Address   | RAM   | CPU | Storage | Purpose                      | Status    |
|-----|----------------------|--------------|-------|-----|---------|------------------------------|-----------|
| 101 | n8n-automation       | 10.10.10.120 | 2GB   | 2   | 10GB    | Workflow orchestration       | ACTIVE    |
| 119 | Ollama               | 10.10.10.11  | 8GB   | 4   | 50GB    | Local LLM for AI features    | ACTIVE    |
| 115 | OpenWebUI            | 10.10.10.210 | 2GB   | 2   | 10GB    | AI interface                 | ACTIVE    |
| 127 | NginxPM              | -            | 1GB   | 1   | 5GB     | Reverse proxy manager        | ACTIVE    |
| 107 | Redis                | 10.10.10.111 | 1GB   | 1   | 5GB     | Cache and session storage    | ACTIVE    |
| 201 | Portainer            | 10.10.10.247 | 1GB   | 1   | 5GB     | Container management UI      | ACTIVE    |

### Service Templates (Cloneable)

| ID  | Hostname             | IP Address   | RAM   | CPU | Storage | Purpose                      | Clone For       |
|-----|----------------------|--------------|-------|-----|---------|------------------------------|-----------------|
| 102 | paperless-ngx        | 10.10.10.158 | 2GB   | 2   | 20GB    | Document management          | Docs service    |
| 104 | Listmonk             | -            | 1GB   | 1   | 5GB     | Email marketing              | Email service   |
| 136 | CalCom               | -            | 1GB   | 1   | 5GB     | Calendar scheduling          | Calendar svc    |

### Supporting Services

| ID  | Hostname             | IP Address   | RAM   | CPU | Storage | Purpose                      |
|-----|----------------------|--------------|-------|-----|---------|------------------------------|
| 123 | Monica               | -            | 1GB   | 1   | 5GB     | Personal CRM (optional)      |
| 125 | Odoo                 | -            | 2GB   | 2   | 10GB    | ERP (optional)               |
| 134 | code-server          | 10.10.10.253 | 2GB   | 2   | 10GB    | VS Code in browser           |
| 250 | gitea-server         | 10.10.10.36  | 1GB   | 1   | 10GB    | Git hosting                  |
| 113 | Ghost                | -            | 1GB   | 1   | 5GB     | Blogging platform            |
| 138 | RocketChat           | -            | 1GB   | 1   | 5GB     | Team chat                    |
| 108 | Zammad               | -            | 2GB   | 2   | 10GB    | Helpdesk/ticketing           |
| 117 | paperless-ai         | 10.10.10.254 | 2GB   | 2   | 10GB    | AI document processing       |
| 118 | paperless-gpt        | 10.10.10.254 | 2GB   | 2   | 10GB    | GPT document queries         |

## Virtual Machines

### Production VMs

| ID  | Hostname             | IP Address      | RAM   | CPU | Storage | Purpose                      | Status |
|-----|----------------------|-----------------|-------|-----|---------|------------------------------|--------|
| 100 | haos-16.2            | 10.200.200.99   | 4GB   | 2   | 32GB    | Home Assistant               | ACTIVE |
| 200 | Splunk-Enterprise    | 10.200.200.122  | 16GB  | 8   | 200GB   | Log indexing/analysis        | ACTIVE |
| 202 | Elasticsearch        | 10.200.200.123  | 8GB   | 4   | 100GB   | Search engine                | ACTIVE |
| 225 | Wazuh                | 10.200.200.178  | 8GB   | 4   | 100GB   | Security monitoring          | ACTIVE |

### Test/Development VMs

| ID   | Hostname                 | Purpose              | Status |
|------|--------------------------|----------------------|--------|
| 203  | Splunk-Test-1            | Testing environment  | TEST   |
| 204  | Splunk-Test-2            | Testing environment  | TEST   |
| 205  | Splunk-Test-3            | Testing environment  | TEST   |
| 210  | Splunk-Test-Clone        | Testing environment  | TEST   |
| 220  | Elasticsearch-Test       | Testing environment  | TEST   |

### Templates

| ID   | Hostname                 | Purpose              |
|------|--------------------------|----------------------|
| 9000 | Splunk-Template          | Splunk VM template   |
| 9001 | Elasticsearch-Template   | ES VM template       |

## External Services

| Service           | IP Address      | Port  | Purpose                      |
|-------------------|-----------------|-------|------------------------------|
| Synology NAS      | 192.168.0.25    | -     | Backup storage, NFS shares   |
| Grafana           | 192.168.0.165   | 3000  | Monitoring dashboards        |
| Prometheus        | 192.168.0.165   | 9090  | Metrics collection           |

## Container ID Allocation Plan

### Reserved Ranges

| Range     | Purpose                              |
|-----------|--------------------------------------|
| 100-199   | Core infrastructure (existing)       |
| 150-159   | AIQSO core services (new)           |
| 200-249   | Logging/monitoring                   |
| 250-299   | Development tools                    |
| 300-399   | Customer dashboards (production)     |
| 400-899   | Customer services (production)       |
| 900-999   | Testing/staging                      |

### Example Tenant Allocation

**Tenant: Acme Corp (subdomain: acmecorp)**
- Dashboard: LXC 301 (10.10.10.51)
- CRM Service: LXC 401 (10.10.10.101)
- Docs Service: LXC 402 (10.10.10.102)
- Email Service: LXC 403 (10.10.10.103)

**Tenant: Beta Industries (subdomain: betaindustries)**
- Dashboard: LXC 302 (10.10.10.52)
- CRM Service: LXC 404 (10.10.10.104)
- Calendar Service: LXC 405 (10.10.10.105)

## IP Address Allocation Plan

### Container Network (10.10.10.0/24)

| Range           | Purpose                              |
|-----------------|--------------------------------------|
| 10.10.10.1      | Gateway                              |
| 10.10.10.10-49  | Infrastructure services              |
| 10.10.10.50-99  | Customer dashboards                  |
| 10.10.10.100-249| Customer services                    |
| 10.10.10.250-254| Reserved/special purpose             |

## Service Catalog

Services available for customer subscription:

| Service Key | Service Name               | Base Price | Docker Image                    | Requires DB | Clone From |
|-------------|----------------------------|------------|---------------------------------|-------------|------------|
| crm         | CRM Suite                  | $49/mo     | espocrm/espocrm:latest          | Yes         | N/A (new)  |
| docs        | Document Management        | $29/mo     | paperlessngx/paperless-ngx      | Yes         | LXC 102    |
| social      | Social Media Manager       | $39/mo     | custom/social-manager:latest    | Yes         | N/A (new)  |
| content     | Content Creation Suite     | $59/mo     | custom/content-suite:latest     | Yes         | N/A (new)  |
| email       | Email Marketing            | $29/mo     | listmonk/listmonk:latest        | Yes         | LXC 104    |
| calendar    | Calendar & Scheduling      | $19/mo     | calcom/cal.com:latest           | Yes         | LXC 136    |

## Resource Requirements

### Per Tenant (Estimate)

**Minimum (Dashboard only):**
- RAM: 2GB
- CPU: 2 cores
- Storage: 10GB
- Network: 10Mbps

**Average (Dashboard + 3 services):**
- RAM: 8GB (2GB dashboard + 2GB per service)
- CPU: 8 cores
- Storage: 40GB
- Network: 50Mbps

**Maximum (All services):**
- RAM: 14GB
- CPU: 14 cores
- Storage: 70GB
- Network: 100Mbps

### Platform Capacity

**Single Proxmox Host (192GB RAM, 36 cores):**
- Minimum tenants: ~96 (dashboard only)
- Average tenants: ~24 (with 3 services each)
- Maximum tenants: ~13 (all services)

**Realistic Production Capacity:**
- Target: 40-50 tenants per host
- Mix of service subscriptions
- Reserve 20% capacity for overhead
- Reserve 10% for infrastructure services

## Growth Projections

| Month | Tenants | Total Containers | RAM Used | CPU Used | Storage Used |
|-------|---------|------------------|----------|----------|--------------|
| 1     | 5       | 25               | 40GB     | 40 cores | 200GB        |
| 3     | 15      | 75               | 120GB    | 120 cores| 600GB        |
| 6     | 30      | 150              | 180GB    | 180 cores| 1.2TB        |
| 12    | 50      | 250              | **250GB**| **250 cores** | 2TB     |

**Note:** At month 6-12, will need to add second Proxmox host or upgrade existing.

## Backup Strategy

### Backup Targets

| Target           | Type      | Location              | Retention        |
|------------------|-----------|-----------------------|------------------|
| Synology NAS     | Primary   | 192.168.0.25          | 30 days daily    |
| Cloud (Future)   | Secondary | AWS S3 / Backblaze B2 | 90 days          |

### Backup Schedule

| Component            | Frequency | Time  | Destination      |
|----------------------|-----------|-------|------------------|
| Master Database      | Daily     | 2:00  | Synology + Local |
| Customer Containers  | Daily     | 2:00  | Synology         |
| Configuration Files  | Daily     | 3:00  | Synology         |
| LXC Snapshots        | Weekly    | Sun   | Local storage    |
| VM Snapshots         | Weekly    | Sun   | Local storage    |

### Recovery Time Objectives (RTO)

| Component            | RTO       | Recovery Method              |
|----------------------|-----------|------------------------------|
| Master Database      | 1 hour    | Restore from backup          |
| Single Service       | 30 min    | Restore container snapshot   |
| Single Tenant        | 1 hour    | Restore all tenant containers|
| Entire Platform      | 4 hours   | Full disaster recovery       |

## Monitoring & Alerting

### Metrics Collected

- Container CPU/RAM/Disk usage
- Network throughput
- Service health checks
- Database connections
- API response times
- Backup success/failure
- Security events (via Wazuh)

### Alert Thresholds

| Metric                | Warning | Critical | Action                    |
|-----------------------|---------|----------|---------------------------|
| CPU Usage             | 70%     | 90%      | Scale resources           |
| RAM Usage             | 80%     | 95%      | Scale resources           |
| Disk Usage            | 75%     | 90%      | Cleanup or expand         |
| Service Down          | -       | 1 check  | Auto-restart              |
| Backup Failure        | -       | 1 day    | Admin notification        |
| Security Alert        | -       | Any      | Immediate investigation   |

## Access Control

### SSH Access

| User      | Containers            | Purpose              |
|-----------|-----------------------|----------------------|
| root      | All                   | Emergency access     |
| aiqso     | 150, 200, 110         | AIQSO platform       |
| deploy    | All customer          | Deployment scripts   |

### Database Access

| User          | Database      | Permissions          |
|---------------|---------------|----------------------|
| aiqso_admin   | aiqso_master  | All (platform)       |
| aiqso_app     | aiqso_master  | Read/Write (app)     |
| tenant_*      | tenant_*      | All (tenant DB)      |

## Maintenance Windows

| Task                      | Frequency | Day       | Time        | Duration |
|---------------------------|-----------|-----------|-------------|----------|
| System updates            | Monthly   | 1st Sun   | 2:00-4:00   | 2 hours  |
| Database maintenance      | Weekly    | Sunday    | 3:00-3:30   | 30 min   |
| Backup verification       | Monthly   | 15th      | 2:00-3:00   | 1 hour   |
| Security patching         | As needed | Any       | 2:00-4:00   | 2 hours  |

## Change Log

| Date       | Change                              | By    |
|------------|-------------------------------------|-------|
| 2025-09-29 | Initial infrastructure setup        | AI    |
| TBD        | Deploy Master DB and Vector Broker  | -     |
| TBD        | First tenant onboarded              | -     |