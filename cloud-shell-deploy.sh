#!/bin/bash

# BankBrain Cloud Shell Deployment Script
# Run this in Google Cloud Shell (https://console.cloud.google.com/cloudshell)

set -e

echo "🚀 BankBrain Cloud Shell Deployment"
echo "=================================="
echo ""

# Check if we're in Cloud Shell
if [ -z "$CLOUD_SHELL" ]; then
    echo "⚠️  This script is designed to run in Google Cloud Shell"
    echo "   Open: https://console.cloud.google.com/cloudshell"
    exit 1
fi

# Get project ID
PROJECT_ID=$(gcloud config get-value project)
if [ -z "$PROJECT_ID" ]; then
    echo "❌ No project ID found. Please set your project:"
    echo "   gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

echo "📋 Project ID: $PROJECT_ID"
echo "🏷️  Tag: v1"
echo ""

# Confirm deployment
read -p "Continue with deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

echo ""
echo "🔐 Setting up Google Cloud..."

# Enable required APIs
echo "Enabling required APIs..."
gcloud services enable container.googleapis.com
gcloud services enable containerregistry.googleapis.com

# Create GKE cluster if it doesn't exist
CLUSTER_EXISTS=$(gcloud container clusters list --filter="name:bankbrain-cluster" --format="value(name)")

if [ -z "$CLUSTER_EXISTS" ]; then
    echo "🏗️  Creating GKE cluster 'bankbrain-cluster'..."
    echo "This may take 5-10 minutes..."
    
    gcloud container clusters create bankbrain-cluster \
        --zone us-central1-a \
        --num-nodes 3 \
        --machine-type e2-standard-2 \
        --enable-autoscaling \
        --min-nodes 1 \
        --max-nodes 5 \
        --enable-network-policy
    
    echo "✅ Cluster created successfully!"
else
    echo "✅ Cluster 'bankbrain-cluster' already exists"
fi

# Get cluster credentials
echo "🔑 Getting cluster credentials..."
gcloud container clusters get-credentials bankbrain-cluster --zone us-central1-a

echo ""
echo "🐳 Building and pushing Docker images..."

# Build and push Support Agent
echo "Building Support Agent..."
docker build -t gcr.io/$PROJECT_ID/support-agent:v1 ./agents/support-agent
docker push gcr.io/$PROJECT_ID/support-agent:v1

# Build and push Risk Agent
echo "Building Risk Agent..."
docker build -t gcr.io/$PROJECT_ID/risk-agent:v1 ./agents/risk-agent
docker push gcr.io/$PROJECT_ID/risk-agent:v1

# Build and push MCP Server
echo "Building MCP Server..."
docker build -t gcr.io/$PROJECT_ID/mcp-server:v1 ./mcp/bank_mcp_server
docker push gcr.io/$PROJECT_ID/mcp-server:v1

# Build and push A2A Gateway
echo "Building A2A Gateway..."
docker build -t gcr.io/$PROJECT_ID/a2a-gateway:v1 ./agents/a2a-gateway
docker push gcr.io/$PROJECT_ID/a2a-gateway:v1

echo "✅ All images built and pushed successfully!"
echo ""

echo "📝 Updating Kubernetes manifests..."

# Update manifests with correct image references
sed -i "s|REPLACE_WITH_REGISTRY/bankbrain-support-agent:REPLACE_TAG|gcr.io/$PROJECT_ID/support-agent:v1|g" k8s/support-agent.yaml
sed -i "s|REPLACE_WITH_REGISTRY/bankbrain-risk-agent:REPLACE_TAG|gcr.io/$PROJECT_ID/risk-agent:v1|g" k8s/risk-agent.yaml
sed -i "s|REPLACE_WITH_REGISTRY/bankbrain-mcp-server:REPLACE_TAG|gcr.io/$PROJECT_ID/mcp-server:v1|g" k8s/mcp-bank-server.yaml
sed -i "s|REPLACE_WITH_REGISTRY/bankbrain-a2a-gateway:REPLACE_TAG|gcr.io/$PROJECT_ID/a2a-gateway:v1|g" k8s/a2a-gateway.yaml

echo "✅ Manifests updated!"
echo ""

echo "🚀 Deploying to GKE..."
kubectl apply -f k8s/

echo "✅ Deployment successful!"
echo ""

echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=support-agent -n bankbrain --timeout=300s
kubectl wait --for=condition=ready pod -l app=risk-agent -n bankbrain --timeout=300s
kubectl wait --for=condition=ready pod -l app=mcp-bank-server -n bankbrain --timeout=300s
kubectl wait --for=condition=ready pod -l app=a2a-gateway -n bankbrain --timeout=300s

echo "✅ All pods are ready!"
echo ""

echo "📊 Deployment Status:"
kubectl get pods -n bankbrain
echo ""

echo "🌐 Services:"
kubectl get svc -n bankbrain
echo ""

echo "🚪 Ingress:"
kubectl get ingress -n bankbrain
echo ""

echo "🎯 Your BankBrain application is now deployed!"
echo ""

# Get the public URL
echo "🔗 Getting your public URL..."
INGRESS_ADDRESS=$(kubectl get ingress -n bankbrain -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null)

if [ -n "$INGRESS_ADDRESS" ]; then
    echo "✅ Public URL: http://$INGRESS_ADDRESS"
    echo ""
    echo "🌐 You can now access BankBrain at:"
    echo "   http://$INGRESS_ADDRESS"
    echo ""
    echo "📱 This URL is accessible from anywhere on the internet!"
else
    echo "⏳ Ingress is still provisioning. Check status with:"
    echo "   kubectl get ingress -n bankbrain"
    echo ""
    echo "💡 You can also use port forwarding for local testing:"
    echo "   kubectl port-forward svc/support-agent 8080:80 -n bankbrain"
    echo "   Then open: http://localhost:8080"
fi

echo ""
echo "🎉 Deployment completed successfully!"
echo ""
echo "📋 Useful commands:"
echo "   Check status: kubectl get all -n bankbrain"
echo "   View logs: kubectl logs -f deployment/support-agent -n bankbrain"
echo "   Port forward: kubectl port-forward svc/support-agent 8080:80 -n bankbrain"
