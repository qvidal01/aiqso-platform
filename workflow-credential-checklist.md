# n8n Workflow Credential Checklist

## ✅ Workflows to Update

Each workflow below has PostgreSQL nodes that need the "AIQSO Master DB" credential assigned:

### 1. ✅ 04-health-monitoring (DONE)
- Get Active Services
- Update Health Check - Healthy
- Update Status - Stopped
- Update Status - Degraded
- Log Incident

### 2. 01-customer-provisioning
PostgreSQL Nodes:
- Create Tenant Record
- Create Subscription Record
- Log Audit Entry

### 3. 02-service-deployment
PostgreSQL Nodes:
- Validate Tenant Subscription
- Get Service Details
- Update Service Status

### 4. 03-backup-orchestration
PostgreSQL Nodes:
- Get Active Tenants
- Log Success
- Log Failure
- Get Backup Stats

### 5. 05-ai-content-generation
PostgreSQL Nodes:
- Validate AI Access
- Log AI Usage
- Log Audit Entry

### 6. 06-usage-tracking
PostgreSQL Nodes:
- Get Active Tenants
- Get Tenant Services
- Log Storage Metric
- Log Database Metric
- Log API Calls
- Calculate Monthly Usage

## 📝 How to Fix (Per Workflow):

1. Open the workflow
2. Click each PostgreSQL node (look for database icon)
3. In Parameters → Credential dropdown
4. Re-select "AIQSO Master DB" 
5. Save the workflow
6. Move to next workflow

## ⚡ Quick Test:

After fixing all workflows, manually execute:
- 01-customer-provisioning (will need webhook payload - skip for now)
- 04-health-monitoring (already tested ✅)
- 06-usage-tracking (can execute manually)
