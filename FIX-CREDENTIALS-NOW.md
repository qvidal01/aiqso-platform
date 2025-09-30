# 🔥 AGGRESSIVE CREDENTIAL FIX - DO THIS NOW

## The Problem
n8n workflows don't automatically link credentials after import. Even though "AIQSO Master DB" exists, EVERY PostgreSQL node in EVERY workflow must be manually re-assigned.

---

## ✅ COMPLETE FIX CHECKLIST

### Step 1: Open n8n UI
```
http://10.10.10.120:5678
```

### Step 2: Fix Each Workflow (DO ALL 6 NOW)

#### 🔴 Workflow 1: 01-customer-provisioning
1. Open workflow
2. Click "Create Tenant Record" node → Credentials → Select "AIQSO Master DB"
3. Click "Create Subscription Record" node → Credentials → Select "AIQSO Master DB"
4. Click "Log Audit Entry" node → Credentials → Select "AIQSO Master DB"
5. **SAVE WORKFLOW** (Ctrl+S or click Save button)

#### 🔴 Workflow 2: 02-service-deployment
1. Open workflow
2. Click "Validate Tenant Subscription" node → Credentials → Select "AIQSO Master DB"
3. Click "Get Service Details" node → Credentials → Select "AIQSO Master DB"
4. Click "Update Service Status" node → Credentials → Select "AIQSO Master DB"
5. **SAVE WORKFLOW**

#### 🔴 Workflow 3: 03-backup-orchestration
1. Open workflow
2. Click "Get Active Tenants" node → Credentials → Select "AIQSO Master DB"
3. Click "Log Success" node → Credentials → Select "AIQSO Master DB"
4. Click "Log Failure" node → Credentials → Select "AIQSO Master DB"
5. Click "Get Backup Stats" node → Credentials → Select "AIQSO Master DB"
6. **SAVE WORKFLOW**

#### 🔴 Workflow 4: 04-health-monitoring (Already Done ✅)
Skip - you already fixed this one

#### 🔴 Workflow 5: 05-ai-content-generation
1. Open workflow
2. Click "Validate AI Access" node → Credentials → Select "AIQSO Master DB"
3. Click "Log AI Usage" node → Credentials → Select "AIQSO Master DB"
4. Click "Log Audit Entry" node → Credentials → Select "AIQSO Master DB"
5. **SAVE WORKFLOW**

#### 🔴 Workflow 6: 06-usage-tracking
1. Open workflow
2. Click "Get Active Tenants" node → Credentials → Select "AIQSO Master DB"
3. Click "Get Tenant Services" node → Credentials → Select "AIQSO Master DB"
4. Click "Log Storage Metric" node → Credentials → Select "AIQSO Master DB"
5. Click "Log Database Metric" node → Credentials → Select "AIQSO Master DB"
6. Click "Log API Calls" node → Credentials → Select "AIQSO Master DB"
7. Click "Calculate Monthly Usage" node → Credentials → Select "AIQSO Master DB"
8. **SAVE WORKFLOW**

---

## 🎯 VERIFICATION

After fixing all workflows, verify by executing workflow 02:

```bash
curl -X POST http://10.10.10.120:5678/webhook/deploy-service \
  -H "Content-Type: application/json" \
  -d '{
    "tenant_id": "f0985381-2983-47dd-8cda-e8ad69e3de58",
    "service_key": "email"
  }'
```

Then check executions in n8n UI - should see green success, not red errors.

---

## 📊 Total Nodes to Fix

- Workflow 1: 3 nodes
- Workflow 2: 3 nodes
- Workflow 3: 4 nodes
- Workflow 4: ✅ Done
- Workflow 5: 3 nodes
- Workflow 6: 6 nodes

**Total: 19 PostgreSQL nodes need credentials assigned**

**Estimated time: 10-15 minutes**

---

## 🚨 IMPORTANT

- **Click dropdown and RE-SELECT credential even if it shows selected**
- **Save workflow after each fix (Ctrl+S)**
- **Check for green checkmark on Save button**
- **Do not skip any workflow**

---

## Why This Happens

n8n workflow JSON files only store credential NAME references, not the actual credential links. When workflows are imported:
- Credential name is imported ✅
- Credential link is NOT created ❌
- You must manually click dropdown to create the link
- This is a known n8n behavior, not a bug

---

## After Fixing

Once all 19 nodes are fixed and saved, you'll never have to do this again unless you re-import the workflows.