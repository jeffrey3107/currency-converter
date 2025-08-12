# 🚀 Complete Currency Converter Enterprise Infrastructure

This Infrastructure as Code (IaC) project creates a complete, production-ready enterprise infrastructure for your currency converter application using Terraform.

## 🏗️ **What This Builds**

### **Complete Infrastructure Stack:**
```
┌─────────────────────────────────────────────────────────────┐
│                    AWS Cloud Infrastructure                 │
├─────────────────────────────────────────────────────────────┤
│  VPC (10.0.0.0/16)                                        │
│  ├── Public Subnets (2 AZs)                               │
│  ├── Private Subnets (2 AZs)                              │
│  └── Internet Gateway + Route Tables                       │
├─────────────────────────────────────────────────────────────┤
│  Jenkins Server (EC2 t3.medium)                           │
│  ├── Jenkins CI/CD Platform                               │
│  ├── Docker + AWS CLI + kubectl                           │
│  ├── Currency Converter Flask App                         │
│  └── Complete DevOps Toolchain                            │
├─────────────────────────────────────────────────────────────┤
│  Amazon EKS Cluster                                       │
│  ├── Kubernetes 1.28                                      │
│  ├── 2-4 Worker Nodes (t3.medium)                         │
│  ├── Auto-scaling Node Groups                             │
│  └── LoadBalancer Services                                │
├─────────────────────────────────────────────────────────────┤
│  Amazon ECR Repository                                    │
│  ├── Container Image Registry                             │
│  ├── Image Scanning                                       │
│  └── Automated CI/CD Integration                          │
├─────────────────────────────────────────────────────────────┤
│  ArgoCD GitOps Platform                                   │
│  ├── Automated Deployments                                │
│  ├── Git-based Configuration                              │
│  ├── Visual Dashboard                                     │
│  └── Rollback Capabilities                                │
├─────────────────────────────────────────────────────────────┤
│  Monitoring Stack                                         │
│  ├── Prometheus (Metrics)                                 │
│  ├── Grafana (Dashboards)                                 │
│  ├── AlertManager (Alerts)                                │
│  └── Node Exporter (System Metrics)                       │
└─────────────────────────────────────────────────────────────┘
```

## 🎯 **Enterprise Features**

### **✅ Production-Ready Infrastructure:**
- **High Availability**: Multi-AZ deployment
- **Auto-scaling**: EKS node groups scale 1-4 nodes
- **Load Balancing**: AWS LoadBalancer for traffic distribution
- **Security**: VPC with public/private subnets, security groups
- **Monitoring**: Complete observability stack

### **✅ Complete CI/CD Pipeline:**
- **Source Control**: GitHub integration
- **Build Automation**: Jenkins with automated triggers
- **Container Registry**: Amazon ECR with image scanning
- **Deployment Automation**: ArgoCD GitOps workflow

### **✅ Professional DevOps Workflow:**
```
Developer → Git Push → Jenkins → Build → ECR → ArgoCD → EKS → Users
                         ↓
                    Automated Testing
                         ↓
                    Quality Gates
                         ↓
                    Production Deploy
```

## 🚀 **Quick Deployment**

### **Prerequisites:**
- AWS CLI configured with appropriate permissions
- Terraform installed (>= 1.0)
- An AWS key pair for EC2 access

### **Step 1: Clone and Configure**
```bash
# Create project directory
mkdir currency-converter-enterprise
cd currency-converter-enterprise

# Copy all Terraform files from the artifacts above
# main.tf, variables.tf, outputs.tf, jenkins_user_data.sh
```

### **Step 2: Configure Variables**
```bash
# Copy and customize configuration
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars and update:
nano terraform.tfvars
```

**Required changes:**
```hcl
key_name = "your-actual-key-pair-name"  # Your AWS key pair
project_name = "currency-converter"      # Or your preferred name
environment = "production"               # dev, staging, production
```

### **Step 3: Deploy Infrastructure**
```bash
# Initialize Terraform
terraform init

# Review deployment plan
terraform plan

# Deploy complete infrastructure (takes ~20-25 minutes)
terraform apply
```

### **Step 4: Access Your Infrastructure**
After deployment, Terraform will output:
```
jenkins_url = "http://54.208.33.1:8080"
currency_converter_url = "http://54.208.33.1:5000"
argocd_url = "http://54.208.33.1:8081"
eks_cluster_name = "currency-converter-k8s"
ecr_repository_url = "123456789.dkr.ecr.us-east-1.amazonaws.com/currency-converter"
```

## 🎛️ **Post-Deployment Setup**

### **1. Configure Jenkins (5 minutes)**
```bash
# SSH into Jenkins server
ssh -i your-key.pem ec2-user@<jenkins-ip>

# Get Jenkins initial password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Access Jenkins at http://<jenkins-ip>:8080
# Complete setup wizard and install recommended plugins
```

### **2. Set Up EKS Integration (5 minutes)**
```bash
# On Jenkins server, run complete setup
cd /opt/currency-converter
./complete-setup.sh

# This installs ArgoCD, Prometheus/Grafana, and deploys your app
```

### **3. Configure GitHub Integration (5 minutes)**
- Add GitHub webhook: `http://<jenkins-ip>:8080/github-webhook/`
- Create Jenkins pipeline job pointing to your repository
- Enable automated builds on git push

## 🌐 **Access Your Applications**

### **Development/Testing:**
- **Currency Converter**: `http://<jenkins-ip>:5000`
- **Jenkins Dashboard**: `http://<jenkins-ip>:8080`

### **Production (Kubernetes):**
```bash
# Get Kubernetes app URL
kubectl get service currency-converter-service

# Get ArgoCD URL  
kubectl get service argocd-server-lb -n argocd

# Get Grafana URL
kubectl get service prometheus-grafana -n monitoring
```

## 📊 **Monitoring & Observability**

### **Built-in Dashboards:**
- **Grafana**: Application metrics, system health
- **Prometheus**: Raw metrics and alerting rules
- **ArgoCD**: Deployment status and git sync
- **Jenkins**: Build status and pipeline health

### **Health Monitoring:**
```bash
# SSH into Jenkins server
ssh -i your-key.pem ec2-user@<jenkins-ip>

# Run health check
cd /opt/currency-converter
./monitor.sh
```

## 🔧 **Scaling & Management**

### **Scale EKS Nodes:**
```bash
# Update desired capacity
aws eks update-nodegroup-config \
  --cluster-name currency-converter-k8s \
  --nodegroup-name currency-converter-workers \
  --scaling-config minSize=2,maxSize=6,desiredSize=4
```

### **Application Scaling:**
```bash
# Scale application pods
kubectl scale deployment currency-converter --replicas=5
```

### **Update Application:**
```bash
# Simply push to GitHub - ArgoCD will auto-deploy
git add .
git commit -m "Update application"
git push origin main
```

## 💰 **Cost Optimization**

### **Estimated Monthly Costs:**
- **Development**: ~$50-80/month
  - Jenkins EC2 (t3.medium): ~$30
  - EKS Control Plane: $73
  - Worker Nodes (2 x t3.medium): ~$60
  - Data Transfer: ~$5-10

- **Production**: ~$200-300/month
  - Larger instances and more nodes
  - Enhanced monitoring and logging
  - Multi-environment setup

### **Cost-Saving Tips:**
```hcl
# For development, use smaller instances
jenkins_instance_type = "t3.small"
eks_instance_type = "t3.small"
eks_desired_nodes = 1
```

## 🔒 **Security Features**

- **VPC Isolation**: Private subnets for EKS workers
- **Security Groups**: Least-privilege access rules
- **IAM Roles**: Granular permissions for each service
- **ECR Scanning**: Automated container vulnerability scans
- **Secrets Management**: Kubernetes secrets for sensitive data

## 🚨 **Troubleshooting**

### **Common Issues:**

**EKS cluster creation timeout:**
```bash
# Check CloudFormation stacks
aws cloudformation list-stacks --region us-east-1
```

**Jenkins not accessible:**
```bash
# Check Jenkins status
sudo systemctl status jenkins

# Check security groups allow port 8080
aws ec2 describe-security-groups --group-ids <sg-id>
```

**ArgoCD not syncing:**
```bash
# Check ArgoCD logs
kubectl logs -n argocd deployment/argocd-server
```

## 🧹 **Cleanup**

To destroy all infrastructure:
```bash
# Destroy EKS resources first (if needed)
kubectl delete all --all -n default
kubectl delete all --all -n argocd
kubectl delete all --all -n monitoring

# Destroy Terraform infrastructure
terraform destroy
```

## 🎓 **Learning Resources**

This infrastructure demonstrates:
- **Infrastructure as Code** with Terraform
- **Container Orchestration** with Kubernetes
- **CI/CD Pipelines** with Jenkins
- **GitOps** with ArgoCD
- **Monitoring** with Prometheus/Grafana
- **Cloud-Native Architecture** on AWS

## 🎉 **Achievements**

By deploying this infrastructure, you've created:
✅ **Enterprise-Grade DevOps Pipeline**
✅ **Production-Ready Kubernetes Cluster**
✅ **Automated CI/CD Workflow**
✅ **Complete Monitoring Stack**
✅ **GitOps Deployment Process**
✅ **Scalable Cloud Architecture**

This is the same level of infrastructure used by major companies for production applications!
