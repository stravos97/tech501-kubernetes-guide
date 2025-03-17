# Basic Sparta Node.js Deployment

This directory contains the basic deployment configuration for the Sparta Node.js application without advanced features like HPA or persistent volumes.

## Files

- `sparta-deploy.yml`: Deployment configuration for the Sparta Node.js app and MongoDB database
- `sparta-service.yml`: Service configuration to expose the Sparta app and MongoDB

## Usage

To deploy the basic Sparta application to your Kubernetes cluster:

```bash
kubectl apply -f sparta-deploy.yml
kubectl apply -f sparta-service.yml
```

To verify the deployment:

```bash
kubectl get deployments
kubectl get pods
kubectl get services
```

## Purpose

This basic deployment demonstrates:

1. Creating a multi-container application in Kubernetes
2. Setting up a web application (Sparta Node.js) with a database (MongoDB)
3. Configuring environment variables for container communication
4. Exposing services with appropriate port configurations

For a more advanced deployment with Horizontal Pod Autoscaler (HPA) and Persistent Volumes (PV), see the `../advanced/` directory.
