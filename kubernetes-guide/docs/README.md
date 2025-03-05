# Documentation

This directory contains comprehensive documentation for the Kubernetes Guide project.

## Directory Structure

```
docs/
├── implementation/       # Detailed implementation documentation
│   └── IMPLEMENTATION.md # HPA and PV/PVC management implementation details
├── diagrams/             # Architecture and flow diagrams
│   └── diagrams.md       # Mermaid diagrams for HPA and PV/PVC management
└── README.md             # This file
```

## Documentation Overview

### Implementation Details

The [implementation](implementation/IMPLEMENTATION.md) documentation provides detailed explanations of:

1. **Horizontal Pod Autoscaler (HPA) Implementation**
   - Resource requests in deployment
   - HPA configuration
   - Load testing with Apache Bench
   - How the HPA works

2. **PV/PVC Management for Data Retention**
   - Persistent Volume configuration
   - PVC recreation process
   - How data retention works with the `Retain` policy

### Architecture Diagrams

The [diagrams](diagrams/diagrams.md) documentation includes Mermaid diagrams that visually represent:

1. **Horizontal Pod Autoscaler (HPA) Flow**
   - How the Metrics Server, HPA Controller, and Deployment interact
   - Scale up and scale down processes

2. **PV/PVC Management Flow**
   - The sequence of operations for PVC recreation while retaining data
   - How MongoDB detaches and reattaches to the PV

3. **System Architecture**
   - Overall system architecture showing the relationships between components
   - Frontend and database tiers

## Using the Documentation

- Start with the architecture diagrams to get a visual understanding of the system
- Then dive into the implementation details for a deeper understanding of how things work
- Refer to the specific deployment files in the `deployments/` directory to see the actual configurations
