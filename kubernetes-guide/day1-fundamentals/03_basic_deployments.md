# Basic Deployments

## Table of Contents
- [Basic Deployments](#basic-deployments)
  - [Table of Contents](#table-of-contents)
  - [Nginx Deployment with a NodePort Service](#nginx-deployment-with-a-nodeport-service)
    - [Deployment YAML (nginx-deployment.yaml)](#deployment-yaml-nginx-deploymentyaml)
    - [Service YAML (nginx-service.yaml)](#service-yaml-nginx-serviceyaml)
    - [Applying and Testing the Deployment](#applying-and-testing-the-deployment)
    - [Troubleshooting Nginx Accessibility](#troubleshooting-nginx-accessibility)
    - [Testing Kubernetes Self-Healing](#testing-kubernetes-self-healing)

## Nginx Deployment with a NodePort Service

Let's deploy a simple Nginx web server in our cluster and expose it to our host machine using a NodePort service. A NodePort service opens a specific port on the node (in this case, our Docker Desktop VM) to allow external access to the service.

We'll create two Kubernetes YAML manifest files: one for the Deployment and one for the Service (or combine them in one file separated by `---`). Below are the manifests.

### Deployment YAML (nginx-deployment.yaml)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3  # run 3 Nginx pods for high availability
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: daraymonsta/nginx-257:dreamteam
        ports:
        - containerPort: 80
```

Let's break down this deployment:

- We set `replicas: 3` to run three copies of the Nginx pod. This ensures if one pod goes down, we still have others serving, and it demonstrates load-balancing.
- The `selector` and `template.metadata.labels` ensure the Deployment manages pods labeled `app: nginx`.
- The container uses the image `daraymonsta/nginx-257:dreamteam` (as specified in the task). This is presumably a custom image (perhaps a modified Nginx with specific content or configuration). If that image is not accessible or you prefer, you could use a standard `nginx:latest` image – but we'll follow the given one.
- We expose container port 80 (the Nginx default HTTP port). This is the port Nginx listens on inside the container.

### Service YAML (nginx-service.yaml)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
    - port: 80        # Service port (cluster internal)
      targetPort: 80  # Container port to route to
      nodePort: 30001 # NodePort on the node VM
```

Here, we define a Service named "nginx-service". Key points:

- `spec.type: NodePort` means this service will allocate a port on the node (in the 30000-32767 range). We explicitly choose 30001 for clarity. If we left it blank, Kubernetes would auto-assign a random port in that range.
- The `selector` matches the pods with label `app: nginx` (so it will route traffic to the 3 Nginx pods we deployed).
- Under `ports`, `port: 80` is the service's cluster-internal port, and `targetPort: 80` is where the service forwards traffic on the pods (the containerPort we exposed). Often the service port and container targetPort are the same for simplicity, as we do here (both 80).
- `nodePort: 30001` opens port 30001 on the Docker Desktop VM. This means any traffic hitting port 30001 on your host (Docker VM) will be forwarded to the service, which in turn balances it to the Nginx pods.

### Applying and Testing the Deployment

Apply the deployment and service with:

```bash
kubectl apply -f nginx-deployment.yaml
kubectl apply -f nginx-service.yaml
```

Kubernetes will pull the image and create 3 pods. You can check the pods status with:

```bash
kubectl get pods -l app=nginx
```

This uses a label selector to list only pods with `app=nginx`. You should see 3 pods, and after pulling the image, their status should be Running.

Now verify the service:

```bash
kubectl get service nginx-service
```

It should show something like:

```
NAME            TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
nginx-service   NodePort   10.104.205.12   <none>        80:30001/TCP   1m
```

This indicates the service has cluster IP 10.104.205.12 (random internal IP) and that it's exposing 80 via node port 30001.

Now, you can test access. Because this is Docker Desktop, the "node" is essentially your local machine. On Mac/Windows with Docker Desktop, you can access the NodePort via localhost:30001.

Open a web browser and go to http://localhost:30001/. You should see the Nginx welcome page or the content served by that `daraymonsta/nginx-257:dreamteam` image.

### Troubleshooting Nginx Accessibility

If you can't access localhost:30001, try these troubleshooting steps:

1. **Check if pods are running**: 
   ```bash
   kubectl get pods
   ```
   If the pods are CrashLooping, fix that issue first (maybe the image entrypoint fails).

2. **Ensure the service is correctly configured**:
   ```bash
   kubectl describe svc nginx-service
   ```
   This should show that endpoints are assigned (it will list the pod IPs under Endpoints). If Endpoints is empty, the label selector might not match. Ensure your pods have the label `app: nginx` (check with `kubectl get pods --show-labels`).

3. **Verify connectivity**:
   - On Docker Desktop, the NodePort is accessible via localhost
   - Try `curl localhost:30001` to test connectivity
   - If that doesn't work on Windows, you might need to enable the port in Windows firewall

4. **Check Kubernetes context**:
   ```bash
   kubectl cluster-info
   ```
   Verify that Docker Desktop Kubernetes is running and not using another context.

5. **Inspect image configuration**:
   If you see a response but it's not the expected content, perhaps the custom image serves on a different port or path. Double-check if `daraymonsta/nginx-257:dreamteam` is indeed listening on port 80.

### Testing Kubernetes Self-Healing

At this point, you have a robust Nginx deployment. You can test Kubernetes' self-healing by killing a pod:

```bash
kubectl delete pod -l app=nginx --force
```

The Deployment's ReplicaSet will immediately create a new pod to maintain 3 replicas. If you refresh the browser during this, you might not even notice, because the service load-balances across pods and one pod's termination simply shifts traffic to others. This zero-downtime behavior is a big benefit of using Deployments with multiple replicas.

Tip: You can also scale this deployment easily (without downtime). We'll explore scaling more in the next section.
