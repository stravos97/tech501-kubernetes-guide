#!/bin/bash
# Script to test the database seeding solution locally

# Exit on error
set -e

echo "Starting database seeding test..."

# Apply the PV and PVC first
echo "Creating PV and PVC..."
kubectl apply -f ../sparta/sparta-pv.yml

# Deploy the database
echo "Deploying MongoDB..."
kubectl apply -f ../sparta/sparta-deploy.yml -l app=sparta-db

# Create the services
echo "Creating services..."
kubectl apply -f ../sparta/sparta-service.yml

# Wait for database to be ready
echo "Waiting for MongoDB to be ready..."
kubectl wait --for=condition=ready pod -l app=sparta-db --timeout=120s

# Apply the database seeding job
echo "Running database seeding job..."
kubectl apply -f ../sparta/sparta-db-seed-job.yml

# Wait for the job to start
echo "Waiting for seeding job to start..."
sleep 5

# Get the pod name for the seeding job
SEED_POD=$(kubectl get pods -l job-name=sparta-db-seed-job -o jsonpath='{.items[0].metadata.name}')

# Wait for the job to complete
echo "Waiting for seeding job to complete..."
kubectl wait --for=condition=complete job/sparta-db-seed-job --timeout=120s

# Show logs from the seeding job
echo "Database seeding job logs:"
kubectl logs $SEED_POD -c db-seed

# Deploy the app
echo "Deploying Sparta app..."
kubectl apply -f ../sparta/sparta-deploy.yml -l app=sparta-node

# Wait for the app to be ready
echo "Waiting for app to be ready..."
kubectl wait --for=condition=ready pod -l app=sparta-node --timeout=120s

# Check if the app can access the database
echo "Checking if app can access the database..."
APP_POD=$(kubectl get pods -l app=sparta-node -o jsonpath='{.items[0].metadata.name}')
kubectl logs $APP_POD

# Get the NodePort for the app
NODE_PORT=$(kubectl get service sparta-node-service -o jsonpath='{.spec.ports[0].nodePort}')
MINIKUBE_IP=$(minikube ip)

echo "Test completed. You can access the app at: http://${MINIKUBE_IP}:${NODE_PORT}"
echo "If the app shows posts, the database seeding was successful."
