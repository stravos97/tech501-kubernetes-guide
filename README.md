# Kubernetes Reference

This document serves as a reference to the Kubernetes documentation and resources available in the tech501-kubernetes repository.

## Repository Location

The Kubernetes code and documentation can be found at:
```
/Users/haashimalvi/Downloads/Do not delete/spartaglobal/tech501-kubernetes
```

## Key Documentation

For detailed Kubernetes documentation, please refer to the [Kubernetes-Guide.md](Kubernetes-Guide.md) file in this directory, which provides comprehensive information on:

- Deploying a Node.js "Sparta" Test App with MongoDB
- Setting up persistent storage for MongoDB
- Implementing horizontal pod autoscaling
- Troubleshooting common issues

## Repository Structure

The Kubernetes repository is organized into two main directories:

### `/code`

Contains all Kubernetes manifests, configuration files, and scripts:

- `/code/app1` - App1 deployment and service manifests
- `/code/app2` - App2 deployment and service manifests
- `/code/app3` - App3 deployment and service manifests, along with deployment scripts
- `/code/nginx` - Nginx deployment and service manifests
- `/code/sparta` - Sparta application deployment and service manifests
- `/code/sparta-with-pv` - Sparta application with persistent volume configuration
- `/code/config` - Configuration files for various applications
- `/code/scripts` - Shell scripts for deployment and management
- `/code/infrastructure` - Infrastructure components like metrics-server
- `/code/deployments` - Additional deployment configurations
- `/code/logs` - Log files

### `/docs`

Contains all documentation:

- `/docs/app3` - Documentation specific to App3
- `/docs/diagrams` - Diagrams and visual documentation
- `/docs/implementation` - Implementation guides and documentation
- `/docs/day1-fundamentals` - Day 1 fundamentals documentation
- `/docs/day2` - Day 2 documentation (Persistent Storage, Autoscaling)
- `/docs/day3` - Day 3 documentation (Advanced topics)

## Key Scripts

All scripts should be run from the root directory of the Kubernetes repository:

```bash
# Deploy all applications
./code/scripts/deploy-all-apps.sh

# Deploy Sparta application
./code/scripts/deploy-sparta.sh

# Connect to Sparta application
./code/scripts/sparta-connect.sh

# Check Sparta logs
./code/scripts/sparta-check-logs.sh

# Start Minikube
./code/scripts/minikube-start.sh

# Cleanup App3
./code/app3/app3-cleanup.sh

# Recover Kubernetes after instance restart
./code/app3/kubernetes-recover.sh

# Sparta with Persistent Volume scripts
./code/sparta-with-pv/minikube-setup.sh
./code/sparta-with-pv/sparta-pv-test.sh
```
