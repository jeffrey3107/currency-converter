pipeline {
    agent any
    
    environment {
        AWS_REGION = 'us-east-1'
        ECR_REPOSITORY = 'currency-converter'
        AWS_ACCOUNT_ID = '718043211627'
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_TAG = "${BUILD_NUMBER}"
        SONAR_PROJECT_KEY = 'currency-converter'
    }
    
    stages {
        stage('📥 Checkout') {
            steps {
                echo 'Checking out code...'
                checkout scm
            }
        }
        
        stage('📊 SonarQube Analysis') {
            steps {
                echo 'Running code quality analysis...'
                script {
                    sh '''
                        cat > sonar-project.properties << EOFSONAR
sonar.projectKey=${SONAR_PROJECT_KEY}
sonar.projectName=Currency Converter
sonar.projectVersion=1.0
sonar.sources=.
sonar.exclusions=**/*.log,**/venv/**,**/__pycache__/**
EOFSONAR
                    '''
                    
                    withSonarQubeEnv('SonarQube') {
                        sh '''
                            docker run --rm --network host \
                                -v "${PWD}:/usr/src" \
                                -w /usr/src \
                                sonarsource/sonar-scanner-cli:latest \
                                -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                                -Dsonar.sources=. \
                                -Dsonar.host.url=$SONAR_HOST_URL \
                                -Dsonar.login=$SONAR_AUTH_TOKEN
                        '''
                    }
                }
            }
        }
        
        stage('🐳 Build Image') {
            steps {
                echo 'Building Docker image...'
                sh '''
                    docker build -t ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG} .
                    docker tag ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG} \
                        ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
                    echo "✅ Built: ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
                '''
            }
        }
        
        stage('🧪 Test Image') {
            steps {
                echo 'Testing Docker image...'
                sh '''
                    docker stop currency-test-container 2>/dev/null || true
                    docker rm currency-test-container 2>/dev/null || true
                    
                    CONTAINER_ID=$(docker run -d --name currency-test-container -p 5001:5000 \
                        ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG})
                    
                    sleep 15
                    curl -f http://localhost:5001 || exit 1
                    
                    docker stop currency-test-container || true
                    docker rm currency-test-container || true
                    echo "✅ Tests passed!"
                '''
            }
        }
        
        stage('🔐 ECR Login') {
            steps {
                echo 'Logging into ECR...'
                sh '''
                    aws ecr get-login-password --region ${AWS_REGION} | \
                    docker login --username AWS --password-stdin ${ECR_REGISTRY}
                '''
            }
        }
        
        stage('📤 Push to ECR') {
            steps {
                echo 'Pushing to ECR...'
                sh '''
                    docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}
                    docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
                    echo "✅ Pushed: ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
                '''
            }
        }
        
        stage('🚀 Deploy') {
            when {
                branch 'main'
            }
            steps {
                echo 'Deploying to EC2...'
                sh '''
                    docker stop currency-converter-app || true
                    docker rm currency-converter-app || true
                    
                    docker pull ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
                    
                    docker run -d --name currency-converter-app \
                        --restart unless-stopped \
                        -p 5000:5000 \
                        ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
                    
                    sleep 10
                    curl -f http://localhost:5000 || exit 1
                    echo "✅ Deployed successfully!"
                '''
            }
        }
    }
    
    post {
        always {
            echo '🧹 Cleanup...'
            sh '''
                docker rmi ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG} || true
                docker rmi ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest || true
                docker system prune -f
            '''
        }
        success {
            echo '✅ Pipeline completed!'
        }
        failure {
            echo '❌ Pipeline failed!'
        }
    }
}
