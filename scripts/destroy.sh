#!/bin/bash
# Destroy all infrastructure

echo "🧹 Currency Converter Infrastructure Cleanup"

# Warning
echo "⚠️  WARNING: This will destroy ALL infrastructure!"
echo "⚠️  This includes:"
echo "   - Jenkins server"
echo "   - EKS cluster" 
echo "   - ECR repository"
echo "   - All data and configurations"
echo ""

read -p "🤔 Are you SURE you want to destroy everything? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗑️ Destroying infrastructure..."
    
    cd terraform
    terraform destroy -auto-approve
    
    echo "✅ Infrastructure destroyed"
    echo "💰 AWS charges stopped"
else
    echo "❌ Cleanup cancelled - infrastructure preserved"
fi
