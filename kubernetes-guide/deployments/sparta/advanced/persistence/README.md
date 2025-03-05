# Persistent Volume Management

This directory contains configuration files for managing Persistent Volumes (PV) and Persistent Volume Claims (PVC) in the Sparta application.

## Files

- `pv.yml`: Persistent Volume and initial Persistent Volume Claim configuration
- `pvc-recreate.yml`: Configuration for recreating the PVC while retaining data in the PV

## Key Features

### Persistent Volume with Retain Policy

The PV is configured with a `persistentVolumeReclaimPolicy: Retain` which ensures that when the PVC is deleted, the PV and its data are not deleted:

```yaml
persistentVolumeReclaimPolicy: Retain
```

### PVC Recreation Process

The `pvc-recreate.yml` file is used to recreate the PVC with the same configuration after it has been deleted. This demonstrates how to delete a PVC while retaining the data in the PV.

## Usage

### Initial Setup

To create the PV and initial PVC:

```bash
kubectl apply -f pv.yml
```

### PVC Recreation Process

To demonstrate PV/PVC management with data retention:

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

## Notes

- The PV uses a `hostPath` volume type which is suitable for development and testing but not for production environments
- In a production environment, you would typically use a cloud provider's storage solution or a storage class
- The MongoDB deployment is configured to use this PV/PVC for data persistence
