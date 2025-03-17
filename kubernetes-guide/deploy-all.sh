#!/bin/bash
# Script to deploy and test the Sparta app on the remote Minikube cluster

# Source configuration
source ./config.env
REMOTE_SERVER="${REMOTE_USER}@${REMOTE_SERVER_IP}"

# Make deploy-sparta.sh executable if it's not already
chmod +x ./deploy-sparta.sh

# Deploy the application
echo "Starting deployment..."
./deploy-sparta.sh

# Verify pods are running
echo -e "\n\nVerifying pods are running..."
ssh ${REMOTE_SERVER} "kubectl get pods"

# Configure Minikube auto-start
echo -e "\n\nConfiguring Minikube auto-start..."
ssh ${REMOTE_SERVER} "sudo chmod +x ~/sparta-app/minikube-startup.sh && sudo ~/sparta-app/minikube-startup.sh"

# Test HPA
echo -e "\n\nApplying load test for HPA..."
ssh ${REMOTE_SERVER} "kubectl apply -f ~/sparta-app/load-test.yml"

# Monitor HPA scaling (will need to be manually interrupted)
echo -e "\n\nMonitoring HPA scaling (press Ctrl+C to stop)..."
ssh ${REMOTE_SERVER} "kubectl get hpa sparta-node-hpa -w"
