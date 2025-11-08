# Manual BankBrain GKE Deployment Script
# Run this script from the project root directory (D:\bankbrain_project)

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectId,
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-central1",
    
    [Parameter(Mandatory=$false)]
    [string]$Tag = "v1",
    
    [Parameter(Mandatory=$false)]
    [string]$Zone = "us-central1-a"
)

Write-Host "🚀 BankBrain Manual GKE Deployment" -ForegroundColor Green
Write-Host "Project ID: $ProjectId" -ForegroundColor Cyan
Write-Host "Region: $Region" -ForegroundColor Cyan
Write-Host "Tag: $Tag" -ForegroundColor Cyan
Write-Host "Zone: $Zone" -ForegroundColor Cyan
Write-Host ""

# Set environment variables
$env:PROJECT_ID = $ProjectId
$env:REGION = $Region
$env:TAG = $Tag

Write-Host "Step 1: Google Cloud Authentication" -ForegroundColor Yellow
$continue = Read-Host "Continue with gcloud auth login? (y/n)"
if ($continue -eq "y" -or $continue -eq "Y") {
    gcloud auth login
    gcloud config set project $ProjectId
    gcloud container clusters get-credentials bankbrain-cluster --zone $Zone
}

Write-Host "Step 2: Build and Push Docker Images" -ForegroundColor Yellow
$continue = Read-Host "Continue with building and pushing images? (y/n)"
if ($continue -eq "y" -or $continue -eq "Y") {
    Write-Host "Building Support Agent..." -ForegroundColor Cyan
    docker build -t gcr.io/$ProjectId/support-agent:$Tag ./agents/support-agent
    docker push gcr.io/$ProjectId/support-agent:$Tag
    
    Write-Host "Building Risk Agent..." -ForegroundColor Cyan
    docker build -t gcr.io/$ProjectId/risk-agent:$Tag ./agents/risk-agent
    docker push gcr.io/$ProjectId/risk-agent:$Tag
    
    Write-Host "Building MCP Server..." -ForegroundColor Cyan
    docker build -t gcr.io/$ProjectId/mcp-server:$Tag ./mcp/bank_mcp_server
    docker push gcr.io/$ProjectId/mcp-server:$Tag
    
    Write-Host "Building A2A Gateway..." -ForegroundColor Cyan
    docker build -t gcr.io/$ProjectId/a2a-gateway:$Tag ./agents/a2a-gateway
    docker push gcr.io/$ProjectId/a2a-gateway:$Tag
}

Write-Host "Step 3: Update Kubernetes Manifests" -ForegroundColor Yellow
$continue = Read-Host "Continue with updating manifests? (y/n)"
if ($continue -eq "y" -or $continue -eq "Y") {
    $supportAgentContent = Get-Content "k8s/support-agent.yaml" -Raw
    $supportAgentContent = $supportAgentContent -replace "REPLACE_WITH_REGISTRY/bankbrain-support-agent:REPLACE_TAG", "gcr.io/$ProjectId/support-agent:$Tag"
    Set-Content "k8s/support-agent.yaml" $supportAgentContent
    
    $riskAgentContent = Get-Content "k8s/risk-agent.yaml" -Raw
    $riskAgentContent = $riskAgentContent -replace "REPLACE_WITH_REGISTRY/bankbrain-risk-agent:REPLACE_TAG", "gcr.io/$ProjectId/risk-agent:$Tag"
    Set-Content "k8s/risk-agent.yaml" $riskAgentContent
    
    $mcpServerContent = Get-Content "k8s/mcp-bank-server.yaml" -Raw
    $mcpServerContent = $mcpServerContent -replace "REPLACE_WITH_REGISTRY/bankbrain-mcp-server:REPLACE_TAG", "gcr.io/$ProjectId/mcp-server:$Tag"
    Set-Content "k8s/mcp-bank-server.yaml" $mcpServerContent
    
    $a2aGatewayContent = Get-Content "k8s/a2a-gateway.yaml" -Raw
    $a2aGatewayContent = $a2aGatewayContent -replace "REPLACE_WITH_REGISTRY/bankbrain-a2a-gateway:REPLACE_TAG", "gcr.io/$ProjectId/a2a-gateway:$Tag"
    Set-Content "k8s/a2a-gateway.yaml" $a2aGatewayContent
    
    Write-Host "✅ Manifests updated!" -ForegroundColor Green
}

Write-Host "Step 4: Deploy to GKE" -ForegroundColor Yellow
$continue = Read-Host "Continue with deployment? (y/n)"
if ($continue -eq "y" -or $continue -eq "Y") {
    kubectl apply -f k8s/
}

Write-Host "Step 5: Check Deployment Status" -ForegroundColor Yellow
$continue = Read-Host "Check deployment status? (y/n)"
if ($continue -eq "y" -or $continue -eq "Y") {
    Write-Host "Pods:" -ForegroundColor Cyan
    kubectl get pods -n bankbrain
    
    Write-Host "Services:" -ForegroundColor Cyan
    kubectl get svc -n bankbrain
    
    Write-Host "Ingress:" -ForegroundColor Cyan
    kubectl get ingress -n bankbrain
}

Write-Host "Step 6: Test the Deployment" -ForegroundColor Yellow
$continue = Read-Host "Start port forwarding for testing? (y/n)"
if ($continue -eq "y" -or $continue -eq "Y") {
    Write-Host "Starting port forward for support-agent..." -ForegroundColor Green
    Write-Host "Open browser to: http://localhost:8080" -ForegroundColor White
    Write-Host "Press Ctrl+C to stop port forwarding" -ForegroundColor Yellow
    kubectl port-forward svc/support-agent 8080:80 -n bankbrain
}

Write-Host "🎉 Manual deployment script completed!" -ForegroundColor Green
