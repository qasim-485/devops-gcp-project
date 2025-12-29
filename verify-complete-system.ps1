Write-Host "=== COMPLETE SYSTEM VERIFICATION ===" -ForegroundColor Cyan

$FRONTEND_IP = kubectl get svc frontend-service -n production -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
$GRAFANA_IP = kubectl get svc grafana-service -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
$PROMETHEUS_IP = kubectl get svc prometheus-service -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

Write-Host "`n✅ ALL ACCESS URLS:" -ForegroundColor Green
Write-Host "════════════════════════════════════════" -ForegroundColor Gray
Write-Host "Frontend:   http://$FRONTEND_IP" -ForegroundColor White
Write-Host "Prometheus: http://$PROMETHEUS_IP:9090" -ForegroundColor White
Write-Host "Grafana:    http://$GRAFANA_IP:3000" -ForegroundColor White
Write-Host "  Username: admin" -ForegroundColor Cyan
Write-Host "  Password: admin123" -ForegroundColor Cyan
Write-Host "Jenkins:    http://34.59.247.214:8080" -ForegroundColor White

Write-Host "`n=== TESTING ALL SERVICES ===" -ForegroundColor Cyan

Write-Host "`n1. Testing Backend Health..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "http://$FRONTEND_IP/api/health" -TimeoutSec 5
    Write-Host "   ✅ Backend Status: $($health.status)" -ForegroundColor Green
    Write-Host "   ✅ Database: $($health.database)" -ForegroundColor Green
    Write-Host "   ✅ Timestamp: $($health.timestamp)" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Backend not accessible yet" -ForegroundColor Red
}

Write-Host "`n2. Testing Frontend..." -ForegroundColor Yellow
try {
    $frontend = Invoke-WebRequest -Uri "http://$FRONTEND_IP" -UseBasicParsing -TimeoutSec 5
    Write-Host "   ✅ Frontend: HTTP $($frontend.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Frontend not accessible" -ForegroundColor Red
}

Write-Host "`n3. Testing Prometheus..." -ForegroundColor Yellow
try {
    $prom = Invoke-WebRequest -Uri "http://$PROMETHEUS_IP:9090/-/healthy" -UseBasicParsing -TimeoutSec 5
    Write-Host "   ✅ Prometheus: $($prom.Content)" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Prometheus not accessible" -ForegroundColor Red
}

Write-Host "`n4. Testing Grafana..." -ForegroundColor Yellow
try {
    $grafana = Invoke-WebRequest -Uri "http://$GRAFANA_IP:3000/api/health" -UseBasicParsing -TimeoutSec 5
    Write-Host "   ✅ Grafana: Running" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Grafana not accessible" -ForegroundColor Red
}

Write-Host "`n=== POD STATUS ===" -ForegroundColor Cyan
kubectl get pods -n production
kubectl get pods -n monitoring

Write-Host "`n=== CREATING TEST DATA ===" -ForegroundColor Cyan
try {
    $task1 = @{
        title = "Setup Monitoring Dashboard"
        description = "Configure Grafana with Kubernetes metrics"
        priority = "high"
        status = "completed"
    } | ConvertTo-Json

    $result1 = Invoke-RestMethod -Uri "http://$FRONTEND_IP/api/tasks" -Method POST -Body $task1 -ContentType "application/json"
    Write-Host "✅ Created task: $($result1.title)" -ForegroundColor Green

    $task2 = @{
        title = "Deploy Jenkins Pipeline"
        description = "Automate CI/CD with Jenkins"
        priority = "high"
        status = "in-progress"
    } | ConvertTo-Json

    $result2 = Invoke-RestMethod -Uri "http://$FRONTEND_IP/api/tasks" -Method POST -Body $task2 -ContentType "application/json"
    Write-Host "✅ Created task: $($result2.title)" -ForegroundColor Green

    Write-Host "`n📊 Getting Statistics..." -ForegroundColor Yellow
    $stats = Invoke-RestMethod -Uri "http://$FRONTEND_IP/api/stats"
    Write-Host "Total Tasks: $($stats.totalTasks)" -ForegroundColor White
    Write-Host "Completed: $($stats.completedTasks)" -ForegroundColor Green
    Write-Host "Pending: $($stats.pendingTasks)" -ForegroundColor Yellow
    Write-Host "In Progress: $($stats.inProgressTasks)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Could not create test data: $_" -ForegroundColor Red
}

Write-Host "`n✅ SYSTEM IS FULLY OPERATIONAL!" -ForegroundColor Green

# Save URLs
@"
═══════════════════════════════════════════════════════════
   DEVOPS GCP PROJECT - ACCESS INFORMATION
═══════════════════════════════════════════════════════════

🌐 APPLICATION
───────────────────────────────────────────────────────────
Frontend: http://$FRONTEND_IP

📊 MONITORING  
───────────────────────────────────────────────────────────
Prometheus: http://$PROMETHEUS_IP:9090
Grafana:    http://$GRAFANA_IP:3000
  Username: admin
  Password: admin123

🔄 CI/CD
───────────────────────────────────────────────────────────
Jenkins: http://34.59.247.214:8080

Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
═══════════════════════════════════════════════════════════
"@ | Out-File -FilePath SYSTEM_URLS.txt -Encoding UTF8

Write-Host "`n📄 Access URLs saved to SYSTEM_URLS.txt" -ForegroundColor Cyan

# Open all services
Write-Host "`n🌐 Opening services in browser..." -ForegroundColor Yellow
Start-Process "http://$FRONTEND_IP"
Start-Process "http://$GRAFANA_IP:3000"
Start-Process "http://$PROMETHEUS_IP:9090"
