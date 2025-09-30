# 🚀 AIQSO Platform Setup Instructions

## Architecture
- **GitHub**: Source of truth for all code
- **Proxmox Host**: Runs deployment scripts
- **n8n Container**: Triggers deployments via SSH
- **No PC dependencies**: Everything runs in infrastructure

---

## Step 1: Run Setup on Proxmox Host

**SSH into Proxmox:**
```bash
ssh root@192.168.0.165
```

**Run the setup script:**
```bash
curl -fsSL https://raw.githubusercontent.com/qvidal01/aiqso-platform/master/setup-proxmox-infrastructure.sh | bash
```

**Or manually:**
```bash
cd /root
git clone https://github.com/qvidal01/aiqso-platform.git
cd aiqso-platform
chmod +x setup-proxmox-infrastructure.sh
./setup-proxmox-infrastructure.sh
```

This script will:
- ✅ Clone GitHub repo to `/root/aiqso-platform`
- ✅ Generate SSH keys for n8n container
- ✅ Set up passwordless SSH from n8n to Proxmox
- ✅ Install PostgreSQL client
- ✅ Configure environment variables
- ✅ Test the connection

**Expected output:**
```
✓ Infrastructure Setup Complete!
  ✓ Repository cloned to /root/aiqso-platform
  ✓ n8n container can SSH to Proxmox host
  ✓ PostgreSQL client installed
  ✓ Environment variables configured
```

---

## Step 2: Update Workflow in n8n

Open n8n UI: http://10.10.10.120:5678

**Open the "02 - Service Deployment" workflow**

**Update the "Deploy Service Container" node:**

Current command:
```bash
ssh -i /mnt/c/Users/cyber/.ssh/id_rsa root@192.168.0.165 'cd /home/cyber/aiqso-platform/scripts && ./deploy-service.sh ...'
```

**New command:**
```bash
ssh root@192.168.0.165 'source /root/.aiqso.env && cd /root/aiqso-platform/scripts && ./deploy-service.sh {{$node["Validate Tenant Subscription"].json.tenant_id}} {{$node["Get Service Details"].json.service_key}}'
```

**Save the workflow** (Ctrl+S)

---

## Step 3: Test the Deployment

From your PC:
```bash
cd /home/cyber/aiqso-platform
./test-service-deployment.sh
```

Check execution in n8n UI - should be 🟢 GREEN!

---

## Updating Code

**To update deployment scripts:**
1. Edit files on your PC in `/home/cyber/aiqso-platform/`
2. Commit and push to GitHub: `git add . && git commit -m "message" && git push`
3. On Proxmox: `cd /root/aiqso-platform && git pull`

**Or automate it:**
On Proxmox, set up a cron job:
```bash
# Update repo every hour
0 * * * * cd /root/aiqso-platform && git pull
```

---

## Architecture Diagram

```
┌──────────────┐
│  Your PC     │  ← Stage code, commit, push
│  (WSL)       │
└──────┬───────┘
       │ git push
       ↓
┌──────────────┐
│  GitHub      │  ← Source of truth
│  qvidal01/   │
│  aiqso-      │
│  platform    │
└──────┬───────┘
       │ git pull (manual or cron)
       ↓
┌──────────────────────────────────┐
│  Proxmox Host (192.168.0.165)    │
│  /root/aiqso-platform/           │
│  - scripts/deploy-service.sh     │
│  - scripts/provision-tenant.sh   │
│  - scripts/health-check.sh       │
└──────┬───────────────────────────┘
       │ SSH (passwordless)
       ↓
┌──────────────────────────────────┐
│  n8n Container (LXC 101)         │
│  10.10.10.120                    │
│  - Triggers deployments via SSH  │
│  - Executes: ssh root@proxmox   │
│    'cd /root/aiqso-platform &&   │
│     ./scripts/deploy-service.sh' │
└──────────────────────────────────┘
       │
       ↓
┌──────────────────────────────────┐
│  New Service Containers          │
│  (LXC 302, 303, etc.)            │
└──────────────────────────────────┘
```

---

## Benefits of This Architecture

✅ **No PC dependencies** - Everything runs in infrastructure
✅ **Git-based** - All code in version control
✅ **Secure** - SSH keys, no passwords
✅ **Updatable** - `git pull` to update scripts
✅ **Testable** - Can test locally before pushing
✅ **Scalable** - Easy to add more automation

---

## Troubleshooting

### SSH Connection Fails
```bash
# On Proxmox, test SSH from n8n:
pct exec 101 -- ssh root@192.168.0.165 "echo 'Connected!'"
```

### Script Not Found
```bash
# On Proxmox, verify repo:
ls -la /root/aiqso-platform/scripts/
```

### Permission Denied
```bash
# On Proxmox, fix permissions:
chmod +x /root/aiqso-platform/scripts/*.sh
```

---

**Ready? Run the setup script on Proxmox now!**