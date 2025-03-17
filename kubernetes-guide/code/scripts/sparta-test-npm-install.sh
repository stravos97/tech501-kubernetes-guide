#!/bin/bash
# Script to test the manual npm install process for the Sparta app

# Source configuration
source ./config.env
REMOTE_SERVER="${REMOTE_USER}@${REMOTE_SERVER_IP}"

# Exit on error
set -e

echo "Testing manual npm install process for Sparta app..."

# Check if we can connect to the remote server
echo "Checking connection to remote server..."
ssh -o ConnectTimeout=5 $REMOTE_SERVER "echo Connection successful" || {
  echo "Error: Cannot connect to remote server. Please check the server address and your SSH configuration."
  exit 1
}

# Check if Minikube is running on the VM
echo "Checking if Minikube is running on the VM..."
MINIKUBE_STATUS=$(ssh $REMOTE_SERVER "minikube status | grep -c 'host: Running'" || echo "0")

if [ "$MINIKUBE_STATUS" -ne 1 ]; then
  echo "Error: Minikube is not running. Please start Minikube first."
  exit 1
fi

# Get the name of a running Sparta app pod
echo "Getting the name of a running Sparta app pod..."
POD_NAME=$(ssh $REMOTE_SERVER "kubectl get pods -l app=sparta-node -o jsonpath='{.items[0].metadata.name}'")

if [ -z "$POD_NAME" ]; then
  echo "Error: No Sparta app pods found. Please deploy the Sparta app first."
  exit 1
fi

echo "Found Sparta app pod: $POD_NAME"

# Test npm install and database seeding inside the pod
echo "Testing npm install and database seeding inside the pod..."
ssh $REMOTE_SERVER "
  echo 'Executing npm install in pod $POD_NAME...'
  kubectl exec $POD_NAME -- bash -c 'cd /app && npm install --dry-run'
  
  if [ \$? -eq 0 ]; then
    echo 'npm install test successful!'
  else
    echo 'npm install test failed!'
    exit 1
  fi
  
  echo 'Testing database seeding script...'
  kubectl exec $POD_NAME -- bash -c 'cd /app && ls -la seeds/seed.js'
  
  if [ \$? -eq 0 ]; then
    echo 'Database seeding script found!'
  else
    echo 'Database seeding script not found!'
    exit 1
  fi
"

# Test application access
echo "Testing application access..."
MINIKUBE_IP=$(ssh $REMOTE_SERVER "minikube ip")
echo "Minikube IP: $MINIKUBE_IP"

echo "Testing direct access to app on Minikube..."
ssh $REMOTE_SERVER "curl -s http://$MINIKUBE_IP:30003 | grep -q 'Sparta' && echo 'Direct access successful!' || echo 'Direct access failed!'"

echo "Testing access through Nginx proxy..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://${REMOTE_SERVER_IP})
if [ "$RESPONSE" = "200" ]; then
  echo "Nginx proxy access successful!"
else
  echo "Nginx proxy access failed with HTTP code: $RESPONSE"
fi

echo "Manual npm install test completed!"
