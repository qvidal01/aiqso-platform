#!/bin/bash
# Quick test script for service deployment workflow

echo "🚀 Testing Service Deployment Workflow"
echo "========================================"
echo ""
echo "Tenant ID: f0985381-2983-47dd-8cda-e8ad69e3de58 (testcorp)"
echo "Service: email (Listmonk)"
echo ""
echo "Triggering workflow..."
echo ""

curl -X POST http://10.10.10.120:5678/webhook/deploy-service \
  -H "Content-Type: application/json" \
  -d '{
    "tenant_id": "f0985381-2983-47dd-8cda-e8ad69e3de58",
    "service_key": "email"
  }' \
  -w "\n\nHTTP Status: %{http_code}\n" \
  -s

echo ""
echo "========================================"
echo "Next steps:"
echo "1. Open n8n UI: http://10.10.10.120:5678"
echo "2. Click 'Executions' in left sidebar"
echo "3. Check latest execution of '02 - Service Deployment'"
echo "4. Should see GREEN (success) not RED (error)"
echo ""
echo "If you see RED error about credentials:"
echo "→ Read: /home/cyber/aiqso-platform/FIX-CREDENTIALS-NOW.md"
echo "========================================"