# Kubernetes Guide: From Fundamentals to Advanced Deployment

## Introduction to Kubernetes

Kubernetes is an open-source container orchestration platform that automates the deployment, scaling, and management of containerized applications. It provides a framework to run distributed systems resiliently, handling failover, scaling, and deployment patterns.

## Table of Contents
- [Kubernetes Guide: From Fundamentals to Advanced Deployment](#kubernetes-guide-from-fundamentals-to-advanced-deployment)
  - [Introduction to Kubernetes](#introduction-to-kubernetes)
  - [Table of Contents](#table-of-contents)
  - [Deploying a Node.js "Sparta" Test App with MongoDB](#deploying-a-nodejs-sparta-test-app-with-mongodb)
  - [Setting Up the Node.js App Deployment](#setting-up-the-nodejs-app-deployment)
    - [Node.js App Deployment YAML](#nodejs-app-deployment-yaml)
    - [Deploying and Verifying the Node App](#deploying-and-verifying-the-node-app)
  - [Exposing the Node.js App via NodePort](#exposing-the-nodejs-app-via-nodeport)
  - [Adding a MongoDB Database Deployment with Persistent Storage](#adding-a-mongodb-database-deployment-with-persistent-storage)
    - [Persistent Volume and Claim](#persistent-volume-and-claim)
    - [MongoDB Deployment YAML](#mongodb-deployment-yaml)
    - [MongoDB Service YAML](#mongodb-service-yaml)
  - [Implementing Horizontal Pod Autoscaler (HPA)](#implementing-horizontal-pod-autoscaler-hpa)
    - [HPA Configuration](#hpa-configuration)
    - [Testing the HPA](#testing-the-hpa)
  - [Testing the Full Application](#testing-the-full-application)
  - [Troubleshooting the Node.js and MongoDB Setup](#troubleshooting-the-nodejs-and-mongodb-setup)
  - [Organizing Your Kubernetes Manifests](#organizing-your-kubernetes-manifests)

## Deploying a Node.js "Sparta" Test App with MongoDB

Now we'll deploy a two-tier application: a Node.js application (the "Sparta" test app) and a MongoDB database it connects to. We'll use Kubernetes to run both components and wire them together. The end goal is to have the Node app reachable via a NodePort and the Node app talking to MongoDB via an internal service.

## Setting Up the Node.js App Deployment

We'll use a Node.js app packaged into a Docker image (`haashim1/haashim-node-website:multi`). The Node app listens on port 3000 inside the container. We also need to provide it with the MongoDB connection info via environment variables.

### Node.js App Deployment YAML

Here's the Deployment YAML for the Node app (sparta-deploy.yml):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sparta-node-deployment
  labels:
    app: sparta-node
spec:
  replicas: 2  # Starting with 2 replicas as per HPA requirements
  selector:
    matchLabels:
      app: sparta-node
  template:
    metadata:
      labels:
        app: sparta-node
    spec:
      containers:
        - name: sparta-app
          image: haashim1/haashim-node-website:multi
          ports:
            - containerPort: 3000
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 200m
              memory: 256Mi
          env:
            - name: DB_HOST
              value: "mongodb://sparta-db-service:27017/posts"
            - name: EXECUTE_NPM_INSTALL
              value: "false"
          readinessProbe:
            httpGet:
              path: /
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 5
```

A few things to note:

- We run 2 replicas of the Node app (this matches the minimum replicas in the HPA configuration).
- The container exposes port 3000.
- We set resource requests and limits to ensure proper scheduling and prevent resource starvation.
- We set environment variables:
  - `DB_HOST` with the MongoDB connection string
  - `EXECUTE_NPM_INSTALL` set to "false" to skip npm install on startup
- We include a readiness probe to ensure the app is ready to receive traffic.

### Deploying and Verifying the Node App

Apply this deployment with:

```bash
kubectl apply -f code/sparta/sparta-deploy.yml
```

After a few moments check the pod status:

```bash
kubectl get pods -l app=sparta-node
```

The pods should be Running. If not, troubleshoot using the guidance in the troubleshooting section below.

## Exposing the Node.js App via NodePort

We create a service to expose the Node.js application:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: sparta-node-service
spec:
  type: NodePort
  selector:
    app: sparta-node
  ports:
    - port: 3000
      targetPort: 3000
      nodePort: 30003
      protocol: TCP
```

This will route external port 30003 to the Node app pods (port 3000 in the container). Apply this:

```bash
kubectl apply -f code/sparta/sparta-service.yml
```

Check the service:

```bash
kubectl get svc sparta-node-service
```

Confirm it's assigned the nodePort 30003 as specified.

## Adding a MongoDB Database Deployment with Persistent Storage

For MongoDB, we'll use the official `mongo:latest` image. We'll set up a persistent volume for data storage and a service for the Node app to connect to MongoDB.

### Persistent Volume and Claim

First, let's set up the persistent volume and claim for MongoDB:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: sparta-db-pv
spec:
  capacity:
    storage: 100Mi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/data/mongodb"
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: sparta-db-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
  volumeName: sparta-db-pv
  storageClassName: ""
```

This creates:
- A PersistentVolume with 100Mi capacity using a hostPath at "/data/mongodb"
- A PersistentVolumeClaim that requests 100Mi storage and explicitly binds to our PV
- Both use ReadWriteOnce access mode, which means the volume can be mounted as read-write by a single node

Apply the PV and PVC:

```bash
kubectl apply -f code/sparta/sparta-pv.yml
```

Check the status:

```bash
kubectl get pv sparta-db-pv
kubectl get pvc sparta-db-pvc
```

Both should show as "Bound".

### MongoDB Deployment YAML

Now let's set up the MongoDB deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sparta-db-deployment
  labels:
    app: sparta-db
spec:
  replicas: 1  # Using 1 replica since we're using ReadWriteOnce PV
  selector:
    matchLabels:
      app: sparta-db
  template:
    metadata:
      labels:
        app: sparta-db
    spec:
      containers:
        - name: sparta-db
          image: mongo:latest
          ports:
            - containerPort: 27017
          volumeMounts:
            - name: mongodb-data
              mountPath: /data/db
      volumes:
        - name: mongodb-data
          persistentVolumeClaim:
            claimName: sparta-db-pvc
```

Key points about this configuration:

- We set `replicas: 1` because our PV has ReadWriteOnce access mode which only allows mounting by one node at a time.
- We mount the PVC at `/data/db` (that's where MongoDB stores its database files inside the container by default).
- We use the `mongo:latest` image.

This deployment is included in the same file as the Node.js deployment (sparta-deploy.yml).

### MongoDB Service YAML

We also need a service for MongoDB:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: sparta-db-service
spec:
  selector:
    app: sparta-db
  ports:
    - port: 27017
      targetPort: 27017
      protocol: TCP
```

This creates a ClusterIP service (the default type) that's only accessible within the cluster. The service name "sparta-db-service" is what we used in the Node app's `DB_HOST` environment variable.

This service is included in the same file as the Node.js service (sparta-service.yml).

## Implementing Horizontal Pod Autoscaler (HPA)

To automatically scale our Node.js application based on CPU usage, we'll implement a Horizontal Pod Autoscaler (HPA).

### HPA Configuration

Here's the HPA configuration:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: sparta-node-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: sparta-node-deployment
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
```

This HPA will:
- Target our Node.js deployment
- Maintain between 2 and 10 replicas
- Scale based on CPU utilization, targeting 50% of the requested CPU
- Use the autoscaling/v2 API which supports multiple metrics

Apply this:

```bash
kubectl apply -f code/sparta/sparta-hpa.yml
```

Check the HPA status:

```bash
kubectl get hpa sparta-node-hpa
```

### Testing the HPA

To see the HPA scale up, we need to generate load on the application:

1. **Run a load test**

   You can use a tool like `hey` or a simple bash loop:

   ```bash
   # Send a bunch of parallel requests
   for i in {1..1000}; do curl -s http://localhost:30003/ > /dev/null & done
   ```

2. **Monitor the HPA**

   ```bash
   # Watch the HPA status
   kubectl get hpa sparta-node-hpa -w
   ```

   It will show current replicas, target, and current usage percentage.

   Also watch the pods:

   ```bash
   # Watch the pods being created
   kubectl get pods -l app=sparta-node -w
   ```

After the load stops, the HPA will eventually scale back down to the minimum of 2 replicas.

## Testing the Full Application

You have:

- Node app service on NodePort 30003
- MongoDB running internally with persistent storage

Open a browser or use curl:

```bash
curl http://localhost:30003/
```

You should get a response from the Node app. Try to exercise its functionality to confirm the DB connection works.

## Troubleshooting the Node.js and MongoDB Setup

If you encounter issues:

1. **Node app not reachable on 30003**:
   Check `kubectl get svc sparta-node-service` to confirm the NodePort. On Docker Desktop, localhost:30003 should forward to it.

2. **Application errors**:
   If you get an error from the Node app, check the Node pod logs:
   ```bash
   kubectl logs -l app=sparta-node
   ```

3. **MongoDB connection issues**:
   If Node logs show it cannot connect to MongoDB, check that the service is working:
   ```bash
   kubectl get svc sparta-db-service
   kubectl get pods -l app=sparta-db
   ```
   
   You can also exec into a Node pod to test connectivity:
   ```bash
   kubectl exec -it $(kubectl get pod -l app=sparta-node -o jsonpath='{.items[0].metadata.name}') -- curl -s sparta-db-service:27017
   ```

4. **MongoDB pod crashing**:
   If the MongoDB pod is restarting, check its logs:
   ```bash
   kubectl logs -l app=sparta-db
   ```
   
   Also check if the PV and PVC are properly bound:
   ```bash
   kubectl get pv,pvc
   ```

5. **HPA not scaling**:
   Ensure the metrics server is running:
   ```bash
   kubectl get deployment metrics-server -n kube-system
   ```
   
   If it's not running, you may need to install it:
   ```bash
   kubectl apply -f code/infrastructure/metrics-server/metrics-server-fixed.yaml
   ```

## Organizing Your Kubernetes Manifests

It's a good practice to organize your manifests in a structured way. The repository is already organized with a clear structure:

```
code/
  app1/
  app2/
  app3/
  nginx/
  sparta/
  sparta-with-pv/
  config/
  scripts/
  infrastructure/
  deployments/
  logs/
docs/
  app3/
  diagrams/
  implementation/
  day1-fundamentals/
  day2/
  day3/
```

All scripts should be run from the root directory of the repository. For example:

```bash
# Deploy all applications
./code/scripts/deploy-all-apps.sh

# Deploy Sparta application
./code/scripts/deploy-sparta.sh

# Connect to Sparta application
./code/scripts/sparta-connect.sh
```
