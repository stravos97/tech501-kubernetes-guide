# Kubernetes Architecture and Deployment Diagrams

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

## Complete System Architecture

```mermaid
graph TD
    A[User] -->|Accesses| N[Nginx Reverse Proxy]
    N -->|Routes to| B[Sparta Node.js App]
    N -->|Routes to| APP2[App2]
    N -->|Routes to /hello| APP3[App3 Hello-Minikube]
    
    B -->|Scaled by| C[Horizontal Pod Autoscaler]
    B -->|Reads/Writes| D[MongoDB]
    D -->|Uses| E[Persistent Volume Claim]
    E -->|Bound to| F[Persistent Volume]
    
    APP3 -->|Exposed via| LB[LoadBalancer Service]
    LB -->|Enabled by| MT[Minikube Tunnel]
    
    subgraph "Frontend Tier"
    N
    B
    APP2
    APP3
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
    
    subgraph "Networking"
    LB
    MT
    end
```

## Deployment Workflow with Manual NPM Install

```mermaid
sequenceDiagram
    participant User
    participant Script as Deployment Script
    participant K8s as Kubernetes
    participant DB as MongoDB Pod
    participant App as Sparta App Pod
    participant Manual as Manual Process
    
    User->>Script: Run deploy-sparta.sh
    Script->>K8s: Apply PV and PVC
    Script->>K8s: Deploy MongoDB
    K8s->>DB: Create and start MongoDB pod
    Script->>K8s: Wait for MongoDB readiness
    Note over DB: MongoDB ready
    
    Script->>K8s: Deploy Sparta app
    K8s->>App: Create app pod
    Note over App: Init container runs
    App->>DB: Check MongoDB connectivity
    Note over App: Main container starts
    Script->>K8s: Wait for app readiness
    
    Script->>User: Prompt for manual npm install
    User->>Manual: Run connect-to-sparta.sh
    Manual->>App: Connect to pod
    Manual->>App: Run npm install
    Manual->>App: Run database seeding
    Manual->>App: Exit pod
    
    User->>K8s: Apply HPA
    K8s->>App: Configure auto-scaling
    
    Note over App: Application fully operational
```

## Recovery Process After Server Restart

```mermaid
graph TD
    A[Server Restart] -->|Triggers| B[Minikube Auto-Start]
    B -->|Starts| C[Kubernetes Cluster]
    C -->|Recovers| D[Persistent Volumes]
    
    D -->|Reattaches to| E[MongoDB Pod]
    E -->|Contains| F[Preserved Data]
    
    C -->|Restarts| G[Sparta App Pods]
    G -->|Wait for| E
    
    H[Manual Process] -->|Connects to| G
    H -->|Runs| I[npm install]
    H -->|Runs| J[Database Seeding]
    
    K[Minikube Tunnel] -->|Enables| L[LoadBalancer Services]
    L -->|Exposes| M[App3 Service]
    
    N[Nginx] -->|Routes to| G
    N -->|Routes to| M
    N -->|Routes to| O[App2 Pods]
```

These diagrams illustrate the key components and flows of the complete Kubernetes setup, including the Horizontal Pod Autoscaler (HPA), Persistent Volume (PV) management, manual npm install process, and the overall system architecture with all applications.
