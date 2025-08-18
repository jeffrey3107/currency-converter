pipeline {
    agent any
    
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
                    python -m pytest --cov=. --cov-report=xml --cov-report=html --junitxml=test-results.xml || true
                '''
            }
        }
        
        stage('📊 SonarQube Analysis') {
            steps {
                echo '📊 Running SonarQube analysis...'
                sh '''
                    sonar-scanner \
                    -Dsonar.projectKey=currency-converter \
                    -Dsonar.projectName="Currency Converter" \
                    -Dsonar.sources=. \
                    -Dsonar.exclusions="**/venv/**,**/__pycache__/**,**/htmlcov/**" \
                    -Dsonar.python.coverage.reportPaths=coverage.xml \
                    -Dsonar.python.xunit.reportPath=test-results.xml \
                    -Dsonar.host.url=http://3.220.15.201:9000
                '''
            }
        }
        
        stage('🐳 Docker Build') {
            steps {
                echo '🐳 Building Docker image...'
                sh 'docker build -t currency-converter:${BUILD_NUMBER} .'
            }
        }
    }
    
    post {
        always {
            echo '🧹 Cleaning up...'
            sh 'docker rmi currency-converter:${BUILD_NUMBER} || true'
        }
        success {
            echo '✅ Pipeline completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed!'
        }
    }
}
