#!/bin/bash

echo "🔍 Checking infrastructure status..."

echo ""
echo "☸️  EKS Nodes:"
kubectl get nodes

echo ""
echo "📦 All Pods:"
kubectl get pods --all-namespaces

echo ""
echo "🌐 LoadBalancer Services:"
kubectl get svc --all-namespaces | grep LoadBalancer

echo ""
echo "📱 ArgoCD Admin Password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""

echo ""
echo "🔗 Access URLs:"
GRAFANA_LB=$(kubectl get svc -n monitoring prometheus-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
ARGOCD_LB=$(kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Grafana: http://$GRAFANA_LB"
echo "ArgoCD:  http://$ARGOCD_LB"
