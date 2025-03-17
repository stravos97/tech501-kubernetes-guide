# Implementation Details: HPA and PV/PVC Management

## Horizontal Pod Autoscaler (HPA) Implementation

### Overview

The Horizontal Pod Autoscaler (HPA) automatically scales the number of pods in a deployment based on observed CPU utilization. In this implementation, we've configured the HPA to scale the Sparta Node.js application between 2 and 10 replicas, targeting 50% CPU utilization.

### Key Components

1. **Resource Requests in Deployment**:
   - Added CPU and memory resource requests to the Sparta Node.js app deployment
   - CPU request: 100m (100 millicores, or 0.1 CPU core)
   - Memory request: 128Mi
   - These resource requests are essential for the HPA to function properly

2. **HPA Configuration**:
   - Minimum replicas: 2 (ensures at least 2 pods are running for high availability)
   - Maximum replicas: 10 (prevents over-scaling during high load)
   - Target CPU utilization: 50% (scales up when average CPU usage exceeds 50% of the requested CPU)

3. **Load Testing with Apache Bench**:
   - Implemented two load testing approaches using the alpine-bench Docker image:
     - One-time Apache Bench test (Kubernetes Job)
     - Continuous load testing (Kubernetes Deployment)
   - The alpine-bench image runs Apache Bench and outputs detailed metrics in JSON format
   - Metrics include connection times, processing times, waiting times, and percentile data
   - This provides more comprehensive performance data compared to simple request generation

### How It Works

1. The HPA controller periodically checks the CPU utilization of the pods in the Sparta Node.js deployment
2. If the average CPU utilization exceeds 50%, the HPA increases the number of replicas
3. If the average CPU utilization falls below 50%, the HPA decreases the number of replicas (but not below the minimum of 2)
4. The scaling is gradual and respects cooldown periods to prevent thrashing

## PV/PVC Management for Data Retention

### Overview

This implementation demonstrates how to delete a Persistent Volume Claim (PVC) while retaining the data in the Persistent Volume (PV). This is useful for scenarios where you need to recreate a PVC but want to keep the existing data.

### Key Components

1. **Persistent Volume Configuration**:
   - The PV is configured with `persistentVolumeReclaimPolicy: Retain`
   - This ensures that when the PVC is deleted, the PV and its data are not deleted

2. **PVC Recreation Process**:
   - Scale down the MongoDB deployment to safely detach from the PVC
   - Delete the PVC
   - Create a new PVC with the same configuration
   - Scale up the MongoDB deployment to reattach to the new PVC

### How It Works

1. When a PVC is deleted, the PV's reclaim policy determines what happens to the PV and its data
2. With `Retain` policy, the PV becomes "Released" but keeps its data
3. A new PVC can then be created that references the same PV
4. When the MongoDB pod restarts, it mounts the same PV with the existing data

## Testing and Verification

### HPA Testing

1. Apply the deployment and HPA configuration
2. Start the load generator to increase CPU usage
3. Observe the HPA scaling up the number of replicas
4. Stop the load generator and observe the HPA scaling down after the cooldown period

### PV/PVC Testing

1. Create some test data in MongoDB
2. Scale down the MongoDB deployment
3. Delete the PVC
4. Verify the PV still exists
5. Create a new PVC with the same configuration
6. Scale up the MongoDB deployment
7. Verify the data is still accessible

## Conclusion

This implementation provides a robust solution for:
1. Automatically scaling the Sparta Node.js application based on CPU utilization
2. Managing persistent storage with data retention capabilities

The combination of these features ensures that the application can handle variable load while maintaining data persistence.
