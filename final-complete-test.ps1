Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   FINAL COMPLETE SYSTEM TEST" -ForegroundColor Cyan  
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

# Get IPs using JSON parsing
$monSvc = kubectl get svc -n monitoring -o json | ConvertFrom-Json
$prodSvc = kubectl get svc -n production -o json | ConvertFrom-Json

$prometheusIP = ($monSvc.items | Where-Object {$_.metadata.name -eq "prometheus-service"}).status.loadBalancer.ingress[0].ip
$grafanaIP = ($monSvc.items | Where-Object {$_.metadata.name -eq "grafana-service"}).status.loadBalancer.ingress[0].ip
$frontendIP = ($prodSvc.items | Where-Object {$_.metadata.name -eq "frontend-service"}).status.loadBalancer.ingress[0].ip

Write-Host "`n🌐 ALL ACCESS URLS:" -ForegroundColor Green
Write-Host "────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host "Frontend:   http://$frontendIP" -ForegroundColor White
Write-Host "Prometheus: http://$prometheusIP:9090" -ForegroundColor White
Write-Host "Grafana:    http://$grafanaIP:3000 (admin/admin123)" -ForegroundColor White
Write-Host "Jenkins:    http://34.59.247.214:8080" -ForegroundColor White

Write-Host "`n🧪 TESTING SERVICES..." -ForegroundColor Cyan

# Test Frontend
Write-Host "`n1. Frontend:" -ForegroundColor Yellow
try {
    $fe = Invoke-WebRequest -Uri "http://$frontendIP" -UseBasicParsing -TimeoutSec 5
    Write-Host "   ✅ HTTP $($fe.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Failed" -ForegroundColor Red
}

# Test Prometheus
Write-Host "`n2. Prometheus:" -ForegroundColor Yellow
try {
    $prom = Invoke-WebRequest -Uri "http://$prometheusIP:9090/-/healthy" -UseBasicParsing -TimeoutSec 5
    Write-Host "   ✅ $($prom.Content)" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Failed" -ForegroundColor Red
}

# Test Grafana
Write-Host "`n3. Grafana:" -ForegroundColor Yellow
try {
    $graf = Invoke-WebRequest -Uri "http://$grafanaIP:3000/api/health" -UseBasicParsing -TimeoutSec 5
    Write-Host "   ✅ Running" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Failed" -ForegroundColor Red
}

# Test Backend via port-forward in background
Write-Host "`n4. Backend (via port-forward):" -ForegroundColor Yellow
$backendPod = (kubectl get pods -n production -l app=backend -o json | ConvertFrom-Json).items[0].metadata.name

# Start port-forward in background
$job = Start-Job -ScriptBlock {
    param($pod)
    kubectl port-forward -n production $pod 5001:5000
} -ArgumentList $backendPod

Start-Sleep -Seconds 3

try {
    $health = Invoke-RestMethod -Uri "http://localhost:5001/health" -TimeoutSec 5
    Write-Host "   ✅ Status: $($health.status)" -ForegroundColor Green
    Write-Host "   ✅ Database: $($health.database)" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Backend health check failed" -ForegroundColor Red
} finally {
    Stop-Job $job
    Remove-Job $job
}

Write-Host "`n📦 POD STATUS:" -ForegroundColor Cyan
kubectl get pods -n production
kubectl get pods -n monitoring

Write-Host "`n📄 Saving complete status..." -ForegroundColor Yellow

@"
═══════════════════════════════════════════════════════════
   DEVOPS GCP PROJECT - FINAL STATUS
═══════════════════════════════════════════════════════════

🌐 ACCESS INFORMATION
───────────────────────────────────────────────────────────
Frontend:   http://$frontendIP
Prometheus: http://$prometheusIP:9090
Grafana:    http://$grafanaIP:3000
  Credentials: admin / admin123
Jenkins:    http://34.59.247.214:8080

📝 QUICK COMMANDS
───────────────────────────────────────────────────────────
# View logs
kubectl logs -f -n production -l app=backend
kubectl logs -f -n production -l app=frontend
kubectl logs -f -n production mongodb-0

# Port forward backend for testing
kubectl port-forward -n production svc/backend-service 5000:5000
# Then visit: http://localhost:5000/health

# Scale applications
kubectl scale deployment backend -n production --replicas=3
kubectl scale deployment frontend -n production --replicas=3

# Check resources
kubectl top nodes
kubectl top pods -n production

═══════════════════════════════════════════════════════════
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
═══════════════════════════════════════════════════════════
"@ | Out-File -FilePath FINAL_STATUS.txt -Encoding UTF8

Write-Host "`n✅ Status saved to FINAL_STATUS.txt" -ForegroundColor Green

Write-Host "`n🌐 Opening all services in browser..." -ForegroundColor Yellow
Start-Process "http://$frontendIP"
Start-Process "http://$prometheusIP:9090"
Start-Process "http://$grafanaIP:3000"

Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   ✅ SYSTEM TEST COMPLETE!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

Write-Host "`n📋 NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Access Grafana and import dashboards (315, 6417, 1860)" -ForegroundColor White
Write-Host "2. Configure Jenkins CI/CD pipeline" -ForegroundColor White
Write-Host "3. Test the application in browser" -ForegroundColor White

