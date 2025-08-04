# currency-converter
simple currency converter

Complete DevOps Infrastructure Summary 🚀
Based on our extensive work, here's everything we've built for your currency converter application:
📁 Repository Structure
currency-converter/
├── app.py                           # Flask currency converter app
├── Dockerfile                       # Multi-stage container build
├── requirements.txt                 # Python dependencies
├── templates/index.html             # Frontend interface
├── Jenkinsfile                      # CI/CD pipeline configuration
├── k8s-manifests/                   # Kubernetes deployments
│   ├── deployment.yaml              # Pod specifications
│   └── service.yaml                 # LoadBalancer service
├── argocd-apps/                     # GitOps configuration
│   └── currency-converter-app.yaml  # ArgoCD application
└── README.md                        # Documentation

🏗️ Infrastructure Components
1. Application Layer

Flask Currency Converter: USD to EUR/GBP/CAD/PLN conversion
Containerized: Docker with Gunicorn production server
Scalable: 3 replicas running in Kubernetes

2. CI/CD Pipeline

Jenkins: Automated builds on git push
Amazon ECR: Container registry (718043211627.dkr.ecr.us-east-1.amazonaws.com)
Automated Flow: Git Push → Jenkins → Docker Build → ECR Push

3. Kubernetes Infrastructure (EKS)

Cluster: currency-converter-k8s in us-east-1
Nodes: 2 x t3.medium instances
Auto-scaling: 1-4 nodes capability
Load Balancer: AWS Application Load Balancer

4. GitOps (ArgoCD)

Automated Sync: Git changes auto-deploy to Kubernetes
Visual Dashboard: Resource tree visualization
Self-healing: Automatic configuration drift correction
Rollback: One-click rollback to any version

5. Monitoring Stack

Prometheus: Metrics collection and storage
Grafana: Beautiful dashboards and visualization
AlertManager: Alert handling
Node Exporter: Server metrics
Built-in Dashboards: Kubernetes cluster monitoring

🌐 Live URLs
Production Applications

Kubernetes App: http://a0524e56a7a284540ab2469f2f90c2c1-2137847638.us-east-1.elb.amazonaws.com
Original EC2 App: http://3.93.230.198:5000

Management Dashboards

ArgoCD GitOps: http://3.93.230.198:8081 (admin/wolQUKxgAowG4m5V)
Jenkins CI/CD: http://3.93.230.198:8080
Grafana Monitoring: Available via LoadBalancer
Prometheus Metrics: Available via LoadBalancer

🔧 Key Technologies Mastered
Infrastructure as Code

eksctl: EKS cluster creation
kubectl: Kubernetes management
helm: Package management
AWS CLI: Cloud resource management

DevOps Tools

Docker: Containerization
Jenkins: CI/CD automation
ArgoCD: GitOps deployment
Prometheus/Grafana: Monitoring

Cloud Services

Amazon EKS: Managed Kubernetes
Amazon ECR: Container registry
AWS Load Balancer: Traffic distribution
EC2: Virtual machines
VPC: Network isolation

🚀 Achievements
Enterprise-Grade Features
✅ Auto-scaling: Handles traffic spikes automatically
✅ High Availability: Multi-AZ deployment
✅ Self-healing: Kubernetes restarts failed components
✅ Load Balancing: Traffic distributed across pods
✅ GitOps: Deployment via Git commits
✅ Monitoring: Real-time metrics and dashboards
✅ CI/CD: Automated build and deployment
✅ Container Registry: Secure image storage
Production Workflow
Developer → Git Push → Jenkins Build → ECR Push → ArgoCD Sync → Kubernetes Deploy → Users

setting up these commands are quick and easy, install homebrew

# 1. Install tools (1 minute)
brew install awscli kubectl eksctl

# 2. Clone repo (30 seconds)
git clone https://github.com/jeffrey3107/currency-converter.git
cd currency-converter

# 3. Create cluster (15 minutes)
eksctl create cluster --name currency-converter-k8s --region us-east-1 --node-type t3.medium --nodes 2

# 4. Create ECR and deploy (3 minutes)
aws ecr create-repository --repository-name currency-converter --region us-east-1
# Build, tag, push, and deploy your app

---

# Pipeline test - Sat Aug  2 02:00:58 UTC 2025
# ArgoCD GitOps SUCCESS! 🎉 - Sun Aug  3 02:43:24 UTC 2025
