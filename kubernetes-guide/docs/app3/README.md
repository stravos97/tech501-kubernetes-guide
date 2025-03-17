# Hello-Minikube Deployment Documentation

This documentation covers the deployment of the hello-minikube application as the third app in our Kubernetes setup.

## Deployment Overview

The hello-minikube application is deployed with:
- A Kubernetes Deployment with 2 replicas
- A LoadBalancer service exposing port 8080
- Nginx reverse proxy configuration to expose the app at `/hello` path

## Remote Server Deployment

The deployment is designed to work with a remote server where minikube is installed. The server details are configured in the `config.env` file in the root directory:

```
# Sparta App Configuration
REMOTE_SERVER_IP="108.129.186.136"
REMOTE_USER="ubuntu"
```

## Automated Deployment

We've created fully automated scripts for deploying, cleaning up, and recovering the hello-minikube application on the remote server:

### Deployment Script (`deploy-app3.sh`)

This script automates the entire deployment process:
- Copies deployment files to the remote server
- Applies Kubernetes configurations on the remote server
- Ensures minikube tunnel is running on the remote server
- Waits for LoadBalancer IP assignment
- Automatically updates Nginx configuration on the remote server
- Verifies pod readiness
- Tests the endpoint accessibility

Usage:
```bash
./app3/deploy-app3.sh
```

### Cleanup Script (`cleanup-app3.sh`)

This script automates the cleanup process:
- Removes Kubernetes resources on the remote server
- Automatically updates Nginx configuration to remove the `/hello` location
- Verifies the cleanup was successful
- Cleans up deployment files on the remote server

Usage:
```bash
./app3/cleanup-app3.sh
```

### Recovery Script (`recover-kubernetes.sh`)

This script automates the recovery process after a cloud instance restart:
- Starts minikube if not running on the remote server
- Starts minikube tunnel on the remote server
- Copies and reapplies all application configurations to the remote server
- Updates Nginx configuration on the remote server
- Verifies pod readiness
- Tests all endpoints

Usage:
```bash
./app3/recover-kubernetes.sh
```

## Understanding Minikube Tunnel

### What is Minikube Tunnel?
Minikube tunnel creates a network route on the host to services of type LoadBalancer. It simulates cloud provider load balancers in a local environment.

### Why Use Minikube Tunnel?
1. **Cloud Emulation**: In cloud environments, Kubernetes can provision actual load balancers. Minikube, running locally, doesn't have this capability by default.
2. **External IP Assignment**: Without the tunnel, LoadBalancer services would remain in a perpetual "pending" state for external IP assignment.
3. **Direct Service Access**: The tunnel enables direct access to LoadBalancer services using their assigned cluster IPs.

### How Minikube Tunnel Works
1. When a LoadBalancer service is created, Kubernetes attempts to provision an external load balancer
2. In minikube, this would normally remain in "pending" state
3. The minikube tunnel command creates a network route that:
   - Allocates a pseudo-external IP to the service
   - Routes traffic from the host to the service
   - Makes the service directly accessible from outside the cluster

For more detailed information about minikube tunnel, see the [minikube-tunnel-guide.md](minikube-tunnel-guide.md) file.

## Manual Cleanup Instructions

If you need to manually clean up the deployment:

### Cleanup for App3 (Hello-Minikube)
```bash
# Delete the Kubernetes resources
kubectl delete -f app3/app3-service.yml
kubectl delete -f app3/app3-deploy.yml

# Update the Nginx configuration to remove the /hello location block
# Edit the nginx config file and reload:
sudo nginx -s reload
```

### Complete Cluster Cleanup
```bash
# Stop minikube tunnel
pkill -f 'minikube tunnel'

# Delete all resources in the cluster
kubectl delete deployments --all
kubectl delete services --all
kubectl delete pods --all
kubectl delete pvc --all
kubectl delete pv --all

# Optional: Stop the minikube cluster
minikube stop
```

## Manual Recovery After Cloud Instance Restart

If you need to manually recover after a cloud instance restart:

### 1. Start Minikube
```bash
# Check if minikube is already running
minikube status

# If not running, start it
minikube start
```

### 2. Enable Minikube Tunnel
```bash
# Start the minikube tunnel in the background
nohup minikube tunnel > minikube_tunnel.log 2>&1 &

# Verify the tunnel is running
ps aux | grep minikube
```

### 3. Reapply Kubernetes Configurations
```bash
# Apply all application configurations
kubectl apply -f app1/app1-deploy.yml
kubectl apply -f app1/app1-service.yml
kubectl apply -f app2/app2-deploy.yml
kubectl apply -f app2/app2-service.yml
kubectl apply -f app3/app3-deploy.yml
kubectl apply -f app3/app3-service.yml

# Verify all pods are running
kubectl get pods
kubectl get services
```

### 4. Restart Nginx Service
```bash
# Ensure Nginx is running
sudo systemctl status nginx

# If not running, start it
sudo systemctl start nginx

# If running, reload configuration
sudo systemctl reload nginx
```

### 5. Verify Applications
```bash
# Test each application endpoint
curl http://localhost/
curl http://localhost:9000/
curl http://localhost/hello
```

## Automating Recovery with Systemd

For automatic recovery after instance restart, we've set up:
1. A systemd service for Minikube (minikube.service)
2. This service starts Minikube automatically when the system boots

You can create additional systemd services to:
- Start the minikube tunnel automatically
- Run the recovery script on boot

Example systemd service for minikube tunnel:
```
[Unit]
Description=Minikube Tunnel Service
After=minikube.service
Requires=minikube.service

[Service]
Type=simple
User=ubuntu
ExecStart=/usr/local/bin/minikube tunnel
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

## Troubleshooting

If you encounter issues with the deployment:

1. **Pods in Error State**:
   - Check pod logs: `kubectl logs -l app=app3`
   - Verify image availability: `kubectl describe pod -l app=app3`
   - Try using a different image in the deployment YAML

2. **LoadBalancer IP Not Assigned**:
   - Verify minikube tunnel is running: `ps aux | grep minikube`
   - Restart the tunnel: `pkill -f 'minikube tunnel' && nohup minikube tunnel > minikube_tunnel.log 2>&1 &`
   - Check service status: `kubectl get svc app3-service`

3. **Nginx Configuration Issues**:
   - Verify Nginx configuration: `nginx -t`
   - Check Nginx logs: `sudo journalctl -u nginx`
   - Manually update the configuration if needed

4. **Endpoint Not Accessible**:
   - Check if pods are running: `kubectl get pods -l app=app3`
   - Verify service is properly configured: `kubectl describe svc app3-service`
   - Test direct access to the service: `curl http://localhost:8080`
