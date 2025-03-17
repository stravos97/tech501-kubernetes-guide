# Kubernetes Project: Comprehensive Guide

## Introduction

This guide provides a structured walkthrough of Kubernetes fundamentals and advanced features across three days. It is designed to take you from basic concepts to advanced deployments with hands-on exercises and detailed explanations.

## Prerequisites

- Basic understanding of containerization concepts
- Docker installed on your local machine
- Basic command-line knowledge
- A text editor for YAML file creation

## Table of Contents

### Day 1: Kubernetes Fundamentals
1. [Kubernetes Concepts](day1-fundamentals/01_kubernetes_fundamentals.md)
   - Why Kubernetes is needed
   - Benefits of Kubernetes
   - Success stories
   - Architecture: clusters, nodes, and components
   - Kubernetes objects: Pods, ReplicaSets, Deployments
   - Security considerations
   
2. [Cluster Setup](day1-fundamentals/02_cluster_setup.md)
   - Setting up Kubernetes with Docker Desktop
   - Troubleshooting cluster startup
   
3. [Basic Deployments](day1-fundamentals/03_basic_deployments.md)
   - Nginx Deployment with NodePort Service
   - Understanding Deployment YAML
   - Service configuration
   
4. [Observing Kubernetes Behaviors](day1-fundamentals/04_observing_behaviors.md)
   - Pod self-healing
   - Scaling replicas dynamically
   - Zero downtime deployment updates
   - Resource cleanup
   
5. [Multi-tier Application Deployment](day1-fundamentals/05_nodejs_app_deployment.md)
   - Deploying a Node.js application
   - Setting up MongoDB
   - Connecting application components
   - Testing and troubleshooting

### Day 2: Persistent Storage & Scaling
1. [Persistent Volumes](day2/01_Persistent_Storage.md)
   - Understanding storage in Kubernetes
   - PersistentVolumes and PersistentVolumeClaims
   - Storage Classes
   - Stateful applications

2. [Autoscaling Strategies](day2/02_Autoscaling.md)
   - Horizontal Pod Autoscaling
   - Vertical Pod Autoscaling
   - Cluster Autoscaling
   - Resource metrics and custom metrics

### Day 3: Cloud Deployment & Networking
1. [Minikube on Cloud VM](day3/01_Minikube_Cloud_Setup.md)
   - Setting up a cloud VM
   - Installing Minikube and dependencies
   - Deploying applications on Minikube
   - Managing cloud resources

2. [Advanced Networking](day3/02_Advanced_Networking.md)
   - Configuring Nginx reverse proxy
   - Kubernetes networking concepts
   - LoadBalancer and NodePort services
   - Automating cluster startup

## Architecture Overview

```mermaid
graph TD
  ControlPlane[Control Plane]
  Etcd[Etcd KU datastore]
  APIServer[API Server]
  Controller[Controller Manager]
  Scheduler[Scheduler]
  WorkerNodes[Worker Nodes]
  Docker_Engine[Docker Engine]
  Kubelet[Kubelet]
  KubeProxy[Kube-Proxy]
  ControlPlane -->|Contains| Etcd
  ControlPlane -->|Contains| APIServer
  ControlPlane -->|Contains| Controller
  ControlPlane -->|Contains| Scheduler
  WorkerNodes -->|Run| Kubelet
  WorkerNodes -->|Run| Docker_Engine
  WorkerNodes -->|Run| KubeProxy
```

*The diagram above shows the key components of a Kubernetes cluster, including the Control Plane (which manages the cluster) and Worker Nodes (which run the containerized applications).*

## What You'll Learn

This guide includes:
- Detailed technical explanations of Kubernetes concepts
- Production-grade YAML manifests with explanations
- Hands-on exercises with step-by-step instructions
- Troubleshooting tips for common issues
- Best practices for security and deployment
- Architectural insights for scalable applications
