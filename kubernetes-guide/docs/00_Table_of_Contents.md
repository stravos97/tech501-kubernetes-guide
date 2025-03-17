# Kubernetes Project: Comprehensive Guide - Table of Contents

This document provides a complete table of contents for the Kubernetes guide, with links to all sections and subsections.

## Day 1: Kubernetes Fundamentals

### [1.1 Kubernetes Concepts](day1-fundamentals/01_kubernetes_fundamentals.md)
- [Why is Kubernetes Needed?](day1-fundamentals/01_kubernetes_fundamentals.md#why-is-kubernetes-needed)
- [Benefits of Kubernetes](day1-fundamentals/01_kubernetes_fundamentals.md#benefits-of-kubernetes)
  - [Automated Scalability](day1-fundamentals/01_kubernetes_fundamentals.md#automated-scalability)
  - [Self-Healing](day1-fundamentals/01_kubernetes_fundamentals.md#self-healing)
  - [Cloud-Agnostic and Portable](day1-fundamentals/01_kubernetes_fundamentals.md#cloud-agnostic-and-portable)
  - [Efficient Resource Utilization](day1-fundamentals/01_kubernetes_fundamentals.md#efficient-resource-utilization)
  - [Extensive Ecosystem](day1-fundamentals/01_kubernetes_fundamentals.md#extensive-ecosystem)
- [Success Stories of Kubernetes Adoption](day1-fundamentals/01_kubernetes_fundamentals.md#success-stories-of-kubernetes-adoption)
- [Kubernetes Architecture: Clusters, Nodes, and Components](day1-fundamentals/01_kubernetes_fundamentals.md#kubernetes-architecture-clusters-nodes-and-components)
- [Kubernetes Objects: Pods, ReplicaSets, Deployments](day1-fundamentals/01_kubernetes_fundamentals.md#kubernetes-objects-pods-replicasets-deployments)
- [Security Considerations for Kubernetes](day1-fundamentals/01_kubernetes_fundamentals.md#security-considerations-for-kubernetes)
- [Maintained Images: What Are They and Their Pros/Cons?](day1-fundamentals/01_kubernetes_fundamentals.md#maintained-images-what-are-they-and-their-proscons)

### [1.2 Cluster Setup](day1-fundamentals/02_cluster_setup.md)
- Setting up Kubernetes with Docker Desktop
- Troubleshooting cluster startup

### [1.3 Basic Deployments](day1-fundamentals/03_basic_deployments.md)
- Nginx Deployment with NodePort Service
- Understanding Deployment YAML
- Service configuration

### [1.4 Observing Kubernetes Behaviors](day1-fundamentals/04_observing_behaviors.md)
- Pod self-healing
- Scaling replicas dynamically
- Zero downtime deployment updates
- Resource cleanup

### [1.5 Multi-tier Application Deployment](day1-fundamentals/05_nodejs_app_deployment.md)
- Deploying a Node.js application
- Setting up MongoDB
- Connecting application components
- Testing and troubleshooting

## Day 2: Persistent Storage & Scaling

### [2.1 Persistent Volumes](day2/01_Persistent_Storage.md)
- [Understanding Persistent Storage for Databases](day2/01_Persistent_Storage.md#understanding-persistent-storage-for-databases)
- [Creating a PersistentVolume](day2/01_Persistent_Storage.md#creating-a-persistentvolume)
- [Creating a PersistentVolumeClaim](day2/01_Persistent_Storage.md#creating-a-persistentvolumeclaim)
- [Modifying MongoDB Deployment to Use Persistent Storage](day2/01_Persistent_Storage.md#modifying-mongodb-deployment-to-use-persistent-storage)
- [Verifying Data Persistence](day2/01_Persistent_Storage.md#verifying-data-persistence)
- [Kubernetes PV/PVC Architecture](day2/01_Persistent_Storage.md#kubernetes-pvpvc-architecture)
- [PVC Removal While Retaining Data](day2/01_Persistent_Storage.md#pvc-removal-while-retaining-data)

### [2.2 Autoscaling Strategies](day2/02_Autoscaling.md)
- [Types of Autoscaling](day2/02_Autoscaling.md#types-of-autoscaling)
- [Implementing Horizontal Pod Autoscaler (HPA)](day2/02_Autoscaling.md#implementing-horizontal-pod-autoscaler-hpa)
  - [Prerequisite: The Metrics Server](day2/02_Autoscaling.md#prerequisite-the-metrics-server)
  - [Create an HPA YAML](day2/02_Autoscaling.md#create-an-hpa-yaml-sparta-hpayaml)
- [Testing the HPA](day2/02_Autoscaling.md#testing-the-hpa)
- [Troubleshooting HPA](day2/02_Autoscaling.md#troubleshooting-hpa)
- [Autoscaling Types Recap](day2/02_Autoscaling.md#autoscaling-types-recap)

## Day 3: Cloud Deployment & Networking

### [3.1 Minikube on Cloud VM](day3/01_Minikube_Cloud_Setup.md)
- [Minikube Setup on a Cloud Instance (Ubuntu 22.04 LTS)](day3/01_Minikube_Cloud_Setup.md#minikube-setup-on-a-cloud-instance-ubuntu-2204-lts)
- [Deploying Applications on Minikube](day3/01_Minikube_Cloud_Setup.md#deploying-applications-on-minikube)

### [3.2 Advanced Networking](day3/02_Advanced_Networking.md)
- [Configuring Nginx Reverse Proxy](day3/02_Advanced_Networking.md#configuring-nginx-reverse-proxy)
- [Testing the Setup](day3/02_Advanced_Networking.md#testing-the-setup)
- [Minikube Networking Concepts](day3/02_Advanced_Networking.md#minikube-networking-concepts)
- [Cleanup and Management](day3/02_Advanced_Networking.md#cleanup-and-management)

## Additional Documentation

### [Minikube Tunnel Guide](app3/minikube-tunnel-guide.md)
- [Overview](app3/minikube-tunnel-guide.md#overview)
- [Why Use Minikube Tunnel?](app3/minikube-tunnel-guide.md#why-use-minikube-tunnel)
- [How Minikube Tunnel Works](app3/minikube-tunnel-guide.md#how-minikube-tunnel-works)
- [Technical Implementation](app3/minikube-tunnel-guide.md#technical-implementation)
- [Usage in Our Infrastructure](app3/minikube-tunnel-guide.md#usage-in-our-infrastructure)
- [Best Practices](app3/minikube-tunnel-guide.md#best-practices)
- [Troubleshooting](app3/minikube-tunnel-guide.md#troubleshooting)
- [Alternatives to Minikube Tunnel](app3/minikube-tunnel-guide.md#alternatives-to-minikube-tunnel)

### [Manual NPM Install Process](manual-npm-install-docs.md)
- [Background](manual-npm-install-docs.md#background)
- [Why Manual Process?](manual-npm-install-docs.md#why-manual-process)
- [How to Manually Install NPM Packages](manual-npm-install-docs.md#how-to-manually-install-npm-packages)
- [Relationship with Init Containers](manual-npm-install-docs.md#relationship-with-init-containers)
- [Troubleshooting](manual-npm-install-docs.md#troubleshooting)

### [Init Container Implementation](sparta-init-container-docs.md)
- [Problem Addressed](sparta-init-container-docs.md#problem-addressed)
- [Solution Implemented](sparta-init-container-docs.md#solution-implemented)
- [Technical Details](sparta-init-container-docs.md#technical-details)
- [Benefits of This Approach](sparta-init-container-docs.md#benefits-of-this-approach)
- [Relationship with Manual NPM Install Process](sparta-init-container-docs.md#relationship-with-manual-npm-install-process)
- [Troubleshooting](sparta-init-container-docs.md#troubleshooting)

## Applications in this Project

### App1
- Simple Nginx deployment accessed via NodePort
- Located in `code/app1/`
- Demonstrates basic deployment and service concepts

### App2
- Web application using LoadBalancer service
- Located in `code/app2/`
- Demonstrates LoadBalancer service type

### App3
- Echo server that returns request information
- Located in `code/app3/`
- Demonstrates LoadBalancer with minikube tunnel

### Sparta App
- Node.js application with MongoDB backend
- Located in `code/sparta/` and `code/sparta-with-pv/`
- Demonstrates multi-tier applications and persistent storage

## References

- [Kubernetes Official Documentation](https://kubernetes.io/docs/home/)
- [Kubernetes GitHub Repository](https://github.com/kubernetes/kubernetes)
- [Kubernetes Community](https://kubernetes.io/community/)
- [CNCF Landscape](https://landscape.cncf.io/)
