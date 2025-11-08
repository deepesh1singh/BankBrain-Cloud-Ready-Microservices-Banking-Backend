# BankBrain Setup and Deployment Script
# This script will help you set up your Google Cloud project and deploy BankBrain

Write-Host "BankBrain Setup and Deployment" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""

# Check if gcloud is installed
try {
    $gcloudVersion = gcloud --version 2>$null
    if ($gcloudVersion) {
        Write-Host "Google Cloud SDK is installed" -ForegroundColor Green
    }
} catch {
    Write-Host "Google Cloud SDK is not installed. Please install it first." -ForegroundColor Red
    Write-Host "Download from: https://cloud.google.com/sdk/docs/install" -ForegroundColor Yellow
    exit 1
}

# Check if kubectl is available
try {
    $kubectlVersion = kubectl version --client 2>$null
    if ($kubectlVersion) {
        Write-Host "kubectl is available" -ForegroundColor Green
    }
} catch {
    Write-Host "kubectl is not available. Please install it first." -ForegroundColor Red
    exit 1
}

# Check if Docker is running
try {
    $dockerVersion = docker --version 2>$null
    if ($dockerVersion) {
        Write-Host "Docker is available" -ForegroundColor Green
    }
} catch {
    Write-Host "Docker is not available or not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Prerequisites check completed!" -ForegroundColor Green
Write-Host ""

# Get project ID from user
$projectId = Read-Host "Enter your Google Cloud Project ID"
if (-not $projectId) {
    Write-Host "Project ID is required. Exiting." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Setting up Google Cloud project..." -ForegroundColor Yellow

# Set the project
gcloud config set project $projectId

# Check if cluster exists
$clusterExists = gcloud container clusters list --filter="name:bankbrain-cluster" --format="value(name)" 2>$null

if (-not $clusterExists) {
    Write-Host "GKE cluster 'bankbrain-cluster' not found. Creating it..." -ForegroundColor Yellow
    Write-Host "This may take several minutes..." -ForegroundColor Yellow
    
    gcloud container clusters create bankbrain-cluster --zone us-central1-a --num-nodes 3 --machine-type e2-standard-2 --enable-autoscaling --min-nodes 1 --max-nodes 5
} else {
    Write-Host "GKE cluster 'bankbrain-cluster' found. Getting credentials..." -ForegroundColor Green
}

# Get cluster credentials
gcloud container clusters get-credentials bankbrain-cluster --zone us-central1-a

Write-Host ""
Write-Host "Google Cloud setup completed!" -ForegroundColor Green
Write-Host ""

# Ask user if they want to proceed with deployment
$proceed = Read-Host "Do you want to proceed with the deployment? (y/n)"
if ($proceed -eq "y" -or $proceed -eq "Y") {
    Write-Host ""
    Write-Host "Starting deployment..." -ForegroundColor Green
    Write-Host ""
    
    # Run the deployment script
    .\deploy-to-gke.ps1 -ProjectId $projectId
} else {
    Write-Host ""
    Write-Host "Setup completed. You can run the deployment later with:" -ForegroundColor Cyan
    Write-Host ".\deploy-to-gke.ps1 -ProjectId $projectId" -ForegroundColor White
    Write-Host ""
    Write-Host "Or check your cluster status with:" -ForegroundColor Cyan
    Write-Host "kubectl cluster-info" -ForegroundColor White
}
