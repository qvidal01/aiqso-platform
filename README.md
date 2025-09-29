# AIQSO Platform

Multi-tenant SaaS platform providing modular services (CRM, Document Management, Social Media Manager, Content Creation, etc.) with isolated customer environments at `{customer}.aiqso.io`.

## Overview

- **Domain**: aiqso.io
- **Owner**: QMVidal@gmail.com
- **GitHub**: qvidal01/aiqso-platform
- **Infrastructure**: Proxmox-based with existing containers and VMs

## Key Features

- Multi-tenant architecture with subdomain isolation
- Modular service subscription model
- AI-powered content generation (via Ollama)
- Automated provisioning and deployment (via n8n)
- Centralized logging (Vector → Elasticsearch/Wazuh/Synology)
- Automated backups to Synology NAS

## Architecture

Each customer gets:
- Unique subdomain: `customer-name.aiqso.io`
- Isolated container environment
- Dedicated databases per service
- Subscription-based service access

## Services Available

1. **CRM Suite** - EspoCRM-based customer relationship management
2. **Document Management** - Paperless-NGX document system
3. **Social Media Manager** - Multi-platform scheduling with AI captions
4. **Content Creation Suite** - AI blog generation and SEO tools
5. **Email Marketing** - Listmonk campaign management
6. **Calendar & Scheduling** - CalCom integration

## Infrastructure

### New Deployments
- **LXC 150** (10.10.10.150) - Master Control Database (PostgreSQL)
- **LXC 200** (10.10.10.100) - Vector Log Broker

### Existing Infrastructure (Leveraged)
- **LXC 101** (10.10.10.120) - n8n Automation/Orchestration
- **LXC 119** (10.10.10.11) - Ollama Local LLM
- **LXC 127** - NginxPM Reverse Proxy
- **LXC 107** (10.10.10.111) - Redis Cache
- **VM 202** (10.200.200.123) - Elasticsearch
- **VM 225** (10.200.200.178) - Wazuh Security

### Service Templates (Clone-able)
- **LXC 102** - Paperless-NGX (Document Management)
- **LXC 104** - Listmonk (Email Marketing)
- **LXC 136** - CalCom (Calendar)

## Repository Structure

```
aiqso-platform/
├── docs/              # Architecture and deployment documentation
├── database/          # Master database schema and migrations
├── n8n-workflows/     # Automation workflows for n8n
├── services/          # Service-specific applications
├── frontend/          # Customer and Admin portals
├── scripts/           # Provisioning and management scripts
└── docker/            # Container configurations and templates
```

## Quick Start

See [docs/deployment-guide.md](docs/deployment-guide.md) for full deployment instructions.

## Documentation

- [Architecture Overview](docs/architecture.md)
- [Infrastructure Inventory](docs/infrastructure-inventory.md)
- [Deployment Guide](docs/deployment-guide.md)

## License

Open-source (License TBD)