#!/bin/bash

# First, check if Minikube is running on the VM
echo "Checking if Minikube is running on the VM..."
MINIKUBE_STATUS=$(ssh ubuntu@52.16.191.37 "minikube status | grep -c 'host: Running'")

if [ "$MINIKUBE_STATUS" -ne 1 ]; then
    echo "Error: Minikube is not running on the VM. Please start it first."
    echo "You can start it by running: ssh ubuntu@52.16.191.37 'minikube start'"
    exit 1
fi

echo "Minikube is running. Proceeding with deployment..."

# Create directories on the VM
ssh ubuntu@52.16.191.37 "mkdir -p ~/app1 ~/app2"

# Copy files to the VM
scp app1/app1-deploy.yml app1/app1-service.yml ubuntu@52.16.191.37:~/app1/
scp app2/app2-deploy.yml app2/app2-service.yml ubuntu@52.16.191.37:~/app2/
scp nginx-config-lb ubuntu@52.16.191.37:~/nginx-config-lb

# Apply the Kubernetes manifests on the VM
echo "Applying Kubernetes manifests..."
ssh ubuntu@52.16.191.37 "kubectl apply -f ~/app1/app1-deploy.yml"
ssh ubuntu@52.16.191.37 "kubectl apply -f ~/app1/app1-service.yml"
ssh ubuntu@52.16.191.37 "kubectl apply -f ~/app2/app2-deploy.yml"
ssh ubuntu@52.16.191.37 "kubectl apply -f ~/app2/app2-service.yml"

# Kill any existing minikube tunnel processes
echo "Stopping any existing minikube tunnel processes..."
ssh ubuntu@52.16.191.37 "pkill -f 'minikube tunnel' || true"

# Start minikube tunnel in the background but capture output to a log file
echo "Starting minikube tunnel..."
ssh ubuntu@52.16.191.37 "nohup minikube tunnel > minikube_tunnel.log 2>&1 &"
ssh ubuntu@52.16.191.37 "echo 'Minikube tunnel started with PID: \$(pgrep -f \"minikube tunnel\")'"

# Give the tunnel a moment to initialize
echo "Waiting for tunnel to initialize..."
sleep 5

# Wait for LoadBalancer to get an external IP
echo "Waiting for LoadBalancer to get an external IP..."
ATTEMPTS=0
MAX_ATTEMPTS=30
LOADBALANCER_IP=""

while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    LOADBALANCER_IP=$(ssh ubuntu@52.16.191.37 "kubectl get service app2-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'")
    if [ -n "$LOADBALANCER_IP" ]; then
        echo "LoadBalancer IP: $LOADBALANCER_IP"
        break
    fi
    ATTEMPTS=$((ATTEMPTS+1))
    echo "Attempt $ATTEMPTS/$MAX_ATTEMPTS: Waiting for LoadBalancer IP..."
    
    # If we're on the 5th attempt, check the tunnel log for any issues
    if [ $ATTEMPTS -eq 5 ]; then
        echo "Checking minikube tunnel log:"
        ssh ubuntu@52.16.191.37 "cat minikube_tunnel.log"
    fi
    
    sleep 2
done

if [ -z "$LOADBALANCER_IP" ]; then
    echo "Error: Failed to get LoadBalancer IP after $MAX_ATTEMPTS attempts."
    echo "Final minikube tunnel log:"
    ssh ubuntu@52.16.191.37 "cat minikube_tunnel.log"
    exit 1
fi

# We're now using kubernetes.docker.internal in the nginx config
# This hostname only works when minikube tunnel is running
echo "Using kubernetes.docker.internal in nginx config (requires minikube tunnel)"
echo "LoadBalancer IP for reference: $LOADBALANCER_IP"

# No need to replace any placeholder in the nginx config
echo "Configuring nginx..."

# Install nginx if not already installed
ssh ubuntu@52.16.191.37 "if ! command -v nginx &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y nginx
fi"

# Configure nginx
ssh ubuntu@52.16.191.37 "sudo cp ~/nginx-config-lb /etc/nginx/sites-available/default"
echo "Testing nginx configuration..."
ssh ubuntu@52.16.191.37 "sudo nginx -t && sudo systemctl restart nginx"

# Check the status of the deployments
echo "Checking deployment status:"
ssh ubuntu@52.16.191.37 "kubectl get deployments"
echo "Checking service status:"
ssh ubuntu@52.16.191.37 "kubectl get services"
