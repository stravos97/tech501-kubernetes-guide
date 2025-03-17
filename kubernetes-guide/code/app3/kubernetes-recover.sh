#!/bin/bash
# Script to recover Kubernetes after cloud instance restart

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

echo "Recovering Kubernetes environment after instance restart..."

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

echo "Recovering on remote server: $REMOTE_USER@$REMOTE_SERVER_IP"

# 1. Start Minikube if not running on remote server
echo "Checking if minikube is running on remote server..."
MINIKUBE_RUNNING=$(ssh $REMOTE_USER@$REMOTE_SERVER_IP "minikube status 2>/dev/null | grep -c 'host: Running' || echo '0'")
if [ "$MINIKUBE_RUNNING" -eq 0 ]; then
    echo "Starting minikube on remote server..."
    ssh $REMOTE_USER@$REMOTE_SERVER_IP "minikube start" || handle_error "Failed to start minikube on remote server."
    echo "Waiting for minikube to initialize..."
    sleep 10
else
    echo "Minikube is already running on remote server."
fi

# 2. Enable Minikube Tunnel on remote server
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

# 3. Copy and reapply Kubernetes Configurations on remote server
echo "Copying and reapplying Kubernetes configurations on remote server..."

# Create directories on remote server
ssh $REMOTE_USER@$REMOTE_SERVER_IP "mkdir -p ~/app1 ~/app2 ~/app3"

# Check if app1 exists and apply
if [ -f "code/app1/app1-deploy.yml" ] && [ -f "code/app1/app1-service.yml" ]; then
    echo "Copying and applying App1 configurations..."
    scp code/app1/app1-deploy.yml code/app1/app1-service.yml $REMOTE_USER@$REMOTE_SERVER_IP:~/app1/
    ssh $REMOTE_USER@$REMOTE_SERVER_IP "kubectl apply -f ~/app1/app1-deploy.yml" || echo "Warning: Failed to apply app1-deploy.yml"
    ssh $REMOTE_USER@$REMOTE_SERVER_IP "kubectl apply -f ~/app1/app1-service.yml" || echo "Warning: Failed to apply app1-service.yml"
else
    echo "App1 configuration files not found. Skipping."
fi

# Check if app2 exists and apply
if [ -f "code/app2/app2-deploy.yml" ] && [ -f "code/app2/app2-service.yml" ]; then
    echo "Copying and applying App2 configurations..."
    scp code/app2/app2-deploy.yml code/app2/app2-service.yml $REMOTE_USER@$REMOTE_SERVER_IP:~/app2/
    ssh $REMOTE_USER@$REMOTE_SERVER_IP "kubectl apply -f ~/app2/app2-deploy.yml" || echo "Warning: Failed to apply app2-deploy.yml"
    ssh $REMOTE_USER@$REMOTE_SERVER_IP "kubectl apply -f ~/app2/app2-service.yml" || echo "Warning: Failed to apply app2-service.yml"
else
    echo "App2 configuration files not found. Skipping."
fi

# Check if app3 exists and apply
if [ -f "code/app3/app3-deploy.yml" ] && [ -f "code/app3/app3-service.yml" ]; then
    echo "Copying and applying App3 configurations..."
    scp code/app3/app3-deploy.yml code/app3/app3-service.yml $REMOTE_USER@$REMOTE_SERVER_IP:~/app3/
    ssh $REMOTE_USER@$REMOTE_SERVER_IP "kubectl apply -f ~/app3/app3-deploy.yml" || echo "Warning: Failed to apply app3-deploy.yml"
    ssh $REMOTE_USER@$REMOTE_SERVER_IP "kubectl apply -f ~/app3/app3-service.yml" || echo "Warning: Failed to apply app3-service.yml"
    
    # Wait for LoadBalancer to get an external IP for App3
    echo "Waiting for App3 LoadBalancer to get an external IP on remote server..."
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
    
    # Update Nginx configuration for App3 on remote server
    echo "Updating Nginx configuration for App3 on remote server..."
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
        
        echo "Nginx configuration updated with /hello location."
    else
        echo "Nginx configuration already contains /hello location."
    fi
    
    # Clean up temporary files
    rm -f remote_nginx_config.tmp remote_nginx_config_updated.tmp
else
    echo "App3 configuration files not found. Skipping."
fi

# 4. Wait for pods to be ready on remote server
echo "Waiting for pods to be ready on remote server..."
ATTEMPTS=0
MAX_ATTEMPTS=20
while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    ATTEMPTS=$((ATTEMPTS+1))
    echo "Attempt $ATTEMPTS of $MAX_ATTEMPTS..."
    
    # Get the number of pods that are not in Running state
    NOT_RUNNING=$(ssh $REMOTE_USER@$REMOTE_SERVER_IP "kubectl get pods --all-namespaces --no-headers 2>/dev/null | grep -v 'Running' | grep -v 'Completed' | wc -l || echo '0'")
    
    if [ "$NOT_RUNNING" -eq 0 ]; then
        echo "All pods are running on remote server."
        break
    fi
    
    if [ $ATTEMPTS -eq $MAX_ATTEMPTS ]; then
        echo "Warning: Not all pods are running after $MAX_ATTEMPTS attempts."
        echo "Please check the pod logs for errors."
        ssh $REMOTE_USER@$REMOTE_SERVER_IP "kubectl get pods --all-namespaces"
        break
    fi
    
    echo "Waiting for pods to be ready ($NOT_RUNNING pods not running)..."
    sleep 5
done

# 5. Verify all pods are running on remote server
echo "Verifying all pods and services on remote server..."
ssh $REMOTE_USER@$REMOTE_SERVER_IP "kubectl get pods"
ssh $REMOTE_USER@$REMOTE_SERVER_IP "kubectl get services"

# 6. Restart Nginx Service on remote server if needed
echo "Checking Nginx service on remote server..."
NGINX_ACTIVE=$(ssh $REMOTE_USER@$REMOTE_SERVER_IP "systemctl is-active nginx 2>/dev/null || echo 'inactive'")
if [ "$NGINX_ACTIVE" = "active" ]; then
    echo "Reloading Nginx configuration on remote server..."
    ssh $REMOTE_USER@$REMOTE_SERVER_IP "sudo systemctl reload nginx" || echo "Warning: Failed to reload Nginx. Please reload manually."
else
    echo "Starting Nginx service on remote server..."
    ssh $REMOTE_USER@$REMOTE_SERVER_IP "sudo systemctl start nginx" || echo "Warning: Failed to start Nginx. Please start manually."
fi

# 7. Test the endpoints
echo "Testing the endpoints..."
if command_exists curl; then
    echo "Testing root endpoint..."
    curl -s -o /dev/null -w "Root endpoint: HTTP %{http_code}\n" http://$REMOTE_SERVER_IP/ || echo "Failed to connect to root endpoint"
    
    echo "Testing app2 endpoint..."
    curl -s -o /dev/null -w "App2 endpoint: HTTP %{http_code}\n" http://$REMOTE_SERVER_IP:9000/ || echo "Failed to connect to app2 endpoint"
    
    echo "Testing app3 endpoint..."
    curl -s -o /dev/null -w "App3 endpoint: HTTP %{http_code}\n" http://$REMOTE_SERVER_IP/hello || echo "Failed to connect to app3 endpoint"
else
    echo "Note: curl not found. Skipping endpoint tests."
fi

echo "Kubernetes environment recovery completed on remote server."
echo "You should now be able to access your applications."
echo ""
echo "Verify with:"
echo "  curl http://$REMOTE_SERVER_IP/"
echo "  curl http://$REMOTE_SERVER_IP:9000/"
echo "  curl http://$REMOTE_SERVER_IP/hello"
echo ""
echo "Recovery completed successfully!"
