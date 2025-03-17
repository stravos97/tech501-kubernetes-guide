# Sparta App Init Container Implementation

## Problem Addressed

The Sparta app was showing a blank page because the application was starting before the MongoDB database was fully initialized. This timing issue prevented the application from properly connecting to the database and initializing the data.

## Solution Implemented

We've implemented a lightweight solution using an init container to ensure proper sequencing between the database and application startup:

1. **Added an Init Container**: The init container uses a small Alpine Linux image to check if MongoDB is ready before allowing the main application container to start.

2. **Added Readiness Probe**: A readiness probe was added to ensure the application is truly ready to serve traffic.

3. **Enhanced Deployment Script**: The deployment script now waits for all pods to be ready before considering the deployment complete.

4. **Manual NPM Install Process**: Combined with the init container, we now use a manual process for npm installation and database seeding (see [manual-npm-install-docs.md](manual-npm-install-docs.md)).

## Technical Details

### Init Container Implementation

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

### Deployment Manifest

The init container is included in the `sparta-deploy.yml` file as part of the Sparta Node.js application deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sparta-node-deployment
  labels:
    app: sparta-node
spec:
  replicas: 2
  selector:
    matchLabels:
      app: sparta-node
  template:
    metadata:
      labels:
        app: sparta-node
    spec:
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
      containers:
        - name: sparta-app
          # ... container configuration ...
```

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

### Component Sequencing

The complete deployment sequence is now:

1. **MongoDB Deployment**: Database pod is created and started
2. **Wait for MongoDB Readiness**: Kubernetes waits for the MongoDB pod to be ready
3. **Sparta App Deployment**: Application pods are created
4. **Init Container Execution**: Each app pod runs the init container to verify MongoDB is accessible
5. **Main Container Start**: After init container succeeds, the main application container starts
6. **Manual NPM Install**: User connects to the pod and manually runs npm install
7. **Database Seeding**: User manually runs the database seeding script
8. **Readiness Check**: Kubernetes checks if the application is responding on port 3000
9. **Traffic Routing**: Once ready, traffic is routed to the application

### Deployment Script Enhancements

The deployment script (`deploy-sparta.sh`) includes explicit wait steps to ensure all pods are ready:

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

This ensures that the deployment script doesn't consider the deployment complete until all pods are fully ready.

## Testing

A test script (`test-sparta-init.sh`) has been provided to verify the init container functionality locally before deploying to the remote server. You can run it with:

```bash
./test-sparta-init.sh
```

This script will:
1. Apply the deployment locally
2. Monitor the init container logs
3. Verify that the init container completes successfully
4. Check that the main container starts only after the init container succeeds

## Environment Variables

The `EXECUTE_NPM_INSTALL=false` environment variable is configured in the deployment. This variable is set to `false` because we now use a manual process for npm installation rather than having it run automatically when the container starts.

```yaml
env:
  - name: DB_HOST
    value: "mongodb://sparta-db-service:27017/posts"
  - name: EXECUTE_NPM_INSTALL
    value: "false"
```

With the init container in place and this environment variable set to `false`, the application container will:
1. Start only after MongoDB is ready (thanks to the init container)
2. Skip the automatic npm install process (due to the environment variable)
3. Wait for manual npm install and database seeding (performed by the user)

## Benefits of This Approach

1. **Minimal Resource Usage**: Uses a lightweight Alpine image for the init container
2. **Simple Implementation**: Easy to understand and maintain
3. **Reliable Sequencing**: Guarantees that the app only starts after the database is ready
4. **Improved User Experience**: Prevents the blank page issue by ensuring proper initialization
5. **Clear Separation of Concerns**: Init container handles dependency checking, while manual process handles npm install and seeding

## Relationship with Manual NPM Install Process

The init container works in conjunction with the manual npm install process:

1. **Init Container**: Ensures MongoDB is ready before the application container starts
2. **Manual NPM Install**: Allows the user to connect to the running pod and manually install dependencies
3. **Manual Database Seeding**: Allows the user to manually seed the database after npm install

This combination provides maximum control and visibility into the deployment process. For details on the manual npm install process, see [manual-npm-install-docs.md](manual-npm-install-docs.md).

## Troubleshooting

If the init container fails or gets stuck:

1. Check if MongoDB is running:
   ```bash
   kubectl get pods -l app=sparta-db
   ```

2. Verify MongoDB service is correctly defined:
   ```bash
   kubectl get svc sparta-db-service
   ```

3. Check init container logs:
   ```bash
   kubectl logs <pod-name> -c wait-for-mongodb
   ```

4. Test MongoDB connectivity manually:
   ```bash
   kubectl exec -it <mongodb-pod-name> -- mongo
   ```

## Future Improvements

For more complex deployments, consider:

1. Adding a more sophisticated health check in the init container
2. Implementing database migration as a separate job
3. Using Helm charts for more advanced deployment orchestration
4. Adding readiness gates for more complex dependency management
