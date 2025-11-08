# BankBrain GKE Deployment Guide

This guide will walk you through deploying the BankBrain project to Google Kubernetes Engine (GKE).

## 🚀 Quick Start

For automated deployment, use the PowerShell script:

```powershell
.\deploy-to-gke.ps1 -ProjectId "your-gcp-project-id"
```

For step-by-step control, use the manual script:

```powershell
.\deploy-manual.ps1 -ProjectId "your-gcp-project-id"
```

## 📋 Prerequisites

### Google Cloud Setup

1. **Google Cloud Project**
   - Create a project in [Google Cloud Console](https://console.cloud.google.com/)
   - Note your `PROJECT_ID`
   - Enable billing

2. **GKE Cluster**
   ```bash
   gcloud container clusters create bankbrain-cluster \
     --zone us-central1-a \
     --num-nodes=3 \
     --machine-type e2-standard-2
   ```

3. **Authentication & Configuration**
   ```bash
   gcloud auth login
   gcloud config set project YOUR_PROJECT_ID
   gcloud container clusters get-credentials bankbrain-cluster --zone us-central1-a
   ```

### Local Tools

- **Docker Desktop** - Install and start
- **Google Cloud SDK** - Install with `gcloud` and `kubectl`
- **PowerShell** - Windows PowerShell 5.1 or PowerShell Core

## 🔧 Manual Deployment Steps

### Step 1: Set Environment Variables

```powershell
$env:PROJECT_ID="your-gcp-project-id"
$env:REGION="us-central1"
$env:TAG="v1"
```

### Step 2: Build & Push Docker Images

```powershell
# Support Agent
docker build -t gcr.io/$env:PROJECT_ID/support-agent:$env:TAG ./agents/support-agent
docker push gcr.io/$env:PROJECT_ID/support-agent:$env:TAG

# Risk Agent
docker build -t gcr.io/$env:PROJECT_ID/risk-agent:$env:TAG ./agents/risk-agent
docker push gcr.io/$env:PROJECT_ID/risk-agent:$env:TAG

# MCP Server
docker build -t gcr.io/$env:PROJECT_ID/mcp-server:$env:TAG ./mcp/bank_mcp_server
docker push gcr.io/$env:PROJECT_ID/mcp-server:$env:TAG

# A2A Gateway
docker build -t gcr.io/$env:PROJECT_ID/a2a-gateway:$env:TAG ./agents/a2a-gateway
docker push gcr.io/$env:PROJECT_ID/a2a-gateway:$env:TAG
```

### Step 3: Update Kubernetes Manifests

The deployment scripts automatically update the image references in your YAML files. If doing manually:

```yaml
# In each deployment file, replace:
image: REPLACE_WITH_REGISTRY/bankbrain-support-agent:REPLACE_TAG

# With:
image: gcr.io/YOUR_PROJECT_ID/support-agent:v1
```

### Step 4: Deploy to GKE

```powershell
kubectl apply -f k8s/
```

### Step 5: Verify Deployment

```powershell
# Check pods
kubectl get pods -n bankbrain

# Check services
kubectl get svc -n bankbrain

# Check ingress
kubectl get ingress -n bankbrain
```

## 🧪 Testing Your Deployment

### Option A: Local Port Forward

```powershell
kubectl port-forward svc/support-agent 8080:80 -n bankbrain
```

Open browser to: http://localhost:8080

### Option B: Public URL via Ingress

```powershell
kubectl get ingress -n bankbrain
```

Use the ADDRESS from the output as your public URL.

## 🔍 Troubleshooting

### Common Issues

1. **Authentication Errors**
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```

2. **Cluster Not Found**
   ```bash
   gcloud container clusters list
   gcloud container clusters get-credentials CLUSTER_NAME --zone ZONE
   ```

3. **Image Pull Errors**
   - Verify images exist: `gcloud container images list-tags gcr.io/PROJECT_ID/support-agent`
   - Check permissions: Ensure your account has Storage Admin role

4. **Pod Startup Issues**
   ```bash
   kubectl describe pod POD_NAME -n bankbrain
   kubectl logs POD_NAME -n bankbrain
   ```

### Debugging Commands

```powershell
# Check namespace
kubectl get namespace bankbrain

# Check all resources
kubectl get all -n bankbrain

# Check events
kubectl get events -n bankbrain --sort-by='.lastTimestamp'

# Check specific pod logs
kubectl logs -f deployment/support-agent -n bankbrain
```

## 📊 Monitoring & Scaling

### Horizontal Pod Autoscaler

The project includes HPA configuration for automatic scaling:

```powershell
kubectl get hpa -n bankbrain
```

### Resource Monitoring

```powershell
# Check resource usage
kubectl top pods -n bankbrain
kubectl top nodes
```

## 🗑️ Cleanup

To remove the deployment:

```powershell
kubectl delete -f k8s/
```

To delete the cluster:

```bash
gcloud container clusters delete bankbrain-cluster --zone us-central1-a
```

## 📚 Additional Resources

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Google Cloud Console](https://console.cloud.google.com/)

## 🆘 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Verify all prerequisites are met
3. Check Google Cloud Console for cluster status
4. Review pod logs for application-specific errors

---

**Note**: Make sure to replace `YOUR_PROJECT_ID` with your actual Google Cloud project ID throughout this guide.
