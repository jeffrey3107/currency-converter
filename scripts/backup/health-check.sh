#!/bin/bash
# Check system health

echo "🏥 Currency Converter Health Check"
echo "=================================="

# Check local app (if running locally)
check_local_app() {
    echo "📱 Checking local application..."
    if curl -s http://localhost:5000 > /dev/null; then
        echo "✅ Local currency converter: HEALTHY"
    else
        echo "❌ Local currency converter: DOWN"
    fi
}

# Check infrastructure (if deployed)
check_infrastructure() {
    echo "🏗️ Checking infrastructure..."
    
    if [ -d "terraform" ] && [ -f "terraform/terraform.tfstate" ]; then
        cd terraform
        
        # Get infrastructure URLs
        JENKINS_URL=$(terraform output -raw jenkins_url 2>/dev/null)
        APP_URL=$(terraform output -raw currency_converter_url 2>/dev/null)
        
        if [ ! -z "$JENKINS_URL" ]; then
            echo "🔧 Checking Jenkins..."
            if curl -s "$JENKINS_URL" > /dev/null; then
                echo "✅ Jenkins: HEALTHY - $JENKINS_URL"
            else
                echo "❌ Jenkins: DOWN - $JENKINS_URL"
            fi
        fi
        
        if [ ! -z "$APP_URL" ]; then
            echo "📱 Checking deployed app..."
            if curl -s "$APP_URL" > /dev/null; then
                echo "✅ Currency Converter: HEALTHY - $APP_URL"
            else
                echo "❌ Currency Converter: DOWN - $APP_URL"
            fi
        fi
        
        cd ..
    else
        echo "ℹ️  No infrastructure deployed yet"
    fi
}

# System resources
check_system() {
    echo "💻 System resources..."
    echo "💾 Disk space:"
    df -h | grep -E "(Filesystem|/dev/)" | head -2
    echo "🧠 Memory:"
    free -h | grep -E "(Mem|total)"
}

# Main health check
main() {
    check_local_app
    echo ""
    check_infrastructure  
    echo ""
    check_system
    echo ""
    echo "🏥 Health check complete!"
}

main
