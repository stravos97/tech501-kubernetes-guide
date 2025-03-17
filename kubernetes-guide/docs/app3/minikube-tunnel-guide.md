# Minikube Tunnel Guide

## Overview

Minikube tunnel is a command that creates a network route on the host to services deployed with type LoadBalancer. It makes these services accessible from the host machine by assigning them an external IP address.

## Why Use Minikube Tunnel?

### The LoadBalancer Challenge in Local Development

In cloud environments like AWS, GCP, or Azure, when you create a Kubernetes service of type LoadBalancer, the cloud provider automatically provisions a load balancer (like an AWS ELB) and assigns it an external IP address. This makes your service accessible from outside the cluster.

However, in a local Minikube environment, there is no cloud provider to provision actual load balancers. Without minikube tunnel, LoadBalancer services remain in a "pending" state for external IP assignment.

### Benefits of Minikube Tunnel

1. **Cloud-Like Experience**: Simulates the behavior of cloud provider load balancers in a local environment
2. **External IP Assignment**: Assigns an external IP to LoadBalancer services
3. **Direct Access**: Makes services directly accessible from the host machine
4. **Testing**: Allows testing of LoadBalancer configurations locally before deploying to the cloud
5. **Simplified Development**: Enables a more consistent development experience between local and cloud environments

## How Minikube Tunnel Works

1. When you create a LoadBalancer service in Kubernetes, it requests an external IP
2. In Minikube without tunnel, this request remains pending
3. When you run `minikube tunnel`:
   - It creates a network route on the host machine
   - It allocates an IP address to the LoadBalancer service
   - It sets up port forwarding from the host to the service
   - It maintains this connection as long as the tunnel process runs

## Technical Implementation

The minikube tunnel command:

1. Runs with elevated privileges to create network routes
2. Creates a virtual network interface or route
3. Maps the Kubernetes service's cluster IP to an external IP
4. Forwards traffic from the external IP to the appropriate pods
5. Maintains this mapping until the process is terminated

## Usage in Our Infrastructure

In our setup:

1. We use minikube tunnel to enable the LoadBalancer service for our App3 (hello-minikube echoserver)
2. The tunnel assigns an external IP to the app3-service
3. Our Nginx reverse proxy uses this IP to route traffic from `/hello` to the App3 service
4. This allows external access to the app through the Nginx reverse proxy at `http://<VM_IP>/hello`

### Implementation Details

Our deployment script (`code/app3/app3-deploy.sh`) performs the following steps:

1. Deploys the App3 application using `app3-deploy.yml` and `app3-service.yml`
2. Checks if minikube tunnel is running and starts it if needed:
   ```bash
   TUNNEL_RUNNING=$(pgrep -f 'minikube tunnel' || echo '')
   if [ -z "$TUNNEL_RUNNING" ]; then
       nohup minikube tunnel > minikube_tunnel.log 2>&1 &
   fi
   ```
3. Waits for the LoadBalancer to get an external IP
4. Updates the Nginx configuration to add a `/hello` location that proxies to the LoadBalancer IP:
   ```nginx
   location /hello {
       proxy_pass http://<LOADBALANCER_IP>:8080;
       proxy_set_header Host $host;
       proxy_set_header X-Real-IP $remote_addr;
       proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
       proxy_set_header X-Forwarded-Proto $scheme;
   }
   ```

This configuration allows users to access the App3 echoserver at `http://<VM_IP>/hello`.

## Best Practices

1. **Run in Background**: Use `nohup minikube tunnel &` to run the tunnel in the background
2. **Log Output**: Redirect output to a log file for troubleshooting:
   ```bash
   nohup minikube tunnel > minikube_tunnel.log 2>&1 &
   ```
3. **Automatic Restart**: Consider setting up a systemd service to automatically restart the tunnel after system reboots
4. **Cleanup**: Always terminate the tunnel process when it's no longer needed

## Troubleshooting

### Common Issues

1. **Tunnel Not Working**:
   - Ensure minikube is running
   - Check if the tunnel process is running with `ps aux | grep minikube`
   - Restart the tunnel with `minikube tunnel`

2. **Permission Denied**:
   - Run with sudo: `sudo minikube tunnel`
   - Check if the user has the necessary permissions

3. **Service Still Pending**:
   - Wait a few moments for the IP to be assigned
   - Check service status with `kubectl get svc`
   - Restart the tunnel

4. **Connection Refused**:
   - Verify the service is running with `kubectl get pods`
   - Check if the correct ports are exposed
   - Ensure the application inside the pod is functioning correctly

5. **Nginx Not Routing to App3**:
   - Check the Nginx configuration in `/etc/nginx/sites-available/default`
   - Verify that the `/hello` location is properly configured
   - Ensure the LoadBalancer IP is correct in the proxy_pass directive
   - Reload Nginx with `sudo systemctl reload nginx`

## Alternatives to Minikube Tunnel

1. **NodePort Services**: Use NodePort instead of LoadBalancer (accessible via minikube IP and NodePort)
2. **Ingress Controllers**: Set up an Ingress controller for more advanced routing
3. **Port Forwarding**: Use `kubectl port-forward` for temporary access to specific services

## Conclusion

Minikube tunnel is an essential tool for local Kubernetes development when working with LoadBalancer services. It bridges the gap between local development and cloud deployment by simulating cloud provider load balancer functionality. In our infrastructure, it enables the App3 echoserver to be accessible via Nginx at the `/hello` path.
