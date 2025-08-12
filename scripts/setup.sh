bash#!/bin/bash
# Complete infrastructure setup

echo "🚀 Setting up Currency Converter Enterprise Infrastructure..."

# Check prerequisites
check_requirements() {
    echo "🔧 Checking requirements..."
    
    # Check if terraform exists
    if ! command -v terraform &> /dev/null; then
        echo "❌ Terraform not installed"
        echo "💡 Installing Terraform..."
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
        sudo yum -y install terraform
    fi
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        echo "❌ AWS CLI not installed"
        exit 1
    fi
    
    # Check if terraform folder exists
    if [ ! -d "terraform" ]; then
        echo "❌ terraform/ folder not found!"
        echo "💡 Please add terraform files first"
        exit 1
    fi
    
    echo "✅ All requirements met"
}

# Deploy infrastructure
deploy_infrastructure() {
    echo "🏗️ Deploying infrastructure..."
    
    cd terraform
    
    # Check if terraform.tfvars exists
    if [ ! -f "terraform.tfvars" ]; then
        echo "📝 Creating terraform.tfvars from example..."
        cp terraform.tfvars.example terraform.tfvars
        echo "⚠️  Please edit terraform.tfvars with your settings!"
        echo "⚠️  Especially update: key_name = \"29jul25\""
        exit 1
    fi
    
    # Initialize and deploy
    terraform init
    terraform plan
    
    echo ""
    read -p "🤔 Deploy this infrastructure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🚀 Deploying... (this takes ~20 minutes)"
        terraform apply -auto-approve
        
        echo ""
        echo "🎉 Deployment complete!"
        echo "🌐 Access URLs:"
        terraform output
    else
        echo "❌ Deployment cancelled"
    fi
    
    cd ..
}

# Main execution
main() {
    check_requirements
    deploy_infrastructure
}

# Run the script
main
