#!/bin/bash

# Simplified EKS + ECR + ArgoCD + Monitoring Setup
set -e

echo "🚀 Setting up complete DevOps infrastructure..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
AWS_REGION="us-east-1"
CLUSTER_NAME="currency-converter-cluster"
ECR_REPO="currency-converter"

echo -e "${YELLOW}📋 Configuration:${NC}"
echo "Region: $AWS_REGION"
echo "Cluster: $CLUSTER_NAME" 
echo "ECR Repo: $ECR_REPO"
echo ""

# Prerequisites check
echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"
if ! command -v aws >/dev/null 2>&1; then
    echo -e "${RED}❌ AWS CLI required${NC}"
    exit 1
fi

if ! command -v kubectl >/dev/null 2>&1; then
    echo "Installing kubectl..."
    curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.27.5/2023-09-14/bin/linux/amd64/kubectl
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin
fi

if ! command -v helm >/dev/null 2>&1; then
    echo "Installing helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Install eksctl if needed
if ! command -v eksctl &> /dev/null; then
    echo "Installing eksctl..."
    curl -sL "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    sudo mv /tmp/eksctl /usr/local/bin
fi

echo -e "${GREEN}✅ All prerequisites ready${NC}"

# Step 1: Create ECR Repository
echo -e "${YELLOW}📦 Step 1: Creating ECR repository...${NC}"
aws ecr create-repository \
    --repository-name $ECR_REPO \
    --region $AWS_REGION \
    --image-scanning-configuration scanOnPush=true \
    --image-tag-mutability MUTABLE 2>/dev/null || echo "Repository might already exist"

ECR_URI=$(aws ecr describe-repositories --repository-names $ECR_REPO --region $AWS_REGION --query 'repositories[0].repositoryUri' --output text)
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo -e "${GREEN}✅ ECR Repository: $ECR_URI${NC}"

# Step 2: Create EKS Cluster
echo -e "${YELLOW}☸️  Step 2: Creating EKS cluster (this will take 15-20 minutes)...${NC}"

cat > cluster-config.yaml << YAML
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: $CLUSTER_NAME
  region: $AWS_REGION

nodeGroups:
  - name: worker-nodes
    instanceType: t3.medium
    desiredCapacity: 2
    minSize: 1
    maxSize: 4
    volumeSize: 20
    ssh:
      allow: false

addons:
- name: vpc-cni
- name: coredns
- name: kube-proxy
YAML

eksctl create cluster -f cluster-config.yaml

echo -e "${GREEN}✅ EKS Cluster created${NC}"

# Step 3: Configure kubectl
echo -e "${YELLOW}🔧 Step 3: Configuring kubectl...${NC}"
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
echo -e "${GREEN}✅ kubectl configured${NC}"

# Step 4: Install ArgoCD
echo -e "${YELLOW}📱 Step 4: Installing ArgoCD...${NC}"
kubectl create namespace argocd || true
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
echo "Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Expose ArgoCD server
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

echo -e "${GREEN}✅ ArgoCD installed${NC}"

# Step 5: Install Prometheus and Grafana
echo -e "${YELLOW}📊 Step 5: Installing Prometheus and Grafana...${NC}"

# Add Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack
kubectl create namespace monitoring || true
helm install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --set grafana.adminPassword=admin123 \
    --set grafana.service.type=LoadBalancer \
    --wait --timeout=600s

echo -e "${GREEN}✅ Prometheus and Grafana installed${NC}"

# Step 6: Get access information
echo -e "${YELLOW}🔑 Step 6: Getting access information...${NC}"

# Wait for LoadBalancers to be ready
echo "Waiting for LoadBalancers to get external IPs..."
sleep 60

# Get ArgoCD admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Get LoadBalancer URLs (retry a few times)
for i in {1..5}; do
    GRAFANA_LB=$(kubectl get svc -n monitoring prometheus-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    ARGOCD_LB=$(kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    
    if [[ -n "$GRAFANA_LB" && -n "$ARGOCD_LB" ]]; then
        break
    fi
    echo "Waiting for LoadBalancer IPs... (attempt $i/5)"
    sleep 30
done

# Cleanup
rm -f cluster-config.yaml

echo ""
echo -e "${GREEN}🎉 SETUP COMPLETE! 🎉${NC}"
echo ""
echo -e "${YELLOW}📊 ACCESS INFORMATION:${NC}"
echo "┌─────────────────────────────────────────────────────────────────"
echo "│ 🔍 Grafana:"
echo "│   URL: http://$GRAFANA_LB"
echo "│   Username: admin"
echo "│   Password: admin123"
echo "│"
echo "│ 🚀 ArgoCD:"
echo "│   URL: http://$ARGOCD_LB"
echo "│   Username: admin"
echo "│   Password: $ARGOCD_PASSWORD"
echo "│"
echo "│ 📦 ECR Repository:"
echo "│   URL: $ECR_URI"
echo "│   AWS Account ID: $AWS_ACCOUNT_ID"
echo "│"
echo "│ ☸️  Cluster:"
echo "│   Name: $CLUSTER_NAME"
echo "│   Region: $AWS_REGION"
echo "└─────────────────────────────────────────────────────────────────"
echo ""
echo -e "${YELLOW}📝 NEXT STEPS FOR JENKINS:${NC}"
echo "1. Add AWS credentials to Jenkins with these values:"
echo "   - AWS_ACCOUNT_ID: $AWS_ACCOUNT_ID"
echo "   - ECR_REGISTRY: $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
echo ""
echo "2. Update your Jenkinsfile environment section:"
echo "   environment {"
echo "       AWS_ACCOUNT_ID = '$AWS_ACCOUNT_ID'"
echo "       ECR_REGISTRY = '$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com'"
echo "       ECR_REPOSITORY = '$ECR_REPO'"
echo "   }"
echo ""
echo "3. Update k8s-manifests/deployment.yaml image:"
echo "   image: $ECR_URI:latest"
echo ""
echo "4. Commit and push changes to trigger CI/CD pipeline"
echo ""
echo -e "${GREEN}✨ Ready to deploy your application!${NC}"
