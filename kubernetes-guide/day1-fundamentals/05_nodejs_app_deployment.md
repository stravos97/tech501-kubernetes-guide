# Multi-tier Application Deployment

## Table of Contents
- [Multi-tier Application Deployment](#multi-tier-application-deployment)
  - [Table of Contents](#table-of-contents)
  - [Deploying a Node.js "Sparta" Test App with MongoDB](#deploying-a-nodejs-sparta-test-app-with-mongodb)
  - [Setting Up the Node.js App Deployment](#setting-up-the-nodejs-app-deployment)
    - [Node.js App Deployment YAML](#nodejs-app-deployment-yaml)
    - [Deploying and Verifying the Node App](#deploying-and-verifying-the-node-app)
  - [Exposing the Node.js App via NodePort](#exposing-the-nodejs-app-via-nodeport)
  - [Adding a MongoDB Database Deployment](#adding-a-mongodb-database-deployment)
    - [MongoDB Deployment YAML](#mongodb-deployment-yaml)
    - [MongoDB Service YAML](#mongodb-service-yaml)
  - [Testing the Full Application](#testing-the-full-application)
  - [Troubleshooting the Node.js and MongoDB Setup](#troubleshooting-the-nodejs-and-mongodb-setup)
  - [Organizing Your Kubernetes Manifests](#organizing-your-kubernetes-manifests)

## Deploying a Node.js "Sparta" Test App with MongoDB

Now we'll deploy a two-tier application: a Node.js application (the "Sparta" test app) and a MongoDB database it connects to. We'll use Kubernetes to run both components and wire them together. The end goal is to have the Node app reachable via a NodePort and the Node app talking to MongoDB via an internal service.

## Setting Up the Node.js App Deployment

Assuming we have a Node.js app packaged into a Docker image (perhaps the test app's image is available or you built it as myrepo/sparta-app:v1), we create a deployment for it. Let's say the Node app listens on port 3000 inside the container (common for Node apps). We also need to provide it with the MongoDB connection info via environment variables.

### Node.js App Deployment YAML

Here's an example Deployment YAML for the Node app (sparta-node-deployment.yaml):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sparta-node-deployment
spec:
  replicas: 3
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
        image: myrepo/sparta-app:v1   # replace with the actual image name
        ports:
        - containerPort: 3000
        env:
        - name: MONGO_URL
          value: "mongodb://mongo-service:27017/sparta"
```

A few things to note:

- We run 3 replicas of the Node app for high availability.
- The container exposes port 3000. (Adjust this if your app uses a different port.)
- We set an environment variable `MONGO_URL` (this name might differ based on how the app expects configuration; adapt to your app). In this example, the app will use the connection string `mongodb://mongo-service:27017/sparta`. Here, `mongo-service` will be the hostname of our MongoDB service within the cluster, port 27017 is the default MongoDB port, and "sparta" could be the database name. Alternatively, we might pass separate env vars like DB_HOST, DB_NAME, etc., depending on app design.

### Deploying and Verifying the Node App

Apply this deployment with:

```bash
kubectl apply -f sparta-node-deployment.yaml
```

After a few moments, check the pod status:

```bash
kubectl get pods -l app=sparta-node
```

The pods should be Running. If not, troubleshoot:

- If `ImagePullBackOff`, ensure the image name is correct and accessible (push it to Docker Hub or a registry Docker Desktop can access).
- If `CrashLoopBackOff`, use `kubectl logs <pod>` to see the Node app's output. Perhaps it's failing to connect to Mongo (which we haven't set up yet!). It might continuously retry connection – which is okay for now until we add Mongo.

We won't be able to fully test the Node app until the database is up, but we can expose the Node app service in parallel.

## Exposing the Node.js App via NodePort

We create a service similar to the Nginx example:

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
    nodePort: 30002
```

This will route external port 30002 to the Node app pods (port 3000 in the container). Apply this:

```bash
kubectl apply -f sparta-node-service.yaml
```

Check the service:

```bash
kubectl get svc sparta-node-service
```

Confirm it's assigned the nodePort 30002 as specified.

Now you have the Node app set up on the Kubernetes side, but it will error until MongoDB is running. Let's deploy MongoDB.

## Adding a MongoDB Database Deployment

For MongoDB, we can use the official image `mongo:4.4` (or latest). We'll start with a simple deployment of a single Mongo pod (for a toy app, one DB instance is fine; in real scenarios, you'd consider a StatefulSet for replicas). We will also set up a service for MongoDB so the Node app can find it by name.

### MongoDB Deployment YAML

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongo-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongo
  template:
    metadata:
      labels:
        app: mongo
    spec:
      containers:
      - name: mongodb
        image: mongo:4.4
        ports:
        - containerPort: 27017
        env:
        - name: MONGO_INITDB_DATABASE
          value: "sparta"
```

This will run a MongoDB container. We set `MONGO_INITDB_DATABASE` to "sparta" just as an example to automatically create a database on first run (the Sparta app might expect a certain DB to exist; this env var causes Mongo to create an initial DB by that name).

We're not setting any root password or user here for simplicity (Mongo by default in dev mode will allow connections without auth inside the container). For a production-grade setup, you'd set `MONGO_INITDB_ROOT_USERNAME` and `MONGO_INITDB_ROOT_PASSWORD` env vars to enable authentication, and then your app would use credentials. But to keep things simple, we'll run it open (only accessible inside cluster anyway).

### MongoDB Service YAML

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mongo-service
spec:
  selector:
    app: mongo
  ports:
  - port: 27017
    targetPort: 27017
    # ClusterIP service (default type) - no external exposure
```

We don't need to specify a type; by default it will be ClusterIP, which means it's only accessible within the cluster (which is what we want for a database). The service name "mongo-service" is what we used in the Node app's `MONGO_URL`. Kubernetes DNS will resolve `mongo-service` to this service's cluster IP, and pods can connect on port 27017 to reach the MongoDB.

Apply these:

```bash
kubectl apply -f mongo-deployment.yaml
kubectl apply -f mongo-service.yaml
```

Check that the Mongo pod comes up:

```bash
kubectl get pods -l app=mongo
```

If it's Running, good. If it's CrashLooping, check logs (`kubectl logs <mongo-pod-name>`) – sometimes Mongo might crash if persistent storage is not stable (we will address storage on Day 2). But usually, it should run in memory with ephemeral storage for now.

At this point, the Node app pods should automatically be able to connect to Mongo (assuming the app is configured to use the `MONGO_URL` or similar environment we provided). The Node app likely tries to connect on startup. Now that Mongo is live, those connection attempts should succeed.

Check the Node app pod logs again:

```bash
kubectl logs <sparta-pod>
```

You might see messages like "Connected to MongoDB" or the app listening on port, etc., which indicates things are working. If the app still crashes, it might be because it started before Mongo was up and didn't retry. In that case, you might want to add a simple retry logic or liveness probe (beyond scope here). But let's assume it recovers or was still running and now has connected.

## Testing the Full Application

You have:

- Node app service on NodePort 30002
- Nginx still on 30001 (if you kept it) – that was separate, not needed for the Node/Mongo app, unless the Node app is actually served via Nginx (not in this case, presumably).
- Mongo is internal only.

Open a browser or use curl:

```bash
curl http://localhost:30002/
```

(or whatever endpoint the Sparta app provides, e.g., maybe `/` or `/status` or some test path). If all is well, you should get a response from the Node app. This Node app likely interacts with Mongo – for example, it might have a route that writes to the DB or reads from it. Try to exercise its functionality to confirm the DB connection works (some test endpoints might be described in the Sparta app documentation).

## Troubleshooting the Node.js and MongoDB Setup

If you encounter issues:

1. **Node app not reachable on 30002**:
   Check `kubectl get svc sparta-node-service` to confirm the NodePort. On Docker Desktop, localhost:30002 should forward to it.

2. **Application errors**:
   If you get an error from the Node app (like it returns an application error), check the Node pod logs for stack traces. It could be unable to query the database or some internal error.

3. **MongoDB connection issues**:
   If Node logs show it cannot connect to Mongo (e.g., connection refused), check that within the Node container, DNS is resolving correctly. You can exec into a Node pod:
   ```bash
   kubectl exec -it <node-pod> -- ping -c3 mongo-service
   ```
   to see if it can reach the Mongo service. If ping works (DNS resolved, though note that some images might not have ping installed; alternatively use `nslookup mongo-service`), then DNS is fine. In that case, maybe Mongo isn't ready. Ensure the Mongo pod is running and not restarting.

4. **MongoDB pod crashing**:
   If the Mongo pod is CrashLooping, as mentioned, it might be due to no persistent storage on restart. On initial deploy, it should run. We will add persistence soon.

5. **Environment variable mismatch**:
   Ensure the app's env var matches the service name. If the Node app is looking for `MONGO_HOST` or something, our `MONGO_URL` might not be used. We assumed a generic connection string env. Adapt to your app's config needs. You can pass multiple env vars (like `DB_HOST = mongo-service`, `DB_PORT = 27017`, etc.).

## Organizing Your Kubernetes Manifests

Now, we have a basic two-tier architecture running on Kubernetes. It's a good practice to organize your manifests in a Git repository. For example, you might create a directory structure:

```
k8s-manifests/
  day1/
    nginx-deployment.yaml
    nginx-service.yaml
    sparta-node-deployment.yaml
    sparta-node-service.yaml
    mongo-deployment.yaml
    mongo-service.yaml
```

And so on. We'll refine this setup on Days 2 and 3 with persistence and autoscaling.

Before moving on, commit your YAML files to a Git repo (if you have one set up) and document what you did in the README (including any issues encountered and how you solved them). Capturing command outputs (logs, `kubectl get all` output) in your documentation is helpful for debugging and for others to understand the state.

At this stage, Day 1 deliverables would include:
- The cluster up and running (Docker Desktop with Kubernetes)
- An Nginx deployment reachable on localhost:30001
- The Sparta Node.js app with MongoDB reachable on localhost:30002 (assuming the test app exposes something at that port)
- Demonstration of scaling and self-healing
- All YAMLs and a write-up in your repo
