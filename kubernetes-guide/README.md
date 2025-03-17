# Kubernetes Guide

This repository contains Kubernetes deployment configurations and scripts for various applications.

## Directory Structure

The repository is organized into two main directories:

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
- Various markdown files with documentation on different aspects of the system

## Usage

All scripts should be run from the root directory of the repository. The scripts have been updated to reference files in their new locations.

For example, to deploy App1 and App2:

```bash
./code/scripts/deploy-app1-app2.sh
```

To deploy App3:

```bash
./code/app3/app3-deploy.sh
```

Other useful scripts:

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

## Notes

- All paths in scripts have been updated to reference the new file structure
- Configuration files are now located in `/code/config`
- Documentation is now centralized in the `/docs` directory
