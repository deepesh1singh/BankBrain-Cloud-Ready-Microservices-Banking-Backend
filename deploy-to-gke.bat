@echo off
REM BankBrain GKE Deployment Batch Script
REM Run this script from the project root directory (D:\bankbrain_project)

setlocal enabledelayedexpansion

if "%1"=="" (
    echo Usage: deploy-to-gke.bat ^<PROJECT_ID^> [REGION] [TAG] [ZONE]
    echo Example: deploy-to-gke.bat my-project-id us-central1 v1 us-central1-a
    exit /b 1
)

set PROJECT_ID=%1
set REGION=%2
if "%REGION%"=="" set REGION=us-central1
set TAG=%3
if "%TAG%"=="" set TAG=v1
set ZONE=%4
if "%ZONE%"=="" set ZONE=us-central1-a

echo 🚀 Starting BankBrain deployment to GKE...
echo Project ID: %PROJECT_ID%
echo Region: %REGION%
echo Tag: %TAG%
echo Zone: %ZONE%
echo.

echo 🔐 Authenticating with Google Cloud...
gcloud auth login
gcloud config set project %PROJECT_ID%
gcloud container clusters get-credentials bankbrain-cluster --zone %ZONE%

if %ERRORLEVEL% neq 0 (
    echo ❌ Failed to get cluster credentials. Please ensure your cluster exists.
    echo Create cluster with: gcloud container clusters create bankbrain-cluster --zone %ZONE% --num-nodes=3
    pause
    exit /b 1
)

echo ✅ Cluster credentials obtained successfully!
echo.

echo 🐳 Building and pushing Docker images...

echo Building Support Agent...
docker build -t gcr.io/%PROJECT_ID%/support-agent:%TAG% ./agents/support-agent
if %ERRORLEVEL% neq 0 (
    echo ❌ Failed to build support-agent
    pause
    exit /b 1
)
docker push gcr.io/%PROJECT_ID%/support-agent:%TAG%
if %ERRORLEVEL% neq 0 (
    echo ❌ Failed to push support-agent
    pause
    exit /b 1
)

echo Building Risk Agent...
docker build -t gcr.io/%PROJECT_ID%/risk-agent:%TAG% ./agents/risk-agent
if %ERRORLEVEL% neq 0 (
    echo ❌ Failed to build risk-agent
    pause
    exit /b 1
)
docker push gcr.io/%PROJECT_ID%/risk-agent:%TAG%
if %ERRORLEVEL% neq 0 (
    echo ❌ Failed to push risk-agent
    pause
    exit /b 1
)

echo Building MCP Server...
docker build -t gcr.io/%PROJECT_ID%/mcp-server:%TAG% ./mcp/bank_mcp_server
if %ERRORLEVEL% neq 0 (
    echo ❌ Failed to build mcp-server
    pause
    exit /b 1
)
docker push gcr.io/%PROJECT_ID%/mcp-server:%TAG%
if %ERRORLEVEL% neq 0 (
    echo ❌ Failed to push mcp-server
    pause
    exit /b 1
)

echo Building A2A Gateway...
docker build -t gcr.io/%PROJECT_ID%/a2a-gateway:%TAG% ./agents/a2a-gateway
if %ERRORLEVEL% neq 0 (
    echo ❌ Failed to build a2a-gateway
    pause
    exit /b 1
)
docker push gcr.io/%PROJECT_ID%/a2a-gateway:%TAG%
if %ERRORLEVEL% neq 0 (
    echo ❌ Failed to push a2a-gateway
    pause
    exit /b 1
)

echo ✅ All images built and pushed successfully!
echo.

echo 📝 Updating Kubernetes manifests...

powershell -Command "(Get-Content 'k8s/support-agent.yaml') -replace 'REPLACE_WITH_REGISTRY/bankbrain-support-agent:REPLACE_TAG', 'gcr.io/%PROJECT_ID%/support-agent:%TAG%' | Set-Content 'k8s/support-agent.yaml'"
powershell -Command "(Get-Content 'k8s/risk-agent.yaml') -replace 'REPLACE_WITH_REGISTRY/bankbrain-risk-agent:REPLACE_TAG', 'gcr.io/%PROJECT_ID%/risk-agent:%TAG%' | Set-Content 'k8s/risk-agent.yaml'"
powershell -Command "(Get-Content 'k8s/mcp-bank-server.yaml') -replace 'REPLACE_WITH_REGISTRY/bankbrain-mcp-server:REPLACE_TAG', 'gcr.io/%PROJECT_ID%/mcp-server:%TAG%' | Set-Content 'k8s/mcp-bank-server.yaml'"
powershell -Command "(Get-Content 'k8s/a2a-gateway.yaml') -replace 'REPLACE_WITH_REGISTRY/bankbrain-a2a-gateway:REPLACE_TAG', 'gcr.io/%PROJECT_ID%/a2a-gateway:%TAG%' | Set-Content 'k8s/a2a-gateway.yaml'"

echo ✅ Kubernetes manifests updated!
echo.

echo 🚀 Deploying to GKE...
kubectl apply -f k8s/

if %ERRORLEVEL% neq 0 (
    echo ❌ Failed to deploy to GKE
    pause
    exit /b 1
)

echo ✅ Deployment successful!
echo.

echo ⏳ Waiting for pods to be ready...
kubectl wait --for=condition=ready pod -l app=support-agent -n bankbrain --timeout=300s
kubectl wait --for=condition=ready pod -l app=risk-agent -n bankbrain --timeout=300s
kubectl wait --for=condition=ready pod -l app=mcp-bank-server -n bankbrain --timeout=300s
kubectl wait --for=condition=ready pod -l app=a2a-gateway -n bankbrain --timeout=300s

echo ✅ All pods are ready!
echo.

echo 📊 Current deployment status:
kubectl get pods -n bankbrain
echo.

echo 🌐 Services:
kubectl get svc -n bankbrain
echo.

echo 🎯 Next steps:
echo 1. Test locally with: kubectl port-forward svc/support-agent 8080:80 -n bankbrain
echo 2. Open browser to: http://localhost:8080
echo 3. Try asking: "Show my last 5 transactions"
echo.
echo Or check public ingress: kubectl get ingress -n bankbrain
echo.
echo 🎉 Deployment completed successfully!
pause
