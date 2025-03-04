
To deploy this NGINX configuration using kubectl, you'll need to use the `apply` command. Here's the command:

```bash
kubectl apply -f nginx-deploy.yml
```

This command will:

- `kubectl`: The command-line tool for Kubernetes
- `apply`: Creates or updates resources in a cluster
- `-f`: Specifies that we're using a file
- [nginx-deploy.yml](vscode-file://vscode-app/Applications/Visual%20Studio%20Code.app/Contents/Resources/app/out/vs/code/electron-sandbox/workbench/workbench.html): The name of your deployment configuration file

After running this command, you can verify the deployment with:

```bash
kubectl get deployments
kubectl get pods
```

To check the status and details of your deployment:

```bash
kubectl describe deployment nginx-deployment
```

If you need to delete this deployment later:

```bash
kubectl delete -f nginx-deploy.yml
```

To manage replicas, you have several options:

1. **Scale deployment using command line**:
```bash
		kubectl scale deployment nginx-deployment --replicas=0
```

 1. **Edit the deployment directly**:
```bash
	    kubectl edit deployment nginx-deployment
```

To find the IP address and port of your NGINX deployment, you'll need to run a few commands:
```bash
		kubectl get services
```

1. **Get detailed information about pods**:
```bash
	   kubectl get pods -o wide
```
1.  **To get specific pod's IP address**:
```bash
   kubectl describe pod <pod-name>
```

Based on your terminal output, I notice that you haven't created a Service yet to expose your NGINX deployment. The pods are only accessible within the cluster (internal IPs: 10.1.0.6, 10.1.0.7, 10.1.0.8).

To make your NGINX deployment accessible via browser, you need to:

1. First, create a Service. Create a file named `nginx-service.yml`:
```bash
   apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
    - port: 80
      targetPort: 80
```

1. Apply the service:
```bash
   kubectl apply -f nginx-service.yml
```
1. Get the service URL (if using Docker Desktop):
```bash
   kubectl get service nginx-service
```
Once you run these commands, you can access the application through:

- If using Docker Desktop: `localhost:<NodePort>`
- The NodePort will be automatically assigned (typically in range 30000-32767)

To get the exact port, run:
```bash
kubectl get service nginx-service --output='jsonpath="{.spec.ports[0].nodePort}"'
```

Then you can access your application at: `http://localhost:<nodePort>`

