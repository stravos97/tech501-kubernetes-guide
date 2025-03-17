#!/bin/bash
# Script to deploy the Sparta app on the remote Minikube cluster

# Source configuration
source ./config.env
REMOTE_SERVER="${REMOTE_USER}@${REMOTE_SERVER_IP}"

# Exit on error
set -e

echo "Starting Sparta app deployment on remote Minikube cluster..."

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
  echo "Minikube is not running. Starting Minikube..."
  ssh $REMOTE_SERVER "minikube start" || {
    echo "Error: Failed to start Minikube. Please check the remote server."
    exit 1
  }
else
  echo "Minikube is already running."
fi

# Create remote directory for Kubernetes manifests
echo "Creating directory for Kubernetes manifests on remote server..."
ssh $REMOTE_SERVER "mkdir -p ~/sparta-app"

# Copy Kubernetes manifests to remote server
echo "Copying Kubernetes manifests to remote server..."
scp sparta-deploy.yml sparta-service.yml sparta-pv.yml sparta-hpa.yml sparta-db-seed-job.yml load-test.yml minikube-startup.sh $REMOTE_SERVER:~/sparta-app/

# Copy Nginx configuration template
echo "Copying Nginx configuration template to remote server..."
scp nginx-config-template $REMOTE_SERVER:~/sparta-app/

# Apply Kubernetes manifests on remote server
echo "Applying Kubernetes manifests on remote server..."

# First, create the PV and PVC
echo "Creating PV and PVC..."
ssh $REMOTE_SERVER "kubectl apply -f ~/sparta-app/sparta-pv.yml"

# Deploy the database first
echo "Deploying database..."
ssh $REMOTE_SERVER "kubectl apply -f ~/sparta-app/sparta-deploy.yml -l app=sparta-db"

# Create the services
echo "Creating services..."
ssh $REMOTE_SERVER "kubectl apply -f ~/sparta-app/sparta-service.yml"

# Wait for database to be ready
echo "Waiting for database to be ready..."
ssh $REMOTE_SERVER "kubectl wait --for=condition=ready pod -l app=sparta-db --timeout=120s"

# Note: Database seeding job has been replaced with manual npm install
echo "Skipping automated database seeding job..."
echo "After deployment, use the connect-to-sparta.sh script to manually connect to the pod and run npm install"

# Copy the connect-to-sparta script to the remote server
echo "Copying connect-to-sparta.sh script to remote server..."
scp connect-to-sparta.sh $REMOTE_SERVER:~/sparta-app/
ssh $REMOTE_SERVER "chmod +x ~/sparta-app/connect-to-sparta.sh"

# Deploy the app after database is seeded
echo "Deploying app..."
ssh $REMOTE_SERVER "kubectl apply -f ~/sparta-app/sparta-deploy.yml -l app=sparta-node"

# Apply HPA configuration
echo "Configuring Horizontal Pod Autoscaler..."
ssh $REMOTE_SERVER "kubectl apply -f ~/sparta-app/sparta-hpa.yml"

# Install and configure metrics-server if not already installed
echo "Checking if metrics-server is installed..."
METRICS_SERVER_STATUS=$(ssh $REMOTE_SERVER "kubectl get deployment metrics-server -n kube-system 2>/dev/null || echo 'not found'")

if [[ "$METRICS_SERVER_STATUS" == *"not found"* ]]; then
  echo "Installing metrics-server..."
  # Copy metrics-server configuration
  scp infrastructure/metrics-server/metrics-server-fixed.yaml $REMOTE_SERVER:~/sparta-app/
  # Apply metrics-server configuration
  ssh $REMOTE_SERVER "kubectl apply -f ~/sparta-app/metrics-server-fixed.yaml"
else
  echo "Metrics-server is already installed."
fi

# Install and configure Nginx
echo "Installing and configuring Nginx..."
ssh $REMOTE_SERVER "
  # Install Nginx if not already installed
  if ! command -v nginx &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y nginx
  fi

  # Get Minikube IP for Nginx configuration
  MINIKUBE_IP=\$(minikube ip)
  echo \"Using Minikube IP: \${MINIKUBE_IP} for Nginx configuration\"
  
  # Process the Nginx config template with the actual Minikube IP
  sed \"s/MINIKUBE_IP/\${MINIKUBE_IP}/g\" ~/sparta-app/nginx-config-template > ~/sparta-app/nginx-config
  
  # Configure Nginx
  sudo cp ~/sparta-app/nginx-config /etc/nginx/sites-available/default
  sudo nginx -t && sudo systemctl restart nginx
"

# Set up Minikube auto-start
echo "Setting up Minikube auto-start..."
ssh $REMOTE_SERVER "
  # Check available disk space
  AVAILABLE_SPACE=\$(df -h / | awk 'NR==2 {print \$4}' | sed 's/G//')
  
  if (( \$(echo \"\$AVAILABLE_SPACE < 1\" | bc -l) )); then
    echo \"Warning: Low disk space (\${AVAILABLE_SPACE}GB available). Skipping auto-start setup.\"
    echo \"Please run the minikube-startup.sh script manually after increasing disk space.\"
  else
    chmod +x ~/sparta-app/minikube-startup.sh && sudo ~/sparta-app/minikube-startup.sh
  fi
"

# Check deployment status
echo "Checking deployment status..."
ssh $REMOTE_SERVER "kubectl get pods"
ssh $REMOTE_SERVER "kubectl get services"
ssh $REMOTE_SERVER "kubectl get pv,pvc"
ssh $REMOTE_SERVER "kubectl get hpa"

# Wait for all pods to be ready
echo "Waiting for all pods to be ready..."
ssh $REMOTE_SERVER "
  echo 'Waiting for database pod to be ready...'
  kubectl wait --for=condition=ready pod -l app=sparta-db --timeout=120s
  
  echo 'Waiting for app pods to be ready...'
  kubectl wait --for=condition=ready pod -l app=sparta-node --timeout=120s
  
  echo 'All pods are ready!'
"

echo "Sparta app deployment completed successfully!"
echo "You can access the app at: http://${REMOTE_SERVER_IP}"
echo ""
echo "IMPORTANT: You need to run npm install and database seeding in the Sparta app pod."
echo ""

# Make connect-to-sparta.sh executable if it's not already
chmod +x ./connect-to-sparta.sh

# Prompt for connecting to the pod
echo "Do you want to connect to the pod now to run npm install and database seeding? (y/n)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo "Connecting to Sparta app pod..."
  ./connect-to-sparta.sh
else
  echo "Skipping connection to pod."
  echo "To manually connect later, run the following command:"
  echo "./connect-to-sparta.sh"
  echo ""
  echo "This will connect you to the pod where you can run:"
  echo "  cd /app"
  echo "  npm install"
  echo "  node seeds/seed.js"
fi
echo ""
echo "To test HPA, you can run the load test with:"
echo "ssh $REMOTE_SERVER \"kubectl apply -f ~/sparta-app/load-test.yml\""
echo ""
echo "To monitor HPA scaling, use:"
echo "ssh $REMOTE_SERVER \"kubectl get hpa sparta-node-hpa -w\""
