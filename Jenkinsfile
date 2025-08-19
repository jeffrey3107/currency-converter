pipeline {
    agent any
    
    environment {
        AWS_ACCOUNT_ID = '718043211627'
        AWS_REGION = 'us-east-1'
        ECR_REGISTRY = '718043211627.dkr.ecr.us-east-1.amazonaws.com'
        ECR_REPOSITORY = 'currency-converter'
        IMAGE_TAG = "${BUILD_NUMBER}"
    }
    
    stages {
        stage('🏁 Checkout') {
            steps {
                echo '📥 Checking out code...'
                checkout scm
            }
        }
        
        stage('🐍 Setup Python') {
            steps {
                echo '🐍 Setting up Python environment...'
                sh '''
                    python3 -m venv venv
                    . venv/bin/activate
                    pip install --upgrade pip
                    pip install -r requirements.txt
                    pip install pytest pytest-cov flake8
                '''
            }
        }
        
        stage('🧪 Run Tests') {
            steps {
                echo '🧪 Running tests with coverage...'
                sh '''
                    . venv/bin/activate
                    python -m pytest --cov=. --cov-report=xml --cov-report=html --junitxml=test-results.xml -v
                '''
            }
        }
        
        stage('📊 SonarQube Analysis') {
            steps {
                echo '📊 Running SonarQube analysis...'
                withCredentials([string(credentialsId: 'sonarqube', variable: 'SONAR_TOKEN')]) {
                    sh '''
                        sonar-scanner \
                        -Dsonar.projectKey=currency-converter \
                        -Dsonar.projectName="Currency Converter" \
                        -Dsonar.sources=. \
                        -Dsonar.exclusions="**/venv/**,**/__pycache__/**,**/htmlcov/**" \
                        -Dsonar.python.coverage.reportPaths=coverage.xml \
                        -Dsonar.python.xunit.reportPath=test-results.xml \
                        -Dsonar.host.url=http://3.220.15.201:9000 \
                        -Dsonar.token=$SONAR_TOKEN \
                        -Dsonar.qualitygate.wait=false
                    '''
                }
            }
        }
        
        stage('🐳 Build & Push to ECR') {
            steps {
                echo '🐳 Building and pushing Docker image to ECR...'
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                    sh '''
                        # Login to ECR
                        aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
                        
                        # Build image
                        docker build -t $ECR_REPOSITORY:$IMAGE_TAG .
                        docker tag $ECR_REPOSITORY:$IMAGE_TAG $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
                        docker tag $ECR_REPOSITORY:$IMAGE_TAG $ECR_REGISTRY/$ECR_REPOSITORY:latest
                        
                        # Push to ECR
                        docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
                        docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
                        
                        echo "✅ Image pushed: $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"
                    '''
                }
            }
        }
        
        stage('📝 Update K8s Manifests') {
            steps {
                echo '📝 Updating Kubernetes manifests...'
                sh '''
                    # Update the image tag in k8s manifests
                    sed -i "s|image: .*currency-converter.*|image: $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG|g" k8s-manifests/deployment.yaml
                    
                    # Configure git
                    git config user.email "jenkins@ci.local"
                    git config user.name "Jenkins CI"
                    
                    # Check if there are changes
                    if git diff --quiet k8s-manifests/deployment.yaml; then
                        echo "No changes to k8s manifests"
                    else
                        echo "Updated k8s manifest with image: $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"
                        git add k8s-manifests/deployment.yaml
                        git commit -m "CI: Update image to $IMAGE_TAG [skip ci]"
                        
                        # Push changes (ArgoCD will detect and deploy)
                        git push origin main || echo "Push failed - continuing anyway"
                    fi
                '''
            }
        }
    }
    
    post {
        always {
            script {
                try {
                    echo '🧹 Cleaning up local Docker images...'
                    sh '''
                        docker rmi $ECR_REPOSITORY:$IMAGE_TAG || true
                        docker rmi $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG || true
                        docker rmi $ECR_REGISTRY/$ECR_REPOSITORY:latest || true
                    '''
                } catch (Exception e) {
                    echo "⚠️ Cleanup failed: ${e.getMessage()}"
                }
            }
        }
        success {
            echo '✅ Pipeline completed successfully! 🎉'
            echo "📦 Docker Image: $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"
            echo "🚀 ArgoCD will deploy this automatically!"
        }
        failure {
            echo '❌ Pipeline failed!'
        }
    }
}