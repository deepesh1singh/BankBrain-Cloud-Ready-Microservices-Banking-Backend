# 🚀 Quick Deploy to Get Your BankBrain Link

## ⚡ Fastest Way: Google Cloud Shell (Recommended)

**No local installation required!**

### Step 1: Open Google Cloud Shell
1. Go to: https://console.cloud.google.com/cloudshell
2. Sign in with your Google account
3. Make sure you have a Google Cloud project selected

### Step 2: Clone and Deploy
```bash
# Clone your repository
git clone <your-repo-url>
cd bankbrain_project

# Make the deployment script executable
chmod +x cloud-shell-deploy.sh

# Run the deployment
./cloud-shell-deploy.sh
```

**That's it!** The script will:
- ✅ Create a GKE cluster
- ✅ Build and push all Docker images
- ✅ Deploy BankBrain to Kubernetes
- ✅ Give you your public URL

## 🔗 Your Public Link

After deployment, you'll get a public URL like:
```
http://34.120.45.67
```

This URL will be accessible from anywhere on the internet!

## 🛠️ Alternative: Local Installation

If you prefer to install tools locally:

### Install Required Tools:
1. **Google Cloud SDK**: https://cloud.google.com/sdk/docs/install
2. **Docker Desktop**: https://www.docker.com/products/docker-desktop

### Run Deployment:
```powershell
.\setup-and-deploy.ps1
```

## 📱 Test Your Deployment

Once deployed, you can:
1. **Open your public URL** in any browser
2. **Ask questions** like "Show my last 5 transactions"
3. **Share the link** with others to test

## 🆘 Need Help?

- **Check status**: `kubectl get all -n bankbrain`
- **View logs**: `kubectl logs -f deployment/support-agent -n bankbrain`
- **Port forward**: `kubectl port-forward svc/support-agent 8080:80 -n bankbrain`

---

**🎯 Goal**: Get your BankBrain running on the internet with a public URL!
