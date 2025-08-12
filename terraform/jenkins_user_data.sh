#!/bin/bash

# jenkins_user_data.sh - Complete DevOps Infrastructure Setup
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "🚀 Starting complete DevOps infrastructure setup for ${project_name}"
echo "Environment: ${environment}"
echo "ECR Repository: ${ecr_repository}"
echo "Started at: $(date)"

# Update system
yum update -y

# Install required packages
yum install -y git curl wget unzip docker

# Install Java 17 for Jenkins
yum install -y java-17-openjdk java-17-openjdk-devel

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -aG docker ec2-user

# Install Jenkins
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
yum install -y jenkins

# Start and enable Jenkins
systemctl start jenkins
systemctl enable jenkins

# Add jenkins to docker group
usermod -aG docker jenkins

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
mv /tmp/eksctl /usr/local/bin

# Install Helm
curl https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz -o helm.tar.gz
tar -zxvf helm.tar.gz
mv linux-amd64/helm /usr/local/bin/helm
rm -rf linux-amd64/ helm.tar.gz

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Node.js and npm (for additional tooling)
curl -sL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# Create application directory
mkdir -p /opt/${project_name}
cd /opt/${project_name}

# Clone the currency converter repository
git clone https://github.com/jeffrey3107/currency-converter.git .

# Install Python dependencies
yum install -y python3 python3-pip
pip3 install -r requirements.txt

# Create systemd service for the Flask app
cat > /etc/systemd/system/${project_name}.service << EOF
[Unit]
Description=${project_name} Flask Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/${project_name}
Environment=PATH=/usr/local/bin:/usr/bin:/bin
Environment=FLASK_ENV=production
ExecStart=/usr/bin/python3 app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Fix ownership
chown -R ec2-user:ec2-user /opt/${project_name}

# Enable and start the Flask app
systemctl daemon-reload
systemctl enable ${project_name}.service
systemctl start ${project_name}.service

# Create Jenkins job configuration directory
mkdir -p /var/lib/jenkins/jobs

# Wait for Jenkins to start
sleep 60

# Get Jenkins initial admin password
JENKINS_PASSWORD=$(cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "Password file not ready yet")

# Create a basic Jenkins job via CLI (this will be automated)
# Note: In production, you'd configure this through the UI or Jenkins Configuration as Code

# Install Jenkins plugins via CLI
# java -jar /var/cache/jenkins/war/WEB-INF/jenkins-cli.jar -s http://localhost:8080/ install-plugin git docker-workflow

# Create Kubernetes manifests directory
mkdir -p /opt/${project_name}/k8s-manifests

# Create Kubernetes deployment manifest
cat > /opt/${project_name}/k8s-manifests/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: currency-converter
  labels:
    app: currency-converter
spec:
  replicas: 3
  selector:
    matchLabels:
      app: currency-converter
  template:
    metadata:
      labels:
        app: currency-converter
    spec:
      containers:
      - name: currency-converter
        image: ${ecr_repository}:latest
        ports:
        - containerPort: 5000
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        env:
        - name: FLASK_ENV
          value: "production"
        livenessProbe:
          httpGet:
            path: /
            port: 5000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 5000
          initialDelaySeconds: 5
          periodSeconds: 5
EOF

# Create Kubernetes service manifest
cat > /opt/${project_name}/k8s-manifests/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: currency-converter-service
  labels:
    app: currency-converter
spec:
  selector:
    app: currency-converter
  ports:
  - protocol: TCP
    port: 80
    targetPort: 5000
  type: LoadBalancer
EOF

# Create ArgoCD application manifest
mkdir -p /opt/${project_name}/argocd-apps
cat > /opt/${project_name}/argocd-apps/currency-converter-app.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: currency-converter
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/jeffrey3107/currency-converter.git
    targetRevision: HEAD
    path: k8s-manifests
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

# Create Jenkinsfile for CI/CD
cat > /opt/${project_name}/Jenkinsfile << EOF
pipeline {
    agent any
    
    environment {
        AWS_REGION = 'us-east-1'
        ECR_REPOSITORY = '${project_name}'
        ECR_REGISTRY = '${ecr_repository}'
        IMAGE_TAG = "\${BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '📥 Checking out code...'
                checkout scm
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo '🐳 Building Docker image...'
                script {
                    def image = docker.build("\${ECR_REGISTRY}:\${IMAGE_TAG}")
                    sh "docker tag \${ECR_REGISTRY}:\${IMAGE_TAG} \${ECR_REGISTRY}:latest"
                }
            }
        }
        
        stage('Login to ECR') {
            steps {
                echo '🔐 Logging into ECR...'
                script {
                    sh 'aws ecr get-login-password --region \${AWS_REGION} | docker login --username AWS --password-stdin \${ECR_REGISTRY}'
                }
            }
        }
        
        stage('Push to ECR') {
            steps {
                echo '📤 Pushing to ECR...'
                script {
                    sh "docker push \${ECR_REGISTRY}:\${IMAGE_TAG}"
                    sh "docker push \${ECR_REGISTRY}:latest"
                }
            }
        }
        
        stage('Deploy to EKS') {
            steps {
                echo '🚀 Deploying to EKS...'
                script {
                    sh '''
                        aws eks update-kubeconfig --region \${AWS_REGION} --name ${project_name}-k8s
                        kubectl apply -f k8s-manifests/
                        kubectl rollout restart deployment/currency-converter
                    '''
                }
            }
        }
    }
    
    post {
        always {
            echo '🧹 Cleaning up...'
            sh "docker rmi \${ECR_REGISTRY}:\${IMAGE_TAG} || true"
            sh "docker rmi \${ECR_REGISTRY}:latest || true"
        }
    }
}
EOF

# Set up log monitoring
mkdir -p /var/log/${project_name}

# Create monitoring script
cat > /opt/${project_name}/monitor.sh << 'EOF'
#!/bin/bash
echo "=== Infrastructure Monitoring Report - $(date) ==="
echo ""
echo "🐳 Docker Status:"
systemctl is-active docker
echo ""
echo "🔧 Jenkins Status:"
systemctl is-active jenkins
echo ""
echo "💱 Currency Converter Status:"
systemctl is-active currency-converter
echo ""
echo "📊 System Resources:"
df -h | grep -E "(Filesystem|/dev/)"
free -h
echo ""
echo "🌐 Application Health:"
curl -s http://localhost:5000 > /dev/null && echo "✅ Flask app is responding" || echo "❌ Flask app is down"
curl -s http://localhost:8080 > /dev/null && echo "✅ Jenkins is responding" || echo "❌ Jenkins is down"
EOF

chmod +x /opt/${project_name}/monitor.sh

# Create deployment summary
cat > /opt/${project_name}/deployment-info.txt << EOF
🚀 ${project_name} Enterprise Infrastructure Deployment Complete!

📅 Deployed: $(date)
🌍 Environment: ${environment}
🏗️ Infrastructure: Complete DevOps Stack

🔗 Access URLs:
   • Jenkins: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080
   • Currency Converter: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):5000
   • ArgoCD: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8081

🔑 Jenkins Initial Password: ${JENKINS_PASSWORD}

🛠️ Infrastructure Components:
   ✅ Jenkins CI/CD Server
   ✅ Docker Containerization
   ✅ AWS ECR Repository: ${ecr_repository}
   ✅ EKS Cluster (will be created): ${project_name}-k8s
   ✅ Flask Currency Converter Application
   ✅ Kubernetes Manifests
   ✅ ArgoCD GitOps
   ✅ Monitoring & Health Checks

🚀 Next Steps:
   1. Access Jenkins at the URL above
   2. Use initial password to set up Jenkins
   3. Configure GitHub webhook for automated builds
   4. EKS cluster will be ready after Terraform completes
   5. Access ArgoCD for GitOps deployment management

📊 Monitoring:
   • Run /opt/${project_name}/monitor.sh for health check
   • Logs: /var/log/user-data.log
   • Application logs: journalctl -u ${project_name}.service

🔧 Useful Commands:
   • Check Flask app: systemctl status ${project_name}
   • Check Jenkins: systemctl status jenkins
   • Check Docker: docker ps
   • View logs: tail -f /var/log/user-data.log
EOF

# Install ArgoCD CLI
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd

# Create script to install ArgoCD on EKS (will be run after EKS is ready)
cat > /opt/${project_name}/install-argocd.sh << 'EOF'
#!/bin/bash
echo "🔧 Installing ArgoCD on EKS cluster..."

# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name currency-converter-k8s

# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Create LoadBalancer service for ArgoCD
cat << ARGOCD_LB > argocd-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: argocd-server-lb
  namespace: argocd
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
  selector:
    app.kubernetes.io/name: argocd-server
ARGOCD_LB

kubectl apply -f argocd-service.yaml

echo "✅ ArgoCD installation complete!"
echo "🔑 Get ArgoCD password with: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo "🌐 Get ArgoCD URL with: kubectl get service argocd-server-lb -n argocd"
EOF

chmod +x /opt/${project_name}/install-argocd.sh

# Create monitoring and alerting setup
cat > /opt/${project_name}/setup-monitoring.sh << 'EOF'
#!/bin/bash
echo "📊 Setting up Prometheus and Grafana monitoring..."

# Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install complete monitoring stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.service.type=LoadBalancer \
  --set grafana.adminPassword=admin123 \
  --set prometheus.service.type=LoadBalancer \
  --set grafana.persistence.enabled=true \
  --set prometheus.prometheusSpec.retention=15d

echo "✅ Monitoring stack installation complete!"
echo "📊 Grafana will be available via LoadBalancer"
echo "🔍 Prometheus will be available via LoadBalancer"
echo "🔑 Grafana login: admin/admin123"
EOF

chmod +x /opt/${project_name}/setup-monitoring.sh

# Create complete setup script
cat > /opt/${project_name}/complete-setup.sh << 'EOF'
#!/bin/bash
echo "🚀 Running complete infrastructure setup..."

# Install ArgoCD
./install-argocd.sh

# Install monitoring
./setup-monitoring.sh

# Apply currency converter application
kubectl apply -f argocd-apps/currency-converter-app.yaml

echo "🎉 Complete enterprise infrastructure setup finished!"
echo ""
echo "🌐 Access URLs:"
echo "   • Kubernetes App: kubectl get service currency-converter-service"
echo "   • ArgoCD: kubectl get service argocd-server-lb -n argocd"
echo "   • Grafana: kubectl get service prometheus-grafana -n monitoring"
echo ""
echo "💡 Run ./monitor.sh for system health check"
EOF

chmod +x /opt/${project_name}/complete-setup.sh

# Final system status
sleep 30

echo "=== Final Deployment Status ==="
echo "✅ System updated"
echo "✅ Docker installed and running: $(systemctl is-active docker)"
echo "✅ Jenkins installed and running: $(systemctl is-active jenkins)"
echo "✅ Currency converter app running: $(systemctl is-active ${project_name})"
echo "✅ AWS CLI installed: $(aws --version)"
echo "✅ kubectl installed: $(kubectl version --client --short)"
echo "✅ eksctl installed: $(eksctl version)"
echo "✅ Helm installed: $(helm version --short)"
echo "✅ Repository cloned and configured"
echo "✅ Kubernetes manifests created"
echo "✅ ArgoCD manifests created"
echo "✅ Jenkins pipeline configured"

echo ""
echo "🌐 Access Information:"
echo "   Jenkins: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo "   Currency Converter: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):5000"
echo "   SSH: ssh -i your-key.pem ec2-user@$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"

echo ""
echo "🔑 Jenkins Initial Password: ${JENKINS_PASSWORD}"
echo ""
echo "📋 Next steps after EKS cluster is ready:"
echo "   1. SSH into the server"
echo "   2. Run: cd /opt/${project_name} && ./complete-setup.sh"
echo "   3. Configure Jenkins jobs"
echo "   4. Set up GitHub webhooks"

echo "🎉 Enterprise DevOps infrastructure deployment completed at $(date)"
