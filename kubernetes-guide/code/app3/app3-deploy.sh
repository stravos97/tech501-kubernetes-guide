#!/bin/bash
# Script to deploy the hello-minikube application (App3)

# Function to handle errors
handle_error() {
    echo "ERROR: $1"
    exit 1
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Exit on error with message
set -e

echo "Deploying hello-minikube application (App3)..."

# Load configuration from config.env
if [ -f "code/config/config.env" ]; then
    source code/config/config.env
    echo "Loaded configuration from config.env"
    echo "Remote server: $REMOTE_USER@$REMOTE_SERVER_IP"
else
    handle_error "config.env file not found. Please ensure it exists in the current directory."
fi

# Check for required commands
command_exists ssh || handle_error "ssh not found. Please install ssh."
command_exists scp || handle_error "scp not found. Please install scp."

echo "Deploying to remote server: $REMOTE_USER@$REMOTE_SERVER_IP"

# Copy deployment files to remote server
echo "Copying deployment files to remote server..."
ssh $REMOTE_USER@$REMOTE_SERVER_IP "mkdir -p ~/app3" || handle_error "Failed to create app3 directory on remote server"
scp code/app3/app3-deploy.yml code/app3/app3-service.yml $REMOTE_USER@$REMOTE_SERVER_IP:~/app3/ || handle_error "Failed to copy deployment files to remote server"

# Apply Kubernetes configurations on remote server
echo "Applying Kubernetes configurations on remote server..."
ssh $REMOTE_USER@$REMOTE_SERVER_IP "kubectl apply -f ~/app3/app3-deploy.yml" || handle_error "Failed to apply app3-deploy.yml"
ssh $REMOTE_USER@$REMOTE_SERVER_IP "kubectl apply -f ~/app3/app3-service.yml" || handle_error "Failed to apply app3-service.yml"

# Check if minikube tunnel is running on remote server
echo "Checking if minikube tunnel is running on remote server..."
TUNNEL_RUNNING=$(ssh $REMOTE_USER@$REMOTE_SERVER_IP "pgrep -f 'minikube tunnel' || echo ''")
if [ -z "$TUNNEL_RUNNING" ]; then
    echo "Starting minikube tunnel in the background on remote server..."
    ssh $REMOTE_USER@$REMOTE_SERVER_IP "nohup minikube tunnel > minikube_tunnel.log 2>&1 &"
    echo "Waiting for tunnel to initialize..."
    sleep 10
else
    echo "Minikube tunnel is already running on remote server."
fi

# Wait for LoadBalancer to get an external IP
echo "Waiting for LoadBalancer to get an external IP on remote server..."
ATTEMPTS=0
MAX_ATTEMPTS=15
LOADBALANCER_IP=""
while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    ATTEMPTS=$((ATTEMPTS+1))
    echo "Attempt $ATTEMPTS of $MAX_ATTEMPTS..."
    
    # Get the external IP of the LoadBalancer service
    LOADBALANCER_IP=$(ssh $REMOTE_USER@$REMOTE_SERVER_IP "kubectl get svc app3-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo ''")
    LOADBALANCER_HOSTNAME=$(ssh $REMOTE_USER@$REMOTE_SERVER_IP "kubectl get svc app3-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo ''")
    
    # Check if we have either an IP or hostname
    if [ -n "$LOADBALANCER_IP" ]; then
        echo "LoadBalancer IP: $LOADBALANCER_IP"
        break
    elif [ -n "$LOADBALANCER_HOSTNAME" ]; then
        echo "LoadBalancer Hostname: $LOADBALANCER_HOSTNAME"
        LOADBALANCER_IP=$LOADBALANCER_HOSTNAME
        break
    fi
    
    # Check if the service has been assigned a port
    SERVICE_PORT=$(ssh $REMOTE_USER@$REMOTE_SERVER_IP "kubectl get svc app3-service -o jsonpath='{.spec.ports[0].port}' 2>/dev/null || echo ''")
    if [ -n "$SERVICE_PORT" ] && [ $ATTEMPTS -eq $MAX_ATTEMPTS ]; then
        echo "Service port $SERVICE_PORT is available but no external IP was assigned."
        echo "Using localhost as fallback."
        LOADBALANCER_IP="localhost"
        break
    fi
    
    if [ $ATTEMPTS -eq $MAX_ATTEMPTS ]; then
        echo "Warning: Failed to get LoadBalancer IP after $MAX_ATTEMPTS attempts."
        echo "Using localhost as fallback."
        LOADBALANCER_IP="localhost"
        break
    fi
    
    echo "Waiting for LoadBalancer IP..."
    sleep 5
done

# Update Nginx configuration on remote server
echo "Updating Nginx configuration on remote server..."
# First, get the current Nginx configuration
ssh $REMOTE_USER@$REMOTE_SERVER_IP "cat /etc/nginx/sites-available/default" > remote_nginx_config.tmp || handle_error "Failed to get Nginx configuration from remote server"

# Check if /hello location already exists
if ! grep -q "location /hello" remote_nginx_config.tmp; then
    # Create a modified configuration with the /hello location
    cat remote_nginx_config.tmp | sed '/server_name _;/a \
    location /hello {\
        proxy_pass http://'"$LOADBALANCER_IP"':8080;\
        proxy_set_header Host $host;\
        proxy_set_header X-Real-IP $remote_addr;\
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\
        proxy_set_header X-Forwarded-Proto $scheme;\
    }' > remote_nginx_config_updated.tmp
    
    # Copy the updated configuration back to the remote server
    scp remote_nginx_config_updated.tmp $REMOTE_USER@$REMOTE_SERVER_IP:/tmp/nginx_config_updated || handle_error "Failed to copy updated Nginx configuration to remote server"
    ssh $REMOTE_USER@$REMOTE_SERVER_IP "sudo cp /tmp/nginx_config_updated /etc/nginx/sites-available/default" || handle_error "Failed to update Nginx configuration on remote server"
    
    # Reload Nginx on remote server
    echo "Reloading Nginx on remote server..."
    ssh $REMOTE_USER@$REMOTE_SERVER_IP "sudo systemctl reload nginx" || handle_error "Failed to reload Nginx on remote server"
    
    echo "Nginx configuration updated with /hello location."
else
    echo "Nginx configuration already contains /hello location."
fi

# Clean up temporary files
rm -f remote_nginx_config.tmp remote_nginx_config_updated.tmp

# Wait for pods to be ready
echo "Waiting for pods to be ready on remote server..."
ATTEMPTS=0
MAX_ATTEMPTS=20
while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    ATTEMPTS=$((ATTEMPTS+1))
    echo "Attempt $ATTEMPTS of $MAX_ATTEMPTS..."
    
    # Check if all pods are ready
    READY_PODS=$(ssh $REMOTE_USER@$REMOTE_SERVER_IP "kubectl get pods -l app=app3 -o jsonpath='{.items[*].status.containerStatuses[0].ready}' 2>/dev/null | tr ' ' '\n' | grep -c 'true' || echo '0'")
    TOTAL_PODS=$(ssh $REMOTE_USER@$REMOTE_SERVER_IP "kubectl get pods -l app=app3 --no-headers 2>/dev/null | wc -l || echo '0'")
    
    if [ "$READY_PODS" -eq "$TOTAL_PODS" ] && [ "$TOTAL_PODS" -gt 0 ]; then
        echo "All pods are ready ($READY_PODS/$TOTAL_PODS)."
        break
    fi
    
    if [ $ATTEMPTS -eq $MAX_ATTEMPTS ]; then
        echo "Warning: Not all pods are ready after $MAX_ATTEMPTS attempts."
        echo "Please check the pod logs for errors."
        ssh $REMOTE_USER@$REMOTE_SERVER_IP "kubectl get pods -l app=app3"
        ssh $REMOTE_USER@$REMOTE_SERVER_IP "kubectl logs -l app=app3 --tail=20"
        break
    fi
    
    echo "Waiting for pods to be ready ($READY_PODS/$TOTAL_PODS)..."
    sleep 5
done

# Verify the deployment
echo "Verifying deployment on remote server..."
ssh $REMOTE_USER@$REMOTE_SERVER_IP "kubectl get pods -l app=app3"
ssh $REMOTE_USER@$REMOTE_SERVER_IP "kubectl get svc app3-service"

# Test the endpoint
echo "Testing the /hello endpoint..."
if command_exists curl; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$REMOTE_SERVER_IP/hello || echo "000")
    if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 400 ]; then
        echo "Success! The /hello endpoint is accessible (HTTP $HTTP_CODE)."
    else
        echo "Warning: The /hello endpoint returned HTTP code $HTTP_CODE."
        echo "You may need to check your Nginx configuration or wait a bit longer."
    fi
else
    echo "Note: curl not found. Skipping endpoint test."
fi

echo "App3 (hello-minikube) has been deployed successfully."
echo "It should be accessible at: http://$REMOTE_SERVER_IP/hello"
echo ""
echo "Deployment completed successfully!"
