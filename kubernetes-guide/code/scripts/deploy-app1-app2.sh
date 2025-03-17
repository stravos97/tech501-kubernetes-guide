#!/bin/bash

# Source configuration
source ../config/config.env
REMOTE_SERVER="${REMOTE_USER}@${REMOTE_SERVER_IP}"

# First, check if Minikube is running on the VM
echo "Checking if Minikube is running on the VM..."
MINIKUBE_STATUS=$(ssh $REMOTE_SERVER "minikube status | grep -c 'host: Running'")

if [ "$MINIKUBE_STATUS" -ne 1 ]; then
    echo "Error: Minikube is not running on the VM. Please start it first."
    echo "You can start it by running: ssh $REMOTE_SERVER 'minikube start'"
    exit 1
fi

echo "Minikube is running. Proceeding with deployment..."

# Create directories on the VM
ssh $REMOTE_SERVER "mkdir -p ~/app1 ~/app2"

# Copy files to the VM
scp code/app1/app1-deploy.yml code/app1/app1-service.yml $REMOTE_SERVER:~/app1/
scp code/app2/app2-deploy.yml code/app2/app2-service.yml $REMOTE_SERVER:~/app2/
scp code/config/nginx-config-lb $REMOTE_SERVER:~/nginx-config-lb

# Apply the Kubernetes manifests on the VM
echo "Applying Kubernetes manifests..."
ssh $REMOTE_SERVER "kubectl apply -f ~/app1/app1-deploy.yml"
ssh $REMOTE_SERVER "kubectl apply -f ~/app1/app1-service.yml"
ssh $REMOTE_SERVER "kubectl apply -f ~/app2/app2-deploy.yml"
ssh $REMOTE_SERVER "kubectl apply -f ~/app2/app2-service.yml"

# Kill any existing minikube tunnel processes
echo "Stopping any existing minikube tunnel processes..."
ssh $REMOTE_SERVER "pkill -f 'minikube tunnel' || true"

# Start minikube tunnel in the background but capture output to a log file
echo "Starting minikube tunnel..."
ssh $REMOTE_SERVER "nohup minikube tunnel > minikube_tunnel.log 2>&1 &"
ssh $REMOTE_SERVER "echo 'Minikube tunnel started with PID: \$(pgrep -f \"minikube tunnel\")'"

# Give the tunnel a moment to initialize
echo "Waiting for tunnel to initialize..."
sleep 5

# Wait for LoadBalancer to get an external IP
echo "Waiting for LoadBalancer to get an external IP..."
ATTEMPTS=0
MAX_ATTEMPTS=30
LOADBALANCER_IP=""

while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    LOADBALANCER_IP=$(ssh $REMOTE_SERVER "kubectl get service app2-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'")
    if [ -n "$LOADBALANCER_IP" ]; then
        echo "LoadBalancer IP: $LOADBALANCER_IP"
        break
    fi
    ATTEMPTS=$((ATTEMPTS+1))
    echo "Attempt $ATTEMPTS/$MAX_ATTEMPTS: Waiting for LoadBalancer IP..."
    
    # If we're on the 5th attempt, check the tunnel log for any issues
    if [ $ATTEMPTS -eq 5 ]; then
        echo "Checking minikube tunnel log:"
        ssh $REMOTE_SERVER "cat minikube_tunnel.log"
    fi
    
    sleep 2
done

if [ -z "$LOADBALANCER_IP" ]; then
    echo "Error: Failed to get LoadBalancer IP after $MAX_ATTEMPTS attempts."
    echo "Final minikube tunnel log:"
    ssh $REMOTE_SERVER "cat minikube_tunnel.log"
    exit 1
fi

# We're now using kubernetes.docker.internal in the nginx config
# This hostname only works when minikube tunnel is running
echo "Using kubernetes.docker.internal in nginx config (requires minikube tunnel)"
echo "LoadBalancer IP for reference: $LOADBALANCER_IP"

# No need to replace any placeholder in the nginx config
echo "Configuring nginx..."

# Install nginx if not already installed
ssh $REMOTE_SERVER "if ! command -v nginx &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y nginx
fi"

# Configure nginx
ssh $REMOTE_SERVER "sudo cp ~/nginx-config-lb /etc/nginx/sites-available/default"
echo "Testing nginx configuration..."
ssh $REMOTE_SERVER "sudo nginx -t && sudo systemctl restart nginx"

# Check the status of the deployments
echo "Checking deployment status:"
ssh $REMOTE_SERVER "kubectl get deployments"
echo "Checking service status:"
ssh $REMOTE_SERVER "kubectl get services"
