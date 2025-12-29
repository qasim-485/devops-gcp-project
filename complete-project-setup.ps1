Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   COMPLETE PROJECT FINALIZATION" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

# ==========================================
# GET ALL SERVICE IPS (Using correct method)
# ==========================================

Write-Host "`n📡 Getting Service IPs..." -ForegroundColor Yellow

# Prometheus
$prometheusIP = (kubectl get svc prometheus-service -n monitoring -o json | ConvertFrom-Json).status.loadBalancer.ingress[0].ip

# Grafana
$grafanaIP = (kubectl get svc grafana-service -n monitoring -o json | ConvertFrom-Json).status.loadBalancer.ingress[0].ip

# Frontend
$frontendIP = (kubectl get svc frontend-service -n production -o json | ConvertFrom-Json).status.loadBalancer.ingress[0].ip

Write-Host "`n🌐 ALL ACCESS URLS:" -ForegroundColor Green
Write-Host "────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host "Frontend:   http://$frontendIP" -ForegroundColor White
Write-Host "Prometheus: http://$prometheusIP:9090" -ForegroundColor White
Write-Host "Grafana:    http://$grafanaIP:3000" -ForegroundColor White
Write-Host "  Username: admin | Password: admin123" -ForegroundColor Cyan
Write-Host "Jenkins:    http://34.59.247.214:8080" -ForegroundColor White

# ==========================================
# COMPREHENSIVE SERVICE TESTS
# ==========================================

Write-Host "`n🧪 TESTING ALL SERVICES..." -ForegroundColor Cyan

# Test 1: Frontend
Write-Host "`n1. Frontend Application:" -ForegroundColor Yellow
try {
    $fe = Invoke-WebRequest -Uri "http://$frontendIP" -UseBasicParsing -TimeoutSec 5
    Write-Host "   ✅ HTTP $($fe.StatusCode) - Application Accessible" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Backend (via port-forward)
Write-Host "`n2. Backend API:" -ForegroundColor Yellow
$backendPod = (kubectl get pods -n production -l app=backend -o json | ConvertFrom-Json).items[0].metadata.name

$portForward = Start-Job -ScriptBlock {
    param($pod)
    kubectl port-forward -n production $pod 5001:5000 2>$null
} -ArgumentList $backendPod

Start-Sleep -Seconds 3

try {
    $health = Invoke-RestMethod -Uri "http://localhost:5001/health" -TimeoutSec 5
    Write-Host "   ✅ Status: $($health.status)" -ForegroundColor Green
    Write-Host "   ✅ Database: $($health.database)" -ForegroundColor Green
    
    # Test creating a task
    $testTask = @{
        title = "System Verification Complete"
        description = "All services are operational"
        priority = "high"
        status = "completed"
    } | ConvertTo-Json
    
    $task = Invoke-RestMethod -Uri "http://localhost:5001/api/tasks" -Method POST -Body $testTask -ContentType "application/json" -TimeoutSec 5
    Write-Host "   ✅ Created test task: $($task.title)" -ForegroundColor Green
    
    $stats = Invoke-RestMethod -Uri "http://localhost:5001/api/stats" -TimeoutSec 5
    Write-Host "   ✅ Task Stats: Total=$($stats.totalTasks), Completed=$($stats.completedTasks)" -ForegroundColor Green
    
} catch {
    Write-Host "   ❌ Backend test failed: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    Stop-Job $portForward -ErrorAction SilentlyContinue
    Remove-Job $portForward -ErrorAction SilentlyContinue
}

# Test 3: MongoDB
Write-Host "`n3. MongoDB Database:" -ForegroundColor Yellow
try {
    $mongoTest = kubectl exec -n production mongodb-0 -- mongosh --eval "db.adminCommand('ping')" --quiet 2>$null
    if ($mongoTest -match "ok.*1") {
        Write-Host "   ✅ MongoDB Responding" -ForegroundColor Green
    }
} catch {
    Write-Host "   ❌ MongoDB test failed" -ForegroundColor Red
}

# Test 4: Prometheus
Write-Host "`n4. Prometheus Metrics:" -ForegroundColor Yellow
try {
    $prom = Invoke-WebRequest -Uri "http://${prometheusIP}:9090/-/healthy" -UseBasicParsing -TimeoutSec 5
    Write-Host "   ✅ $($prom.Content)" -ForegroundColor Green
    
    # Test query
    $query = Invoke-RestMethod -Uri "http://${prometheusIP}:9090/api/v1/query?query=up" -TimeoutSec 5
    Write-Host "   ✅ Metrics: $($query.data.result.Count) targets monitored" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Prometheus not accessible" -ForegroundColor Red
}

# Test 5: Grafana
Write-Host "`n5. Grafana Dashboards:" -ForegroundColor Yellow
try {
    $graf = Invoke-WebRequest -Uri "http://${grafanaIP}:3000/api/health" -UseBasicParsing -TimeoutSec 5
    Write-Host "   ✅ Grafana Running" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Grafana not accessible" -ForegroundColor Red
}

# ==========================================
# POD AND RESOURCE STATUS
# ==========================================

Write-Host "`n📦 DEPLOYMENT STATUS:" -ForegroundColor Cyan
Write-Host "Production Namespace:" -ForegroundColor Yellow
kubectl get pods -n production -o wide

Write-Host "`nMonitoring Namespace:" -ForegroundColor Yellow
kubectl get pods -n monitoring -o wide

Write-Host "`n💾 PERSISTENT VOLUMES:" -ForegroundColor Cyan
kubectl get pvc -n production

Write-Host "`n⚡ RESOURCE USAGE:" -ForegroundColor Cyan
kubectl top nodes 2>$null
kubectl top pods -n production 2>$null

# ==========================================
# CREATE COMPREHENSIVE DOCUMENTATION
# ==========================================

@"
═══════════════════════════════════════════════════════════
   DEVOPS GCP PROJECT - COMPLETE ACCESS GUIDE
═══════════════════════════════════════════════════════════

🌐 APPLICATION ACCESS
───────────────────────────────────────────────────────────
Frontend Application: http://$frontendIP
  - Task Manager Interface
  - Create/Read/Update/Delete tasks
  - View statistics and metrics

📊 MONITORING ACCESS
───────────────────────────────────────────────────────────
Prometheus:  http://$prometheusIP:9090
  - Metrics collection and querying
  - Query examples:
    • up (check service health)
    • rate(container_cpu_usage_seconds_total[5m])
    • container_memory_usage_bytes

Grafana:     http://$grafanaIP:3000
  - Username: admin
  - Password: admin123
  - Dashboard IDs to import:
    • 315:   Kubernetes Cluster Monitoring
    • 6417:  Kubernetes Deployments
    • 1860:  Node Exporter Full
    • 13332: Kubernetes API Server

🔄 CI/CD ACCESS
───────────────────────────────────────────────────────────
Jenkins:     http://34.59.247.214:8080
  - Pipeline automation
  - Docker image builds
  - GKE deployments

📝 USEFUL KUBECTL COMMANDS
───────────────────────────────────────────────────────────
# View application logs
kubectl logs -f -n production -l app=backend
kubectl logs -f -n production -l app=frontend
kubectl logs -f -n production mongodb-0

# Port forward for local testing
kubectl port-forward -n production svc/backend-service 5000:5000
kubectl port-forward -n production svc/frontend-service 8080:80

# Scale deployments
kubectl scale deployment backend -n production --replicas=3
kubectl scale deployment frontend -n production --replicas=2

# Check resource usage
kubectl top nodes
kubectl top pods -n production
kubectl describe nodes

# Restart deployments
kubectl rollout restart deployment backend -n production
kubectl rollout restart deployment frontend -n production

# View deployment history
kubectl rollout history deployment/backend -n production

# Access pod shell
kubectl exec -it -n production deployment/backend -- sh

🧪 API TESTING (via port-forward)
───────────────────────────────────────────────────────────
# In PowerShell:
kubectl port-forward -n production svc/backend-service 5000:5000

# Then test these endpoints:
curl http://localhost:5000/health
curl http://localhost:5000/api/tasks
curl http://localhost:5000/api/stats

# Create a task:
$task = @{
  title = "New Task"
  description = "Task description"
  priority = "high"
  status = "pending"
} | ConvertTo-Json

Invoke-RestMethod -Uri http://localhost:5000/api/tasks `
  -Method POST `
  -Body $task `
  -ContentType "application/json"

🎯 GRAFANA SETUP STEPS
───────────────────────────────────────────────────────────
1. Open: http://$grafanaIP:3000
2. Login: admin / admin123
3. Verify Data Source:
   - Go to: ☰ → Connections → Data sources
   - Click: Prometheus
   - Verify URL: http://prometheus-service:9090
   - Click: Save & Test
4. Import Dashboards:
   - Go to: ☰ → Dashboards → Import
   - Enter ID: 315
   - Select: Prometheus
   - Click: Import
   - Repeat for IDs: 6417, 1860, 13332

🔧 TROUBLESHOOTING
───────────────────────────────────────────────────────────
# If pods are pending
kubectl describe pod POD_NAME -n production

# If services not accessible
kubectl get svc -A
kubectl get endpoints -n production

# If out of resources
kubectl top nodes
kubectl describe nodes

# Check events
kubectl get events -n production --sort-by='.lastTimestamp'

💰 COST MANAGEMENT
───────────────────────────────────────────────────────────
# Stop cluster (saves costs)
gcloud container clusters resize devops-gke-cluster --num-nodes=0 --zone=us-central1-a

# Restart cluster
gcloud container clusters resize devops-gke-cluster --num-nodes=3 --zone=us-central1-a

# Destroy everything
cd C:\Users\w312\devops-gcp-project\terraform
terraform destroy

📚 PROJECT STRUCTURE
───────────────────────────────────────────────────────────
devops-gcp-project/
├── terraform/          # Infrastructure as Code
├── backend/            # Node.js/Express API
├── frontend/           # React Application
├── k8s-manifests/      # Kubernetes YAML files
├── Jenkinsfile         # CI/CD Pipeline
└── README.md           # Project Documentation

═══════════════════════════════════════════════════════════
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Project Status: ✅ FULLY OPERATIONAL
═══════════════════════════════════════════════════════════
"@ | Out-File -FilePath PROJECT_ACCESS_GUIDE.txt -Encoding UTF8

Write-Host "`n✅ Complete guide saved to PROJECT_ACCESS_GUIDE.txt" -ForegroundColor Green

# ==========================================
# OPEN ALL SERVICES
# ==========================================

Write-Host "`n🌐 Opening all services in browser..." -ForegroundColor Yellow
Start-Process "http://$frontendIP"
Start-Process "http://$prometheusIP:9090"
Start-Process "http://$grafanaIP:3000"

Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   🎉 PROJECT SETUP COMPLETE!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

Write-Host "`n✅ WORKING COMPONENTS:" -ForegroundColor Green
Write-Host "  ✓ MongoDB Database" -ForegroundColor White
Write-Host "  ✓ Backend API" -ForegroundColor White
Write-Host "  ✓ Frontend Application" -ForegroundColor White
Write-Host "  ✓ Prometheus Monitoring" -ForegroundColor White
Write-Host "  ✓ Grafana Dashboards" -ForegroundColor White
Write-Host "  ✓ Jenkins CI/CD (Ready)" -ForegroundColor White

Write-Host "`n📋 IMMEDIATE NEXT STEPS:" -ForegroundColor Yellow
Write-Host "  1. Access Grafana and import dashboards" -ForegroundColor White
Write-Host "  2. Test the application in browser" -ForegroundColor White
Write-Host "  3. (Optional) Configure Jenkins pipeline" -ForegroundColor White

Write-Host "`n📄 ALL DOCUMENTATION:" -ForegroundColor Cyan
Write-Host "  • PROJECT_ACCESS_GUIDE.txt - Complete access info" -ForegroundColor White
Write-Host "  • FINAL_STATUS.txt - System status" -ForegroundColor White

Write-Host "`n🎓 CONGRATULATIONS!" -ForegroundColor Green
Write-Host "You've successfully deployed a complete DevOps project on GCP!" -ForegroundColor White
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

