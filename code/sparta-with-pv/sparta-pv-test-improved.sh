#!/bin/bash

# Recovery script for PV/PVC binding issues

echo "===== PV/PVC BINDING RECOVERY ====="

# 1. Check current status
echo "Checking current status..."
kubectl get pv
kubectl get pvc

# 2. If PVC is stuck in Pending while trying to bind to a Released PV
echo "Fixing Released PV to make it Available again..."
kubectl patch pv sparta-db-pv -p '{"spec":{"claimRef": null}}'

# 3. Wait a moment for the change to take effect
echo "Waiting for changes to propagate..."
sleep 5

# 4. Verify PV is now Available
echo "Checking PV status again..."
kubectl get pv sparta-db-pv

# 5. Check if the PVC is now bound
echo "Checking PVC status..."
kubectl get pvc sparta-db-pvc

# 6. Update deployment with proper volume configuration
echo "Updating the deployment with proper volume configuration..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sparta-db-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sparta-db
  template:
    metadata:
      labels:
        app: sparta-db
    spec:
      containers:
      - name: mongodb
        image: mongo:4.4
        ports:
        - containerPort: 27017
        volumeMounts:
        - name: mongodb-data
          mountPath: /data/db
      volumes:
      - name: mongodb-data
        persistentVolumeClaim:
          claimName: sparta-db-pvc
EOF

# 7. Wait for deployment to be ready
echo "Waiting for deployment to be ready..."
kubectl rollout status deployment/sparta-db-deployment --timeout=60s

# 8. Check pod status
echo "Checking pod status..."
kubectl get pods -l app=sparta-db

# 9. Check logs for any issues
echo "Checking MongoDB pod logs..."
POD_NAME=$(kubectl get pods -l app=sparta-db -o jsonpath='{.items[0].metadata.name}')
if [ -n "$POD_NAME" ]; then
  kubectl logs $POD_NAME
else
  echo "No pod found."
fi

echo "===== RECOVERY COMPLETE ====="
echo "If MongoDB is still not running, inspect detailed pod information:"
echo "kubectl describe pod \$(kubectl get pods -l app=sparta-db -o jsonpath='{.items[0].metadata.name}')"