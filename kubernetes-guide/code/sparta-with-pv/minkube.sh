#!/bin/bash
# Minikube Setup for Ubuntu Cloud VM - Idempotent Version

# Exit on error
set -e

echo "Starting Minikube setup script..."

# Check if script is being run as root directly (not via sudo)
SCRIPT_USER=$(whoami)
SUDO_USER=${SUDO_USER:-$SCRIPT_USER}
IS_ROOT=false

if [ "$SCRIPT_USER" = "root" ]; then
  IS_ROOT=true
  echo "WARNING: This script is being run as root."
  echo "When running Minikube, we will use --driver=none which is appropriate for root."
fi

# Step 1: Update the system
echo "Updating system packages..."
sudo apt-get update && sudo apt-get upgrade -y

# Step 2: Install dependencies
echo "Installing dependencies..."
sudo apt-get install -y curl wget apt-transport-https

# Step 3: Install Docker (required for Minikube)
if ! command -v docker &> /dev/null; then
  echo "Installing Docker..."
  sudo apt-get install -y docker.io
else
  echo "Docker is already installed."
fi

# Check if Docker service is running
if ! systemctl is-active --quiet docker; then
  echo "Starting Docker service..."
  sudo systemctl start docker
fi

# Enable Docker service
if ! systemctl is-enabled --quiet docker; then
  echo "Enabling Docker service..."
  sudo systemctl enable docker
fi

# Add user to docker group if not already a member
if [ "$IS_ROOT" = false ]; then
  if ! groups $USER | grep -q '\bdocker\b'; then
    echo "Adding user $USER to the docker group..."
    sudo usermod -aG docker $USER
    echo "Refreshing group membership..."
    exec sg docker -c "$0 $*"  # Restart script with new group permissions
  else
    echo "User $USER is already in the docker group."
  fi
fi

# Step 4: Install kubectl
if ! command -v kubectl &> /dev/null; then
  echo "Installing kubectl..."
  # Clean up any previous incomplete downloads
  rm -f kubectl
  
  # Download and install kubectl
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" || {
    echo "Failed to download kubectl. Please check your internet connection."
    exit 1
  }
  
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
else
  echo "kubectl is already installed."
fi

# Display kubectl version
echo "kubectl version:"
kubectl version --client

# Step 5: Install Minikube
if ! command -v minikube &> /dev/null; then
  echo "Installing Minikube..."
  # Clean up any previous incomplete downloads
  rm -f minikube-linux-amd64
  
  # Download and install Minikube
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 || {
    echo "Failed to download Minikube. Please check your internet connection."
    exit 1
  }
  
  sudo install minikube-linux-amd64 /usr/local/bin/minikube
  rm -f minikube-linux-amd64  # Clean up the downloaded file
else
  echo "Minikube is already installed."
fi

# Step 6: Start Minikube if not already running
if ! (minikube status &>/dev/null) || ! (minikube status | grep -q "host: Running"); then
  # Calculate memory allocation with minimum threshold
  TOTAL_MEM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  TOTAL_MEM_MB=$((TOTAL_MEM_KB / 1024))
  SAFE_MEM_MB=$((TOTAL_MEM_MB * 80 / 100))
  MIN_MEM_MB=1800 # Minimum required by Minikube
  
  # Use minimum required memory or 80% of system memory, whichever is higher
  if [ $SAFE_MEM_MB -lt $MIN_MEM_MB ]; then
    if [ $TOTAL_MEM_MB -lt $MIN_MEM_MB ]; then
      echo "Warning: System has only ${TOTAL_MEM_MB}MB total memory."
      echo "Minikube requires at least ${MIN_MEM_MB}MB."
      echo "Will attempt to start with all available memory, but you may experience instability."
      MEM_OPTION="--memory=${TOTAL_MEM_MB}mb"
    else
      echo "System has ${TOTAL_MEM_MB}MB total memory. Using minimum required ${MIN_MEM_MB}MB for Minikube."
      MEM_OPTION="--memory=${MIN_MEM_MB}mb"
    fi
  else
    echo "System has ${TOTAL_MEM_MB}MB total memory. Will allocate ${SAFE_MEM_MB}MB to Minikube."
    MEM_OPTION="--memory=${SAFE_MEM_MB}mb"
  fi
  
  if [ "$IS_ROOT" = true ]; then
    echo "Starting Minikube with 'none' driver (root user)..."
    minikube start --driver=none || {
      echo "Failed to start Minikube. Please check the output for errors."
      exit 1
    }
  else
    echo "Starting Minikube with Docker driver..."
    # Check if docker socket is accessible
    if ! docker info &>/dev/null; then
      echo "ERROR: Cannot connect to the Docker daemon."
      echo ""
      echo "This usually means your Docker permissions aren't applied to the current session."
      echo "Try ONE of these solutions:"
      echo ""
      echo "OPTION 1: Run this in your terminal, then run the script again:"
      echo "    newgrp docker"
      echo ""
      echo "OPTION 2: Log out completely and log back in, then run the script"
      echo ""
      echo "OPTION 3: Run the script with --force-docker-connect to attempt a direct connection"
      echo ""
      
      # Check if force flag is provided
      if [[ "$*" == *"--force-docker-connect"* ]]; then
        echo "Attempting to force docker connection..."
        sg docker -c "minikube start --driver=docker $MEM_OPTION" || {
          echo "Failed to start Minikube even with sg docker. Please log out and log back in."
          exit 1
        }
      else
        exit 1
      fi
    else    
      minikube start --driver=docker $MEM_OPTION || {
        echo "Failed to start Minikube. Please check the output for errors."
        exit 1
      }
    fi
  fi
else
  echo "Minikube is already running."
fi

# Step 7: Verify installation
echo "Minikube status:"
minikube status

# Step 8: Basic commands
echo ""
echo "Basic Minikube commands:"
echo "- Check status: minikube status"
echo "- Stop cluster: minikube stop"
echo "- Delete cluster: minikube delete"
echo "- Kubernetes dashboard: minikube dashboard"

# Step 9: Configure kubectl to use Minikube (idempotent by default)
echo ""
echo "Configuring kubectl to use Minikube:"
kubectl config use-context minikube
kubectl get nodes

echo ""
echo "Minikube setup completed successfully."