pipeline {
    agent any
    
    environment {
        AWS_REGION = 'us-east-1'
        ECR_REPOSITORY = 'currency-converter'
        AWS_ACCOUNT_ID = '718043211627'
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_TAG = "${BUILD_NUMBER}"
        SONAR_PROJECT_KEY = 'currency-converter'
        SONAR_HOST_URL = 'http://ip-172-31-42-227:9000'  // Update with correct IP if needed
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
                            docker run --rm --network sonarnet \
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
                    docker network create test-network || true
                    docker stop currency-test-container 2>/dev/null || true
                    docker rm currency-test-container 2>/dev/null || true
                    docker run -d --name currency-test-container --network test-network \
                        ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}
                    sleep 20
                    docker run --rm --network test-network curlimages/curl:latest \
                        curl -f http://currency-test-container:5000
                    docker stop currency-test-container || true
                    docker rm currency-test-container || true
                    docker network rm test-network || true
                    echo "✅ Tests passed!"
                '''
            }
        }
        
        stage('🔐 ECR Login') {
            steps {
                echo 'Logging into ECR...'
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                    sh '''
                        aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${ECR_REGISTRY}
                    '''
                }
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
        
        stage('🚀 Deploy to EKS') {
            when {
                branch 'main'
            }
            steps {
                echo 'Deploying to EKS...'
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                    sh '''
                        kubectl apply -f k8s-manifests/deployment.yaml
                        kubectl apply -f k8s-manifests/service.yaml
                    '''
                }
            }
        }
    }
    
    post {
        always {
            echo '🧹 Cleanup...'
            node {
                sh '''
                    docker rmi ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG} || true
                    docker rmi ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest || true
                    docker system prune -f
                '''
            }
        }
        success {
            echo '✅ Pipeline completed!'
        }
        failure {
            echo '❌ Pipeline failed!'
        }
    }
}
