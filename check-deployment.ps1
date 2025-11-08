# BankBrain Deployment Status Checker
# Run this script to check the health and status of your deployment

Write-Host "🔍 Checking BankBrain Deployment Status..." -ForegroundColor Green
Write-Host ""

Write-Host "📊 Namespace Status:" -ForegroundColor Cyan
kubectl get namespace bankbrain
Write-Host ""

Write-Host "🐳 Pod Status:" -ForegroundColor Cyan
kubectl get pods -n bankbrain -o wide
Write-Host ""

Write-Host "🌐 Services:" -ForegroundColor Cyan
kubectl get svc -n bankbrain
Write-Host ""

Write-Host "🚪 Ingress:" -ForegroundColor Cyan
kubectl get ingress -n bankbrain
Write-Host ""

Write-Host "📈 Horizontal Pod Autoscalers:" -ForegroundColor Cyan
kubectl get hpa -n bankbrain
Write-Host ""

Write-Host "📋 Recent Events:" -ForegroundColor Cyan
kubectl get events -n bankbrain --sort-by='.lastTimestamp' | Select-Object -Last 10
Write-Host ""

Write-Host "💾 ConfigMaps:" -ForegroundColor Cyan
kubectl get configmap -n bankbrain
Write-Host ""

Write-Host "🔍 Pod Logs Summary:" -ForegroundColor Cyan
Write-Host "Support Agent:" -ForegroundColor Yellow
kubectl logs -l app=support-agent -n bankbrain --tail=5 2>$null
Write-Host ""

Write-Host "Risk Agent:" -ForegroundColor Yellow
kubectl logs -l app=risk-agent -n bankbrain --tail=5 2>$null
Write-Host ""

Write-Host "MCP Server:" -ForegroundColor Yellow
kubectl logs -l app=mcp-bank-server -n bankbrain --tail=5 2>$null
Write-Host ""

Write-Host "A2A Gateway:" -ForegroundColor Yellow
kubectl logs -l app=a2a-gateway -n bankbrain --tail=5 2>$null
Write-Host ""

Write-Host "✅ Status check completed!" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Quick Commands:" -ForegroundColor Cyan
Write-Host "  Port forward: kubectl port-forward svc/support-agent 8080:80 -n bankbrain" -ForegroundColor White
Write-Host "  View logs: kubectl logs -f deployment/support-agent -n bankbrain" -ForegroundColor White
Write-Host "  Describe pod: kubectl describe pod <pod-name> -n bankbrain" -ForegroundColor White
