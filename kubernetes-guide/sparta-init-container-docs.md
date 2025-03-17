# Sparta App Deployment Improvements

## Problem Addressed

The Sparta app was showing a blank page because the application was starting before the MongoDB database was fully initialized. This timing issue prevented the application from properly connecting to the database and initializing the data.

## Solution Implemented

We've implemented a lightweight solution using an init container to ensure proper sequencing between the database and application startup:

1. **Added an Init Container**: The init container uses a small Alpine Linux image to check if MongoDB is ready before allowing the main application container to start.

2. **Added Readiness Probe**: A readiness probe was added to ensure the application is truly ready to serve traffic.

3. **Enhanced Deployment Script**: The deployment script now waits for all pods to be ready before considering the deployment complete.

## Technical Details

### Init Container

The init container uses `netcat` to check if the MongoDB port is open and accepting connections:

```yaml
initContainers:
  - name: wait-for-mongodb
    image: alpine:3.16
    command: ['/bin/sh', '-c']
    args:
      - |
        echo "Waiting for MongoDB to be ready..."
        apk add --no-cache netcat-openbsd
        until nc -z sparta-db-service 27017; do
          echo "MongoDB not ready yet, waiting..."
          sleep 2
        done
        echo "MongoDB is ready!"
```

This ensures that the main application container only starts after MongoDB is available.

### Readiness Probe

The readiness probe checks if the application is responding on port 3000:

```yaml
readinessProbe:
  httpGet:
    path: /
    port: 3000
  initialDelaySeconds: 5
  periodSeconds: 5
```

This ensures that Kubernetes only sends traffic to the application once it's fully initialized and ready to serve requests.

### Deployment Script Enhancements

The deployment script now includes explicit wait steps to ensure all pods are ready:

```bash
# Wait for all pods to be ready
echo "Waiting for all pods to be ready..."
ssh $REMOTE_SERVER "
  echo 'Waiting for database pod to be ready...'
  kubectl wait --for=condition=ready pod -l app=sparta-db --timeout=120s
  
  echo 'Waiting for app pods to be ready...'
  kubectl wait --for=condition=ready pod -l app=sparta-node --timeout=120s
  
  echo 'All pods are ready!'
"
```

## Testing

A test script (`test-sparta-init.sh`) has been provided to verify the init container functionality locally before deploying to the remote server.

## Environment Variables

The `EXECUTE_NPM_INSTALL=true` environment variable is already correctly configured in the deployment. This variable triggers npm install in the entrypoint script when the container starts. With the init container in place, this will now happen after MongoDB is ready, ensuring proper database connectivity during the npm install process.

## Benefits of This Approach

1. **Minimal Resource Usage**: Uses a lightweight Alpine image for the init container
2. **Simple Implementation**: Easy to understand and maintain
3. **Reliable Sequencing**: Guarantees that the app only starts after the database is ready
4. **Improved User Experience**: Prevents the blank page issue by ensuring proper initialization

## Future Improvements

For more complex deployments, consider:

1. Adding a more sophisticated health check in the init container
2. Implementing database migration/seeding as a separate job
3. Using Helm charts for more advanced deployment orchestration
