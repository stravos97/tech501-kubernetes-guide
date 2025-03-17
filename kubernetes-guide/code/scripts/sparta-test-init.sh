#!/bin/bash
# Script to test the Sparta app deployment with init container locally

# Exit on error
set -e

echo "Starting Sparta app deployment test..."

# Apply the PV and PVC first
echo "Creating PV and PVC..."
kubectl apply -f ../sparta/sparta-pv.yml

# Deploy the database
echo "Deploying MongoDB..."
kubectl apply -f ../sparta/sparta-deploy.yml

# Create the services
echo "Creating services..."
kubectl apply -f ../sparta/sparta-service.yml

# Watch the pods to see the init container in action
echo "Watching pods to see init container in action..."
echo "Press Ctrl+C when you want to stop watching"
kubectl get pods -w

# Check the logs of the init container
echo "Checking logs of the init container..."
SPARTA_POD=$(kubectl get pods -l app=sparta-node -o jsonpath='{.items[0].metadata.name}')
kubectl logs $SPARTA_POD -c wait-for-mongodb

# Check if the app is running correctly
echo "Checking if the app is running correctly..."
MINIKUBE_IP=$(minikube ip)
echo "You can access the app at: http://${MINIKUBE_IP}:30003"

# Check the logs of the main container
echo "Checking logs of the main container..."
kubectl logs $SPARTA_POD -c sparta-app

echo "Test completed. If you see the app running correctly, the init container is working as expected."
