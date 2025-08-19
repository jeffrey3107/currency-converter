#!/bin/bash

# scripts/setup-infrastructure.sh
# Complete setup script for EKS, ECR, ArgoCD, Prometheus, and Grafana

set -e

echo "🚀 Setting up complete infrastructure..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables
AWS_REGION=${AWS_REGION:-"us-east-1"}
CLUSTER_NAME=${CLUSTER_NAME:-"currency-converter-cluster"}

echo -e "${YELLOW}📋 Configuration:${NC}"
echo "AWS Region: $AWS_REGION"
echo "Cluster Name: $CLUSTER_NAME"
echo ""

# Check prerequisites
echo -e "${YELLOW}�� Checking prerequisites...${NC}"

command -v aws >/dev/null 2>&1 || { echo -e "${RED}❌ AWS CLI is required but not installed.${NC}" >&2; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo -e "${RED}❌ Terraform is required but not installed.${NC}" >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}❌ kubectl is required but not installed.${NC}" >&2; exit 1; }
command -v helm >/dev/null 2>&1 || { echo -e "${RED}❌ Helm is required but not installed.${NC}" >&2; exit 1; }

echo -e "${GREEN}✅ All prerequisites found${NC}"

# Step 1: Deploy infrastructure with Terraform
echo -e "${YELLOW}🏗️ Step 1: Deploying infrastructure with Terraform...${NC}"
cd terraform

terraform init
terraform plan -var="aws_region=$AWS_REGION" -var="cluster_name=$CLUSTER_NAME"
terraform apply -var="aws_region=$AWS_REGION" -var="cluster_name=$CLUSTER_NAME" -auto-approve

# Get outputs
ECR_REPOSITORY_URL=$(terraform output -raw ecr_repository_url)
AWS_ACCOUNT_ID=$(terraform output -raw aws_account_id)

cd ..

echo -e "${GREEN}✅ Infrastructure deployed${NC}"
echo "ECR Repository: $ECR_REPOSITORY_URL"

# Step 2: Configure kubectl
echo -e "${YELLOW}🔧 Step 2: Configuring kubectl...${NC}"
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

echo -e "${GREEN}✅ kubectl configured${NC}"

# Step 3: Wait for cluster to be ready
echo -e "${YELLOW}⏳ Step 3: Waiting for cluster to be ready...${NC}"
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Step 4: Create ArgoCD application
echo -e "${YELLOW}📱 Step 4: Creating ArgoCD application...${NC}"
sleep 60  # Wait for ArgoCD to be fully ready

# Update ArgoCD application with correct repository
sed -i "s|repoURL: .*|repoURL: https://github.com/jeffrey3107/currency-converter.git|g" argocd-apps/currency-converter.yaml

kubectl apply -f argocd-apps/currency-converter.yaml

echo -e "${GREEN}✅ ArgoCD application created${NC}"

# Step 5: Update Jenkins with ECR details
echo -e "${YELLOW}🔧 Step 5: Updating Jenkins configuration...${NC}"

echo "Add these environment variables to your Jenkins configuration:"
echo "AWS_ACCOUNT_ID: $AWS_ACCOUNT_ID"
echo "ECR_REPOSITORY_URL: $ECR_REPOSITORY_URL"

# Step 6: Get access information
echo -e "${YELLOW}🔑 Step 6: Getting access information...${NC}"

# ArgoCD admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Get LoadBalancer URLs
echo "Waiting for LoadBalancers to be ready..."
sleep 30

GRAFANA_LB=$(kubectl get svc -n monitoring prometheus-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
ARGOCD_LB=$(kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo ""
echo -e "${GREEN}🎉 Setup Complete!${NC}"
echo ""
echo -e "${YELLOW}📊 Access Information:${NC}"
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
echo "│   URL: $ECR_REPOSITORY_URL"
echo "│"
echo "│ ☸️  Cluster:"
echo "│   Name: $CLUSTER_NAME"
echo "│   Region: $AWS_REGION"
echo "└─────────────────────────────────────────────────────────────────"
echo ""
echo -e "${YELLOW}📝 Next Steps:${NC}"
echo "1. Add AWS credentials to Jenkins (aws-credentials)"
echo "2. Update your Jenkinsfile with the ECR repository URL"
echo "3. Update k8s-manifests/deployment.yaml with your ECR image"
echo "4. Push changes to trigger the CI/CD pipeline"
echo "5. Monitor deployment in ArgoCD"
echo "6. View metrics in Grafana"

echo ""
echo -e "${GREEN}✨ Happy deploying!${NC}"
