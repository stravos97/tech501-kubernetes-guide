# Kubernetes Horizontal Pod Autoscaler (HPA) and Persistent Volume Management

This directory contains Kubernetes configuration files for implementing Horizontal Pod Autoscaler (HPA) and managing Persistent Volumes (PV) with data retention.

## Files Overview

- `sparta-deploy.yml`: Deployment configuration for the Sparta Node.js app and MongoDB database
- `sparta-service.yml`: Service configuration for exposing the Sparta app and MongoDB
- `pv.yml`: Persistent Volume and Persistent Volume Claim configuration
- `sparta-hpa.yml`: Horizontal Pod Autoscaler configuration for the Sparta Node.js app
- `load-test.yml`: Load generator deployment for testing the HPA
- `pvc-recreate.yml`: PVC recreation configuration for the extension task

## Task 1: Horizontal Pod Autoscaler (HPA)

The HPA is configured to scale the Sparta Node.js app between 2 and 10 replicas based on CPU utilization.

### Implementation Details

- Target CPU utilization: 50%
- Minimum replicas: 2
- Maximum replicas: 10

### How to Apply

```bash
# Apply the deployment with resource requests
kubectl apply -f sparta-deploy.yml

# Apply the HPA configuration
kubectl apply -f sparta-hpa.yml
```

### Testing the HPA

The load testing has been updated to use Apache Bench (via the alpine-bench Docker image) for more detailed performance metrics.

#### Option 1: One-time Apache Bench Test (Job)

1. Apply the load generator job:
   ```bash
   kubectl apply -f load-test.yml
   ```

2. View the Apache Bench results:
   ```bash
   kubectl logs job/load-generator
   ```

3. The results will be in JSON format with detailed metrics including:
   - Connection times (min, max, mean, median)
   - Processing times
   - Waiting times
   - Percentile data (50%, 66%, 75%, 80%, 90%, 95%, 98%, 99%, 100%)

#### Option 2: Continuous Load Testing (Deployment)

1. Apply the continuous load generator:
   ```bash
   kubectl apply -f load-test.yml
   ```

2. Monitor the continuous load test logs:
   ```bash
   kubectl logs -f deployment/continuous-load-generator
   ```

3. Monitor the HPA and pods:
   ```bash
   kubectl get hpa sparta-node-hpa -w
   kubectl get pods -l app=sparta-node -w
   ```

4. To stop the load test:
   ```bash
   kubectl delete -f load-test.yml
   ```

#### Using the Test Script

The test-scripts.sh file provides an interactive way to run the load tests:

```bash
./test-scripts.sh
```

Select option 1 to test the HPA, then choose between one-time or continuous load testing.

## Task 2: Remove PVC and Retain Data in Persistent Volume

This extension task demonstrates how to delete a PVC while retaining the data in the Persistent Volume.

### Steps to Implement

1. Scale down the MongoDB deployment:
   ```bash
   kubectl scale deployment sparta-db-deployment --replicas=0
   ```

2. Delete the PVC:
   ```bash
   kubectl delete pvc sparta-db-pvc
   ```

3. Verify the PV still exists and retains the data:
   ```bash
   kubectl get pv
   ```

4. Recreate the PVC with the same configuration:
   ```bash
   kubectl apply -f pvc-recreate.yml
   ```

5. Scale up the MongoDB deployment:
   ```bash
   kubectl scale deployment sparta-db-deployment --replicas=1
   ```

6. Verify the data is still accessible:
   ```bash
   # Get the pod name
   POD_NAME=$(kubectl get pods -l app=sparta-db -o jsonpath='{.items[0].metadata.name}')
   
   # Connect to MongoDB
   kubectl exec -it $POD_NAME -- mongo
   ```

## Notes

- The PV is configured with `persistentVolumeReclaimPolicy: Retain` which ensures the data is not deleted when the PVC is deleted.
- The HPA requires the metrics-server to be running in the cluster.
- Resource requests are added to the Sparta Node.js app deployment to enable the HPA to function properly.
