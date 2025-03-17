# Manual NPM Install Process for Sparta App

This document explains the process for manually connecting to the Sparta app pod and running npm install, which replaces the automated database seeding job approach.

## Background

Previously, the Sparta app deployment used a Kubernetes Job (`sparta-db-seed-job.yml`) to:
1. Wait for the MongoDB database to be ready
2. Run npm install to install dependencies
3. Seed the database with initial data

This approach has been replaced with a manual process where you:
1. Deploy the application with `EXECUTE_NPM_INSTALL: "false"` in the deployment manifest
2. Use a script to connect to the running pod
3. Manually run npm install inside the pod

## How to Manually Install NPM Packages

### 1. Deploy the Sparta App

First, deploy the Sparta app using the updated deployment script:

```bash
./deploy-sparta.sh
```

This will:
- Deploy the MongoDB database
- Deploy the Sparta app with `EXECUTE_NPM_INSTALL: "false"`
- Skip the automated database seeding job
- Copy the `connect-to-sparta.sh` script to the remote server
- Prompt you to connect to the pod for npm install and database seeding

When the deployment completes, you'll be asked if you want to connect to the pod immediately to run npm install and database seeding. If you choose "yes", the script will automatically run the `connect-to-sparta.sh` script for you.

### 2. Connect to the Sparta App Pod

If you chose not to connect during deployment, you can connect later using the provided script:

```bash
./connect-to-sparta.sh
```

This script will:
- Check the connection to the remote server
- Verify that Minikube is running
- Find a running Sparta app pod
- Connect you to the pod using `kubectl exec`

### 3. Run NPM Install and Database Seeding Inside the Pod

Once connected to the pod, you'll be in a bash shell inside the container. Run the following commands:

```bash
cd /app
npm install
```

This will install all the required dependencies for the Sparta app.

After npm install completes, seed the database with:

```bash
node seeds/seed.js
```

This will populate the MongoDB database with initial data for the application.

### 4. Verify the Application

After npm install completes, you can exit the pod by typing `exit`.

Verify that the application is working correctly by accessing it at the EC2 instance's public IP address:

```
http://<EC2_INSTANCE_IP>
```

## Advantages of Manual NPM Install

1. **Greater Control**: You have direct control over the npm install process
2. **Troubleshooting**: You can see any errors or warnings in real-time
3. **Flexibility**: You can install additional packages or run other commands as needed
4. **Transparency**: The process is more visible and easier to understand

## Database Seeding

The Sparta application comes with a built-in database seeding script that you should run after installing the npm packages. This script will populate the MongoDB database with initial data for the application.

To run the database seeding script:

```bash
# While connected to the pod
cd /app
node seeds/seed.js
```

This will:
1. Connect to the MongoDB database
2. Check if data already exists
3. If needed, seed the database with initial data
4. Display information about the seeding process

The seeding script is part of the application codebase, so there's no need to create a custom script. This approach ensures that the database is populated with the correct data structure expected by the application.
