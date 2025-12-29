Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   COMPLETE SYSTEM FIX & VERIFICATION" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

# Step 1: Get all IPs
Write-Host "`n📡 Step 1: Getting Service IPs..." -ForegroundColor Yellow
$FRONTEND_IP = kubectl get svc frontend-service -n production -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
$PROMETHEUS_IP = kubectl get svc prometheus-service -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
$GRAFANA_IP = kubectl get svc grafana-service -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

Write-Host "Frontend:   http://$FRONTEND_IP" -ForegroundColor White
Write-Host "Prometheus: http://$PROMETHEUS_IP:9090" -ForegroundColor White
Write-Host "Grafana:    http://$GRAFANA_IP:3000" -ForegroundColor White

# Step 2: Check MongoDB
Write-Host "`n🔍 Step 2: Checking MongoDB..." -ForegroundColor Yellow
$mongoStatus = kubectl get pod mongodb-0 -n production -o jsonpath='{.status.phase}'
if ($mongoStatus -eq "Running") {
    Write-Host "✅ MongoDB is Running" -ForegroundColor Green
    
    # Test MongoDB connection
    Write-Host "Testing MongoDB ping..." -ForegroundColor Cyan
    kubectl exec -n production mongodb-0 -- mongosh --eval "db.adminCommand('ping')" 2>$null
} else {
    Write-Host "❌ MongoDB is $mongoStatus" -ForegroundColor Red
}

# Step 3: Restart Backend
Write-Host "`n🔄 Step 3: Restarting Backend..." -ForegroundColor Yellow
kubectl rollout restart deployment backend -n production
Write-Host "Waiting for backend rollout..." -ForegroundColor Cyan
kubectl rollout status deployment/backend -n production --timeout=120s

Start-Sleep -Seconds 10

# Step 4: Verify All Pods
Write-Host "`n📦 Step 4: Pod Status..." -ForegroundColor Yellow
kubectl get pods -n production
kubectl get pods -n monitoring

# Step 5: Test Backend Health
Write-Host "`n🏥 Step 5: Testing Backend Health..." -ForegroundColor Yellow
$maxRetries = 5
$retry = 0
$success = $false

while ($retry -lt $maxRetries -and -not $success) {
    try {
        $health = Invoke-RestMethod -Uri "http://$FRONTEND_IP/api/health" -TimeoutSec 10
        Write-Host "✅ Backend Status: $($health.status)" -ForegroundColor Green
        Write-Host "✅ Database: $($health.database)" -ForegroundColor Green
        Write-Host "✅ Timestamp: $($health.timestamp)" -ForegroundColor Green
        $success = $true
    } catch {
        $retry++
        Write-Host "⏳ Retry $retry/$maxRetries..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
    }
}

if (-not $success) {
    Write-Host "❌ Backend health check failed after $maxRetries retries" -ForegroundColor Red
    Write-Host "`nChecking backend logs..." -ForegroundColor Yellow
    $BACKEND_POD = kubectl get pod -n production -l app=backend -o jsonpath='{.items[0].metadata.name}'
    kubectl logs -n production $BACKEND_POD --tail=30
}

# Step 6: Test Prometheus
Write-Host "`n📊 Step 6: Testing Prometheus..." -ForegroundColor Yellow
try {
    $prom = Invoke-WebRequest -Uri "http://$PROMETHEUS_IP:9090/-/healthy" -UseBasicParsing -TimeoutSec 5
    Write-Host "✅ Prometheus: $($prom.Content)" -ForegroundColor Green
} catch {
    Write-Host "❌ Prometheus not accessible" -ForegroundColor Red
}

# Step 7: Test Grafana
Write-Host "`n📈 Step 7: Testing Grafana..." -ForegroundColor Yellow
try {
    $grafana = Invoke-WebRequest -Uri "http://$GRAFANA_IP:3000/api/health" -UseBasicParsing -TimeoutSec 5
    Write-Host "✅ Grafana: Running" -ForegroundColor Green
} catch {
    Write-Host "❌ Grafana not accessible" -ForegroundColor Red
}

# Step 8: Create Test Data
if ($success) {
    Write-Host "`n🧪 Step 8: Creating Test Data..." -ForegroundColor Yellow
    try {
        # Clear any existing data first
        Start-Sleep -Seconds 2
        
        $task1 = @{
            title = "DevOps Project Setup Complete"
            description = "Successfully deployed MERN app on GKE"
            priority = "high"
            status = "completed"
        } | ConvertTo-Json

        $result1 = Invoke-RestMethod -Uri "http://$FRONTEND_IP/api/tasks" `
            -Method POST `
            -Body $task1 `
            -ContentType "application/json" `
            -TimeoutSec 10
        
        Write-Host "✅ Created task: $($result1.title)" -ForegroundColor Green

        Start-Sleep -Seconds 1

        $task2 = @{
            title = "Configure Monitoring"
            description = "Setup Grafana dashboards"
            priority = "high"
            status = "in-progress"
        } | ConvertTo-Json

        $result2 = Invoke-RestMethod -Uri "http://$FRONTEND_IP/api/tasks" `
            -Method POST `
            -Body $task2 `
            -ContentType "application/json" `
            -TimeoutSec 10
        
        Write-Host "✅ Created task: $($result2.title)" -ForegroundColor Green

        Start-Sleep -Seconds 1

        Write-Host "`n📊 Getting Statistics..." -ForegroundColor Cyan
        $stats = Invoke-RestMethod -Uri "http://$FRONTEND_IP/api/stats" -TimeoutSec 10
        Write-Host "Total Tasks: $($stats.totalTasks)" -ForegroundColor White
        Write-Host "Completed: $($stats.completedTasks)" -ForegroundColor Green
        Write-Host "Pending: $($stats.pendingTasks)" -ForegroundColor Yellow
        Write-Host "In Progress: $($stats.inProgressTasks)" -ForegroundColor Cyan
        
    } catch {
        Write-Host "❌ Could not create test data: $_" -ForegroundColor Red
    }
}

# Final Summary
Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   SYSTEM STATUS SUMMARY" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

Write-Host "`n🌐 ACCESS URLS:" -ForegroundColor Green
Write-Host "Frontend:   http://$FRONTEND_IP" -ForegroundColor White
Write-Host "Prometheus: http://$PROMETHEUS_IP:9090" -ForegroundColor White
Write-Host "Grafana:    http://$GRAFANA_IP:3000 (admin/admin123)" -ForegroundColor White
Write-Host "Jenkins:    http://34.59.247.214:8080" -ForegroundColor White

# Save to file
@"
═══════════════════════════════════════════════════════════
   DEVOPS GCP PROJECT - FINAL ACCESS INFORMATION
═══════════════════════════════════════════════════════════

🌐 APPLICATION
Frontend: http://$FRONTEND_IP

📊 MONITORING
Prometheus: http://$PROMETHEUS_IP:9090
Grafana:    http://$GRAFANA_IP:3000
  Username: admin
  Password: admin123

🔄 CI/CD
Jenkins: http://34.59.247.214:8080

Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
═══════════════════════════════════════════════════════════
"@ | Out-File -FilePath SYSTEM_ACCESS.txt -Encoding UTF8

Write-Host "`n📄 Access info saved to SYSTEM_ACCESS.txt" -ForegroundColor Cyan

# Open services
Write-Host "`n🌐 Opening services in browser..." -ForegroundColor Yellow
Start-Process "http://$FRONTEND_IP"
Start-Process "http://$PROMETHEUS_IP:9090"
Start-Process "http://$GRAFANA_IP:3000"

Write-Host "`n✅ VERIFICATION COMPLETE!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
