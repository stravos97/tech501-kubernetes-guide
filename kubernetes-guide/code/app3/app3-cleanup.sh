#!/bin/bash
# Script to cleanup the hello-minikube application (App3)

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

echo "Cleaning up hello-minikube application (App3)..."

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

echo "Cleaning up on remote server: $REMOTE_USER@$REMOTE_SERVER_IP"

# Delete Kubernetes resources on remote server
echo "Deleting Kubernetes resources on remote server..."
ssh $REMOTE_USER@$REMOTE_SERVER_IP "kubectl delete -f ~/app3/app3-service.yml 2>/dev/null || echo 'Service already deleted or not found'"
ssh $REMOTE_USER@$REMOTE_SERVER_IP "kubectl delete -f ~/app3/app3-deploy.yml 2>/dev/null || echo 'Deployment already deleted or not found'"

# Verify cleanup on remote server
echo "Verifying cleanup on remote server..."
ssh $REMOTE_USER@$REMOTE_SERVER_IP "kubectl get pods -l app=app3 2>/dev/null || echo 'No pods found'"
ssh $REMOTE_USER@$REMOTE_SERVER_IP "kubectl get svc app3-service 2>/dev/null || echo 'No service found'"

# Clean up Nginx configuration on remote server
echo "Cleaning up Nginx configuration on remote server..."
# First, get the current Nginx configuration
ssh $REMOTE_USER@$REMOTE_SERVER_IP "cat /etc/nginx/sites-available/default" > remote_nginx_config.tmp || handle_error "Failed to get Nginx configuration from remote server"

# Check if /hello location exists
if grep -q "location /hello" remote_nginx_config.tmp; then
    # Create a modified configuration without the /hello location
    cat remote_nginx_config.tmp | sed '/location \/hello {/,/}/d' > remote_nginx_config_updated.tmp
    
    # Copy the updated configuration back to the remote server
    scp remote_nginx_config_updated.tmp $REMOTE_USER@$REMOTE_SERVER_IP:/tmp/nginx_config_updated || handle_error "Failed to copy updated Nginx configuration to remote server"
    ssh $REMOTE_USER@$REMOTE_SERVER_IP "sudo cp /tmp/nginx_config_updated /etc/nginx/sites-available/default" || handle_error "Failed to update Nginx configuration on remote server"
    
    # Reload Nginx on remote server
    echo "Reloading Nginx on remote server..."
    ssh $REMOTE_USER@$REMOTE_SERVER_IP "sudo systemctl reload nginx" || handle_error "Failed to reload Nginx on remote server"
    
    echo "Nginx configuration updated - /hello location removed."
else
    echo "Nginx configuration does not contain /hello location. No changes needed."
fi

# Clean up temporary files
rm -f remote_nginx_config.tmp remote_nginx_config_updated.tmp

# Clean up deployment files on remote server
echo "Cleaning up deployment files on remote server..."
ssh $REMOTE_USER@$REMOTE_SERVER_IP "rm -rf ~/app3" || echo "Warning: Failed to remove app3 directory on remote server"

echo "App3 (hello-minikube) has been cleaned up successfully."
echo ""
echo "If you want to stop the minikube tunnel on the remote server, run:"
echo "ssh $REMOTE_USER@$REMOTE_SERVER_IP \"pkill -f 'minikube tunnel'\""
echo "Cleanup completed successfully!"
