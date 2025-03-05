# Kubernetes Guide

This repository contains Kubernetes configuration files, examples, and documentation for learning and implementing Kubernetes features.

## Repository Structure

```
kubernetes-guide/
├── deployments/                  # Application deployments
│   ├── nginx/                    # Basic Nginx deployment example
│   └── sparta/                   # Sparta Node.js application deployments
│       ├── basic/                # Basic deployment without advanced features
│       └── advanced/             # Advanced deployment with HPA and PV
│           ├── config/           # Core configuration files
│           ├── persistence/      # PV and PVC configurations
│           └── testing/          # Load testing and test scripts
├── infrastructure/               # Cluster-level components
│   └── metrics-server/           # Metrics Server configurations
├── docs/                         # Documentation
│   ├── implementation/           # Implementation details
│   └── diagrams/                 # Architecture diagrams
└── notes/                        # Learning notes and tutorials
```

## Key Features

This repository demonstrates several key Kubernetes features:

1. **Basic Deployments**: Simple Nginx and Sparta Node.js deployments
2. **Horizontal Pod Autoscaler (HPA)**: Automatic scaling based on CPU utilization
3. **Persistent Volumes (PV) and Claims (PVC)**: Data persistence with volume management
4. **Load Testing**: Tools for testing application performance and autoscaling
5. **Metrics Server**: Configuration for collecting resource metrics

## Getting Started

To get started with the examples in this repository:

1. Ensure you have a Kubernetes cluster running (Minikube, Docker Desktop, or a cloud provider)
2. Install the Metrics Server for HPA functionality:
   ```bash
   kubectl apply -f infrastructure/metrics-server/metrics-server-fixed.yaml
   ```
3. Deploy the basic examples:
   ```bash
   kubectl apply -f deployments/nginx/nginx-deploy.yml
   kubectl apply -f deployments/nginx/nginx-service.yml
   ```
4. Explore the advanced examples with HPA and PV:
   ```bash
   # Apply the PV and PVC
   kubectl apply -f deployments/sparta/advanced/persistence/pv.yml
   
   # Apply the deployment and service
   kubectl apply -f deployments/sparta/advanced/config/sparta-deploy.yml
   kubectl apply -f deployments/sparta/advanced/config/sparta-service.yml
   
   # Apply the HPA
   kubectl apply -f deployments/sparta/advanced/config/sparta-hpa.yml
   ```

5. Run load tests to see the HPA in action:
   ```bash
   kubectl apply -f deployments/sparta/advanced/testing/load-test.yml
   ```

## Documentation

For more detailed information, refer to:

- [Implementation Details](docs/implementation/IMPLEMENTATION.md): Detailed explanation of HPA and PV/PVC management
- [Architecture Diagrams](docs/diagrams/diagrams.md): Visual representations of the system architecture
- [Notes](notes/): Learning materials and tutorials on Kubernetes concepts

## License

This project is licensed under the MIT License - see the LICENSE file for details.
