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

## Why Manual Process?

The manual process offers several advantages:
1. **Greater Control**: Direct visibility into the npm install process
2. **Troubleshooting**: Ability to see errors in real-time and fix issues immediately
3. **Flexibility**: Option to install additional packages or run other commands as needed
4. **Reliability**: Avoids timing issues that can occur with automated jobs

## How to Manually Install NPM Packages

### 1. Deploy the Sparta App

First, deploy the Sparta app using the updated deployment script:

```bash
./deploy-sparta.sh
```

This will:
- Deploy the MongoDB database with persistent volume
- Create the necessary services
- Deploy the Sparta app with `EXECUTE_NPM_INSTALL: "false"`
- Skip the automated database seeding job
- Copy the `connect-to-sparta.sh` script to the remote server
- Configure Nginx as a reverse proxy
- Set up Minikube auto-start
- Prompt you to connect to the pod for npm install and database seeding

When the deployment completes, you'll be asked if you want to connect to the pod immediately to run npm install and database seeding. If you choose "yes", the script will automatically run the `connect-to-sparta.sh` script for you.

Alternatively, you can use the all-in-one deployment script:

```bash
./deploy-all.sh
```

This script runs `deploy-sparta.sh` and performs additional verification steps.

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
- Provide instructions for npm install and database seeding

### 3. Run NPM Install and Database Seeding Inside the Pod

Once connected to the pod, you'll be in a bash shell inside the container. Run the following commands:

```bash
cd /app
npm install
```

This will install all the required dependencies for the Sparta app. You should see output similar to:

```
added 455 packages, and audited 456 packages in 15s
found 0 vulnerabilities
```

After npm install completes, seed the database with:

```bash
node seeds/seed.js
```

This will populate the MongoDB database with initial data for the application. Successful seeding will show output like:

```
Database seeded! 100 posts created.
```

### 4. Verify the Application

After npm install and database seeding complete, you can exit the pod by typing `exit`.

Verify that the application is working correctly by accessing it at the EC2 instance's public IP address:

```
http://<EC2_INSTANCE_IP>
```

You should see the Sparta app homepage with posts displayed. If the page is blank or shows errors, check the troubleshooting section below.

## Relationship with Init Containers

The Sparta app deployment includes an init container that ensures MongoDB is ready before the application starts. This init container:

1. Waits for the MongoDB service to be accessible
2. Verifies that the database is accepting connections
3. Only then allows the main application container to start

This ensures proper sequencing between components, but does not handle npm installation or database seeding. Those steps still need to be performed manually as described in this document.

For more details on the init container implementation, see [sparta-init-container-docs.md](sparta-init-container-docs.md).

## Troubleshooting

### Common Issues

1. **NPM Install Fails**
   - Check internet connectivity within the pod
   - Verify that the pod has sufficient resources
   - Try running with `npm install --verbose` for more detailed output

2. **Database Seeding Fails**
   - Ensure MongoDB is running: `kubectl get pods -l app=sparta-db`
   - Check MongoDB connection string in the environment variables
   - Verify MongoDB service is accessible: `nc -zv sparta-db-service 27017`

3. **Application Shows Blank Page After Seeding**
   - Check application logs: `kubectl logs -l app=sparta-node`
   - Verify that the database was successfully seeded
   - Restart the application pod if necessary: `kubectl rollout restart deployment sparta-node-deployment`

### Checking Logs

To check logs for the Sparta app:

```bash
./check-logs.sh
```

This script will connect to the remote server and display logs from the Sparta app pod.
