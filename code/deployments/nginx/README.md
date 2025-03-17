# Nginx Deployment

This directory contains a basic Nginx deployment example for Kubernetes.

## Files

- `nginx-deploy.yml`: Deployment configuration for Nginx
- `nginx-service.yml`: Service configuration to expose the Nginx deployment

## Usage

To deploy Nginx to your Kubernetes cluster:

```bash
kubectl apply -f nginx-deploy.yml
kubectl apply -f nginx-service.yml
```

To verify the deployment:

```bash
kubectl get deployments
kubectl get pods
kubectl get services
```

## Purpose

This simple Nginx deployment serves as a basic example of how to deploy a web server in Kubernetes. It demonstrates:

1. Creating a deployment with a specified number of replicas
2. Exposing the deployment using a Kubernetes Service
3. Basic configuration of container ports and resource limits

This example can be used as a starting point for more complex web server deployments.
