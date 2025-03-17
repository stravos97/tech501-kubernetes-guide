# Kubernetes HPA and PV/PVC Management Diagrams

## Horizontal Pod Autoscaler (HPA) Flow

```mermaid
graph TD
    A[Metrics Server] -->|Collects CPU Metrics| B[HPA Controller]
    B -->|Monitors| C[Sparta Node.js Deployment]
    B -->|"CPU > 50%"| D[Scale Up]
    B -->|"CPU < 50%"| E[Scale Down]
    D -->|Increase Replicas| C
    E -->|Decrease Replicas| C
    F[Load Generator] -->|Generates Load| C
    
    subgraph "HPA Configuration"
    G[Min: 2 Replicas]
    H[Max: 10 Replicas]
    I[Target: 50% CPU]
    end
    
    subgraph "Deployment"
    J[CPU Request: 100m]
    K[Memory Request: 128Mi]
    end
```

## PV/PVC Management Flow

```mermaid
sequenceDiagram
    participant User
    participant MongoDB as MongoDB Deployment
    participant PVC as Persistent Volume Claim
    participant PV as Persistent Volume
    
    Note over PV: persistentVolumeReclaimPolicy: Retain
    
    User->>MongoDB: Scale down to 0 replicas
    MongoDB->>PVC: Detach from PVC
    User->>PVC: Delete PVC
    PVC->>PV: PV status changes to "Released"
    Note over PV: Data is retained
    User->>PVC: Create new PVC with same config
    PVC->>PV: Bind to existing PV
    User->>MongoDB: Scale up to 1 replica
    MongoDB->>PVC: Attach to new PVC
    MongoDB->>PV: Access retained data
```

## System Architecture

```mermaid
graph TD
    A[User] -->|Accesses| B[Sparta Node.js App]
    B -->|Scaled by| C[Horizontal Pod Autoscaler]
    B -->|Reads/Writes| D[MongoDB]
    D -->|Uses| E[Persistent Volume Claim]
    E -->|Bound to| F[Persistent Volume]
    
    subgraph "Frontend Tier"
    B
    C
    end
    
    subgraph "Database Tier"
    D
    E
    F
    end
    
    subgraph "Storage"
    F -->|Stores| G[MongoDB Data]
    end
```

These diagrams illustrate the key components and flows of the Horizontal Pod Autoscaler (HPA) and Persistent Volume (PV) management implementations.
