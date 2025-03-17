# Database Seeding Solution for Sparta App

> **Note:** This document describes a previous approach using an automated Kubernetes Job for database seeding. The current implementation uses a manual process as described in [manual-npm-install-docs.md](manual-npm-install-docs.md).

## Problem Addressed

The Sparta app was showing a blank page because the MongoDB database was not being populated with initial data. While the app and database were connecting successfully, the "posts" collection was empty, resulting in no content being displayed on the page.

## Solution Implemented (Previous Approach)

We initially implemented a database seeding mechanism using a Kubernetes Job that runs once to populate the database with sample data. This ensured that the app had content to display when it started up.

## Technical Details of Previous Approach

### 1. Database Seeding Job

We created a Kubernetes Job (`sparta-db-seed-job.yml`) that:
- Uses the same image as the Sparta app
- Waits for MongoDB to be ready using an init container
- Creates and runs a database seeding script that:
  - Checks if data already exists to avoid duplicate seeding
  - Creates 100 sample posts
  - Verifies successful seeding

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: sparta-db-seed-job
spec:
  ttlSecondsAfterFinished: 100  # Delete job after completion
  template:
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
        - name: db-seed
          image: haashim1/haashim-node-website:multi
          command: ['/bin/bash', '-c']
          args:
            - |
              cd /app
              echo "Installing npm packages..."
              npm install
              
              echo "Seeding database..."
              node seeds/seed.js
              
              echo "Database seeding completed!"
      restartPolicy: OnFailure
```

### 2. Deployment Process with Automated Seeding

The deployment script (`deploy-sparta.sh`) was configured to:
- Deploy components in the correct sequence:
  1. Database (MongoDB)
  2. Database seeding job
  3. Application (Sparta app)
- Wait for each component to be ready before proceeding to the next
- Display logs from the seeding job for verification

```bash
# Deploy the database first
echo "Deploying database..."
ssh $REMOTE_SERVER "kubectl apply -f ~/sparta-app/sparta-deploy.yml -l app=sparta-db"

# ... wait for database to be ready ...

# Run the database seeding job
echo "Running database seeding job..."
ssh $REMOTE_SERVER "kubectl apply -f ~/sparta-app/sparta-db-seed-job.yml"

# ... wait for seeding job to complete ...

# Deploy the app after database is seeded
echo "Deploying app..."
ssh $REMOTE_SERVER "kubectl apply -f ~/sparta-app/sparta-deploy.yml -l app=sparta-node"
```

### 3. Deployment Labeling

Labels were added to the deployments in `sparta-deploy.yml` to enable selective deployment:
- `app: sparta-db` for the database deployment
- `app: sparta-node` for the app deployment

This allowed deploying the database and app separately, ensuring proper sequencing.

## Benefits of the Automated Approach

1. **Reliability**: The app would always have data to display, preventing the blank page issue
2. **Idempotency**: The seeding job checked if data already existed, avoiding duplicate data
3. **Proper Sequencing**: Components were deployed in the correct order with verification at each step
4. **Maintainability**: The seeding logic was separate from the application code
5. **Visibility**: Logs from the seeding job provided verification of successful data population

## Migration to Manual Process

### Why We Changed Approaches

While the automated job approach worked well, we migrated to a manual process for several reasons:

1. **Troubleshooting**: The automated job made it difficult to diagnose issues when they occurred
2. **Flexibility**: Manual process allows for ad-hoc commands and adjustments during deployment
3. **Transparency**: Direct visibility into the npm install and seeding process
4. **Learning**: Better for educational purposes to understand what's happening at each step

### Current Manual Approach

The current approach involves:

1. Deploying the application with `EXECUTE_NPM_INSTALL: "false"` in the deployment manifest
2. Connecting to the pod manually using the `connect-to-sparta.sh` script
3. Running npm install and database seeding commands directly in the pod

For detailed instructions on the current manual process, see [manual-npm-install-docs.md](manual-npm-install-docs.md).

## Testing the Previous Approach

If you want to test the previous automated approach:

1. Apply the database seeding job:
   ```bash
   kubectl apply -f sparta-db-seed-job.yml
   ```

2. Check the logs of the seeding job:
   ```bash
   kubectl logs job/sparta-db-seed-job
   ```

## Future Considerations

For more complex deployments, consider:
1. Using Helm charts for more sophisticated deployment orchestration
2. Implementing database migrations for schema changes
3. Creating a more comprehensive data seeding strategy with different data sets for different environments
4. Using Kubernetes Init Containers for more complex initialization sequences
