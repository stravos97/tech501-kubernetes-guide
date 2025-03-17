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

# Make sparta-connect.sh executable
chmod +x ./sparta-connect.sh

# Prompt for manual npm install and database seeding
echo -e "\n\nIMPORTANT: You need to manually run npm install and database seeding in the Sparta app pod."
echo "Do you want to connect to the pod now to run npm install and database seeding? (y/n)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo "Connecting to Sparta app pod..."
  ./sparta-connect.sh
else
  echo "Skipping manual npm install and database seeding. Remember to run './sparta-connect.sh' later to complete the setup."
fi

# Configure Minikube auto-start
echo -e "\n\nConfiguring Minikube auto-start..."
ssh ${REMOTE_SERVER} "sudo chmod +x ~/sparta-app/minikube-start.sh && sudo ~/sparta-app/minikube-start.sh"

# Test HPA
echo -e "\n\nApplying load test for HPA..."
ssh ${REMOTE_SERVER} "kubectl apply -f ~/sparta-app/load-test.yml"

# Monitor HPA scaling (will need to be manually interrupted)
echo -e "\n\nMonitoring HPA scaling (press Ctrl+C to stop)..."
ssh ${REMOTE_SERVER} "kubectl get hpa sparta-node-hpa -w"
