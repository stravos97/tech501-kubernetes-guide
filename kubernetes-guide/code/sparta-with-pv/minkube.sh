#!/bin/bash
# Minikube Setup for Ubuntu Cloud VM

# Step 1: Update the system
sudo apt-get update && sudo apt-get upgrade -y

# Step 2: Install dependencies
sudo apt-get install -y curl wget apt-transport-https virtualbox virtualbox-ext-pack

# Step 3: Install Docker (alternative to VirtualBox)
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
# Note: You may need to log out and log back in for group changes to take effect

# Step 4: Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client

# Step 5: Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Step 6: Start Minikube
# Using Docker driver (recommended for cloud VMs)
minikube start --driver=docker

# Alternative: Start with VirtualBox driver
# minikube start --driver=virtualbox

# Step 7: Verify installation
minikube status

# Step 8: Basic commands
echo "Basic Minikube commands:"
echo "- Check status: minikube status"
echo "- Stop cluster: minikube stop"
echo "- Delete cluster: minikube delete"
echo "- Kubernetes dashboard: minikube dashboard"

# Step 9: Configure kubectl to use Minikube
kubectl config use-context minikube
kubectl get nodes