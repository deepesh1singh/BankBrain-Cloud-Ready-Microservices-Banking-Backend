# BankBrain Setup Guide

## 🚨 Prerequisites Required

Before you can deploy BankBrain to GKE, you need to install the following tools:

### 1. **Google Cloud SDK** (Required)
Download and install from: https://cloud.google.com/sdk/docs/install

**Windows Installation:**
```powershell
# Download the installer
# Run the installer as administrator
# Restart PowerShell after installation
```

**Verify installation:**
```powershell
gcloud --version
```

### 2. **Docker Desktop** (Required)
Download and install from: https://www.docker.com/products/docker-desktop/

**After installation:**
- Start Docker Desktop
- Wait for Docker to be ready (green icon in system tray)

**Verify installation:**
```powershell
docker --version
```

### 3. **kubectl** (Comes with Google Cloud SDK)
After installing Google Cloud SDK, kubectl should be available.

**Verify installation:**
```powershell
kubectl version --client
```

## 🔧 Alternative Deployment Methods

### Option 1: Google Cloud Console (Web-based)
If you prefer not to install tools locally:

1. **Go to Google Cloud Console**: https://console.cloud.google.com/
2. **Create a GKE cluster**:
   - Navigate to Kubernetes Engine → Clusters
   - Click "Create Cluster"
   - Name: `bankbrain-cluster`
   - Zone: `us-central1-a`
   - Nodes: 3
   - Machine type: `e2-standard-2`
3. **Build and push images**:
   - Navigate to Container Registry
   - Use Cloud Shell to build and push images
4. **Deploy manually**:
   - Update the YAML files with your project ID
   - Apply them through the console

### Option 2: Cloud Shell (Browser-based terminal)
1. **Open Cloud Shell** in Google Cloud Console
2. **Clone your repository**:
   ```bash
   git clone <your-repo-url>
   cd bankbrain_project
   ```
3. **Run the deployment commands**:
   ```bash
   # Set your project ID
   export PROJECT_ID="your-project-id"
   export TAG="v1"
   
   # Build and push images
   docker build -t gcr.io/$PROJECT_ID/support-agent:$TAG ./agents/support-agent
   docker push gcr.io/$PROJECT_ID/support-agent:$TAG
   
   docker build -t gcr.io/$PROJECT_ID/risk-agent:$TAG ./agents/risk-agent
   docker push gcr.io/$PROJECT_ID/risk-agent:$TAG
   
   docker build -t gcr.io/$PROJECT_ID/mcp-server:$TAG ./mcp/bank_mcp_server
   docker push gcr.io/$PROJECT_ID/mcp-server:$TAG
   
   docker build -t gcr.io/$PROJECT_ID/a2a-gateway:$TAG ./agents/a2a-gateway
   docker push gcr.io/$PROJECT_ID/a2a-gateway:$TAG
   
   # Update manifests
   sed -i "s/REPLACE_WITH_REGISTRY\/bankbrain-support-agent:REPLACE_TAG/gcr.io\/$PROJECT_ID\/support-agent:$TAG/g" k8s/support-agent.yaml
   sed -i "s/REPLACE_WITH_REGISTRY\/bankbrain-risk-agent:REPLACE_TAG/gcr.io\/$PROJECT_ID\/risk-agent:$TAG/g" k8s/risk-agent.yaml
   sed -i "s/REPLACE_WITH_REGISTRY\/bankbrain-mcp-server:REPLACE_TAG/gcr.io\/$PROJECT_ID\/mcp-server:$TAG/g" k8s/mcp-bank-server.yaml
   sed -i "s/REPLACE_WITH_REGISTRY\/bankbrain-a2a-gateway:REPLACE_TAG/gcr.io\/$PROJECT_ID\/a2a-gateway:$TAG/g" k8s/a2a-gateway.yaml
   
   # Deploy
   kubectl apply -f k8s/
   ```

## 📋 Quick Setup Commands

### Install Google Cloud SDK (Windows):
```powershell
# Download from: https://cloud.google.com/sdk/docs/install
# Run installer as administrator
# Restart PowerShell
gcloud init
gcloud auth login
```

### Install Docker Desktop:
```powershell
# Download from: https://www.docker.com/products/docker-desktop/
# Run installer as administrator
# Start Docker Desktop
# Wait for Docker to be ready
```

### Verify All Tools:
```powershell
gcloud --version
docker --version
kubectl version --client
```

## 🚀 After Installation

Once all tools are installed:

1. **Run the setup script**:
   ```powershell
   .\setup-and-deploy.ps1
   ```

2. **Or run deployment directly**:
   ```powershell
   .\deploy-to-gke.ps1 -ProjectId "your-project-id"
   ```

## 🔗 Getting Your Public Link

After successful deployment:

1. **Check ingress status**:
   ```powershell
   kubectl get ingress -n bankbrain
   ```

2. **Get the public IP**:
   ```powershell
   kubectl get service -n bankbrain
   ```

3. **Your public URL will be**:
   - **Ingress**: Use the ADDRESS from ingress output
   - **LoadBalancer**: Use the EXTERNAL-IP from service output

## 🆘 Troubleshooting

### Common Issues:
- **Docker not running**: Start Docker Desktop and wait for it to be ready
- **gcloud not found**: Restart PowerShell after installation
- **Permission denied**: Run PowerShell as administrator
- **Cluster creation fails**: Ensure billing is enabled on your Google Cloud project

### Get Help:
- Google Cloud Documentation: https://cloud.google.com/kubernetes-engine/docs
- Docker Documentation: https://docs.docker.com/
- Kubernetes Documentation: https://kubernetes.io/docs/

---

**Note**: The deployment will create a public URL that you can use to access your BankBrain application from anywhere on the internet.
