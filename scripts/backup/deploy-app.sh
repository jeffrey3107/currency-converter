#!/bin/bash
# Deploy/update just the application

echo "📱 Deploying Currency Converter Application"

# Update local app
update_local() {
    echo "🔄 Updating local application..."
    
    # Pull latest code
    git pull origin main
    
    # Restart local app if running
    if pgrep -f "python3 app.py" > /dev/null; then
        echo "🔄 Restarting local app..."
        pkill -f "python3 app.py"
        sleep 2
        nohup python3 app.py > app.log 2>&1 &
        echo "✅ Local app restarted"
    else
        echo "ℹ️  Local app not running"
    fi
}

# Deploy to Kubernetes (if infrastructure exists)
deploy_to_k8s() {
    echo "🚀 Deploying to Kubernetes..."
    
    if command -v kubectl &> /dev/null; then
        # Check if connected to cluster
        if kubectl cluster-info &> /dev/null; then
            echo "🔄 Updating Kubernetes deployment..."
            kubectl apply -f k8s-manifests/
            kubectl rollout restart deployment/currency-converter
            echo "✅ Kubernetes deployment updated"
        else
            echo "ℹ️  Not connected to Kubernetes cluster"
        fi
    else
        echo "ℹ️  kubectl not available"
    fi
}

# Main deployment
main() {
    update_local
    echo ""
    deploy_to_k8s
    echo ""
    echo "📱 Application deployment complete!"
}

main
