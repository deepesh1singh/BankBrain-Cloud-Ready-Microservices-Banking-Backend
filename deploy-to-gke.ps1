# BankBrain GKE Deployment Script
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

Write-Host "Starting BankBrain deployment to GKE..." -ForegroundColor Green
Write-Host "Project ID: $ProjectId" -ForegroundColor Cyan
Write-Host "Region: $Region" -ForegroundColor Cyan
Write-Host "Tag: $Tag" -ForegroundColor Cyan
Write-Host "Zone: $Zone" -ForegroundColor Cyan
Write-Host ""

# Set environment variables
$env:PROJECT_ID = $ProjectId
$env:REGION = $Region
$env:TAG = $Tag

Write-Host "Authenticating with Google Cloud..." -ForegroundColor Yellow
gcloud auth login
gcloud config set project $ProjectId
gcloud container clusters get-credentials bankbrain-cluster --zone $Zone

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to get cluster credentials. Please ensure your cluster exists." -ForegroundColor Red
    Write-Host "Create cluster with: gcloud container clusters create bankbrain-cluster --zone $Zone --num-nodes=3" -ForegroundColor Yellow
    exit 1
}

Write-Host "Cluster credentials obtained successfully!" -ForegroundColor Green
Write-Host ""

Write-Host "Building and pushing Docker images..." -ForegroundColor Yellow

# Support Agent
Write-Host "Building Support Agent..." -ForegroundColor Cyan
docker build -t gcr.io/$ProjectId/support-agent:$Tag ./agents/support-agent
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to build support-agent" -ForegroundColor Red
    exit 1
}
docker push gcr.io/$ProjectId/support-agent:$Tag
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to push support-agent" -ForegroundColor Red
    exit 1
}

# Risk Agent
Write-Host "Building Risk Agent..." -ForegroundColor Cyan
docker build -t gcr.io/$ProjectId/risk-agent:$Tag ./agents/risk-agent
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to build risk-agent" -ForegroundColor Red
    exit 1
}
docker push gcr.io/$ProjectId/risk-agent:$Tag
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to push risk-agent" -ForegroundColor Red
    exit 1
}

# MCP Server
Write-Host "Building MCP Server..." -ForegroundColor Cyan
docker build -t gcr.io/$ProjectId/mcp-server:$Tag ./mcp/bank_mcp_server
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to build mcp-server" -ForegroundColor Red
    exit 1
}
docker push gcr.io/$ProjectId/mcp-server:$Tag
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to push mcp-server" -ForegroundColor Red
    exit 1
}

# A2A Gateway
Write-Host "Building A2A Gateway..." -ForegroundColor Cyan
docker build -t gcr.io/$ProjectId/a2a-gateway:$Tag ./agents/a2a-gateway
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to build a2a-gateway" -ForegroundColor Red
    exit 1
}
docker push gcr.io/$ProjectId/a2a-gateway:$Tag
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to push a2a-gateway" -ForegroundColor Red
    exit 1
}

Write-Host "All images built and pushed successfully!" -ForegroundColor Green
Write-Host ""

Write-Host "Updating Kubernetes manifests..." -ForegroundColor Yellow

# Update support-agent.yaml
$supportAgentContent = Get-Content "k8s/support-agent.yaml" -Raw
$supportAgentContent = $supportAgentContent -replace "REPLACE_WITH_REGISTRY/bankbrain-support-agent:REPLACE_TAG", "gcr.io/$ProjectId/support-agent:$Tag"
Set-Content "k8s/support-agent.yaml" $supportAgentContent

# Update risk-agent.yaml
$riskAgentContent = Get-Content "k8s/risk-agent.yaml" -Raw
$riskAgentContent = $riskAgentContent -replace "REPLACE_WITH_REGISTRY/bankbrain-risk-agent:REPLACE_TAG", "gcr.io/$ProjectId/risk-agent:$Tag"
Set-Content "k8s/risk-agent.yaml" $riskAgentContent

# Update mcp-bank-server.yaml
$mcpServerContent = Get-Content "k8s/mcp-bank-server.yaml" -Raw
$mcpServerContent = $mcpServerContent -replace "REPLACE_WITH_REGISTRY/bankbrain-mcp-server:REPLACE_TAG", "gcr.io/$ProjectId/mcp-server:$Tag"
Set-Content "k8s/mcp-bank-server.yaml" $mcpServerContent

# Update a2a-gateway.yaml
$a2aGatewayContent = Get-Content "k8s/a2a-gateway.yaml" -Raw
$a2aGatewayContent = $a2aGatewayContent -replace "REPLACE_WITH_REGISTRY/bankbrain-a2a-gateway:REPLACE_TAG", "gcr.io/$ProjectId/a2a-gateway:$Tag"
Set-Content "k8s/a2a-gateway.yaml" $a2aGatewayContent

Write-Host "Kubernetes manifests updated!" -ForegroundColor Green
Write-Host ""

Write-Host "Deploying to GKE..." -ForegroundColor Yellow
kubectl apply -f k8s/

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to deploy to GKE" -ForegroundColor Red
    exit 1
}

Write-Host "Deployment successful!" -ForegroundColor Green
Write-Host ""

Write-Host "Waiting for pods to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app=support-agent -n bankbrain --timeout=300s
kubectl wait --for=condition=ready pod -l app=risk-agent -n bankbrain --timeout=300s
kubectl wait --for=condition=ready pod -l app=mcp-bank-server -n bankbrain --timeout=300s
kubectl wait --for=condition=ready pod -l app=a2a-gateway -n bankbrain --timeout=300s

Write-Host "All pods are ready!" -ForegroundColor Green
Write-Host ""

Write-Host "Current deployment status:" -ForegroundColor Cyan
kubectl get pods -n bankbrain
Write-Host ""

Write-Host "Services:" -ForegroundColor Cyan
kubectl get svc -n bankbrain
Write-Host ""

Write-Host "Next steps:" -ForegroundColor Green
Write-Host "1. Test locally with: kubectl port-forward svc/support-agent 8080:80 -n bankbrain" -ForegroundColor White
Write-Host "2. Open browser to: http://localhost:8080" -ForegroundColor White
Write-Host "3. Try asking: 'Show my last 5 transactions'" -ForegroundColor White
Write-Host ""
Write-Host "Or check public ingress: kubectl get ingress -n bankbrain" -ForegroundColor White
Write-Host ""
Write-Host "Deployment completed successfully!" -ForegroundColor Green
