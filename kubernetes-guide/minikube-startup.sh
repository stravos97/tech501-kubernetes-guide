#!/bin/bash
# Script to ensure Minikube starts automatically on VM restart

# Exit on error
set -e

echo "Setting up Minikube auto-start..."

# Create systemd service file for Minikube
sudo bash -c "cat > /etc/systemd/system/minikube.service << EOF
[Unit]
Description=Minikube Kubernetes Cluster
After=docker.service network.target
Requires=docker.service

[Service]
Type=oneshot
User=ubuntu
ExecStart=/usr/local/bin/minikube start
RemainAfterExit=true
ExecStop=/usr/local/bin/minikube stop

[Install]
WantedBy=multi-user.target
EOF"

# Reload systemd, enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable minikube.service

echo "Minikube auto-start has been configured."
echo "The service will start Minikube automatically on system boot."
echo "You can manually control it with:"
echo "  sudo systemctl start minikube.service"
echo "  sudo systemctl stop minikube.service"
echo "  sudo systemctl status minikube.service"
