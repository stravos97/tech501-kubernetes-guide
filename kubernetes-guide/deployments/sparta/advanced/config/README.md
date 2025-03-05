# Sparta Advanced Configuration

This directory contains the core configuration files for the advanced Sparta Node.js deployment with Horizontal Pod Autoscaler (HPA).

## Files

- `sparta-deploy.yml`: Deployment configuration for the Sparta Node.js app and MongoDB database with resource requests and limits
- `sparta-service.yml`: Service configuration to expose the Sparta app and MongoDB
- `sparta-hpa.yml`: Horizontal Pod Autoscaler configuration for automatic scaling based on CPU utilization

## Key Features

### Resource Requests and Limits

The deployment includes CPU and memory resource requests and limits, which are essential for the HPA to function properly:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 200m
    memory: 256Mi
```

### Horizontal Pod Autoscaler

The HPA is configured to scale the Sparta Node.js app between 2 and 10 replicas based on CPU utilization:

```yaml
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

## Usage

To apply these configurations:

```bash
# Apply the deployment and service
kubectl apply -f sparta-deploy.yml
kubectl apply -f sparta-service.yml

# Apply the HPA
kubectl apply -f sparta-hpa.yml
```

To monitor the HPA:

```bash
kubectl get hpa sparta-node-hpa -w
```

## Notes

- The HPA requires the metrics-server to be running in the cluster
- For load testing to see the HPA in action, see the files in the `../testing/` directory
