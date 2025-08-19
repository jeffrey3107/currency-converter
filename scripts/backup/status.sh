#!/bin/bash
# Show current system status

echo "📊 Currency Converter System Status"
echo "==================================="

# Show infrastructure status
if [ -d "terraform" ] && [ -f "terraform/terraform.tfstate" ]; then
    echo "🏗️ Infrastructure: DEPLOYED"
    cd terraform
    echo "📋 Access URLs:"
    terraform output 2>/dev/null || echo "   Run 'terraform output' for URLs"
    cd ..
else
    echo "🏗️ Infrastructure: NOT DEPLOYED"
fi

echo ""

# Show local app status
if pgrep -f "python3 app.py" > /dev/null; then
    echo "📱 Local App: RUNNING"
    echo "🌐 Local URL: http://localhost:5000"
else
    echo "📱 Local App: STOPPED"
fi

echo ""

# Show git status
echo "📚 Repository Status:"
git status --porcelain | head -5
if [ -z "$(git status --porcelain)" ]; then
    echo "   ✅ Repository is clean"
else
    echo "   ⚠️  Uncommitted changes exist"
fi

echo ""
echo "📊 Status check complete!"
