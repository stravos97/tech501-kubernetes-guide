#!/bin/bash
# Script to connect to a Sparta app pod and run npm install manually

# Source configuration
source ../config/config.env
REMOTE_SERVER="${REMOTE_USER}@${REMOTE_SERVER_IP}"

# Exit on error
set -e

echo "Connecting to Sparta app pod for manual npm install..."

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

# Instructions for manual npm install and database seeding
echo ""
echo "=== MANUAL NPM INSTALL AND DATABASE SEEDING INSTRUCTIONS ==="
echo ""
echo "1. You will be connected to the Sparta app pod."
echo "2. Once connected, run the following commands:"
echo "   cd /app"
echo "   npm install"
echo "3. After npm install completes, seed the database with:"
echo "   node seeds/seed.js"
echo "4. After seeding completes, you can exit the pod by typing 'exit'."
echo ""
echo "Press Enter to connect to the pod..."
read -r

# Connect to the pod
echo "Connecting to pod $POD_NAME..."
ssh -t $REMOTE_SERVER "kubectl exec -it $POD_NAME -- /bin/bash"

echo ""
echo "Connection to pod closed."
echo "npm install and database seeding should now be complete."
echo ""
echo "To verify the application is working correctly, access it at: http://${REMOTE_SERVER_IP}"
