# outputs.tf - Infrastructure Outputs

# VPC Information
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# Jenkins Information
output "jenkins_instance_id" {
  description = "ID of the Jenkins EC2 instance"
  value       = aws_instance.jenkins.id
}

output "jenkins_public_ip" {
  description = "Public IP address of Jenkins server"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_public_dns" {
  description = "Public DNS name of Jenkins server"
  value       = aws_instance.jenkins.public_dns
}

output "jenkins_url" {
  description = "Jenkins web interface URL"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "currency_converter_url" {
  description = "Currency converter app URL on Jenkins server"
  value       = "http://${aws_instance.jenkins.public_ip}:5000"
}

output "argocd_url" {
  description = "ArgoCD web interface URL"
  value       = "http://${aws_instance.jenkins.public_ip}:8081"
}

# EKS Information
output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "eks_cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

# ECR Information
output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.currency_converter.repository_url
}

output "ecr_repository_name" {
  description = "ECR repository name"
  value       = aws_ecr_repository.currency_converter.name
}

# SSH Access
output "ssh_command" {
  description = "SSH command to connect to Jenkins server"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${aws_instance.jenkins.public_ip}"
}

# Complete Infrastructure Summary
output "infrastructure_summary" {
  description = "Complete infrastructure access information"
  value = {
    jenkins_dashboard    = "http://${aws_instance.jenkins.public_ip}:8080"
    currency_converter   = "http://${aws_instance.jenkins.public_ip}:5000"
    argocd_dashboard    = "http://${aws_instance.jenkins.public_ip}:8081"
    eks_cluster         = aws_eks_cluster.main.name
    ecr_repository      = aws_ecr_repository.currency_converter.repository_url
    ssh_access          = "ssh -i ${var.key_name}.pem ec2-user@${aws_instance.jenkins.public_ip}"
  }
}

# Kubectl Configuration Command
output "kubectl_config_command" {
  description = "Command to configure kubectl for EKS cluster"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}
