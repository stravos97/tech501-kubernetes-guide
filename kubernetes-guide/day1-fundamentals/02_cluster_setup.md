# Cluster Setup

## Table of Contents
- [Cluster Setup](#cluster-setup)
  - [Table of Contents](#table-of-contents)
  - [Getting Kubernetes Running Using Docker Desktop](#getting-kubernetes-running-using-docker-desktop)
    - [Steps to Enable Kubernetes in Docker Desktop](#steps-to-enable-kubernetes-in-docker-desktop)
    - [Troubleshooting Kubernetes Startup in Docker Desktop](#troubleshooting-kubernetes-startup-in-docker-desktop)
  - [References](#references)

## Getting Kubernetes Running Using Docker Desktop

One of the simplest ways to set up a local single-node Kubernetes cluster is by using Docker Desktop. Docker Desktop includes an option to enable a Kubernetes cluster integrated with your Docker runtime. This is great for development and testing purposes.

### Steps to Enable Kubernetes in Docker Desktop

1. **Install Docker Desktop** (if not already installed) for your OS. Ensure it's updated to a recent version. Docker Desktop comes with Kubernetes support on Windows and Mac (and on Windows it uses WSL2 backend).

2. **Enable Kubernetes**: 
   - Open Docker Desktop's settings/preferences
   - Navigate to the "Kubernetes" section 
   - Check the option "Enable Kubernetes"
   - Docker will start installing and configuring a single-node Kubernetes cluster internally
   - On enabling, Docker might prompt to reset the Kubernetes cluster if it was enabled before. Accept and wait a few minutes

3. **Configure kubectl**:
   - Docker Desktop installs the kubectl command-line tool (or you can install it separately) and merges the Kubernetes context automatically
   - Ensure your kubeconfig context is set to Docker Desktop's cluster. You can check by running:
   
   ```bash
   kubectl config get-contexts
   kubectl config use-context docker-desktop
   ```
   
   - The context name `docker-desktop` is typically configured for you when enabling Kubernetes in Docker Desktop

4. **Verify the cluster is running**:
   - Run a simple command like:
   
   ```bash
   kubectl get nodes
   ```
   
   - You should see one node (often named docker-desktop) in the Ready state
   - Also try:
   
   ```bash
   kubectl get services
   ```
   
   - By default, you'll see the kubernetes Service in the default namespace (an internal cluster IP for the API server)

If everything is correct, you now have a functioning Kubernetes cluster. Docker Desktop's Kubernetes is a single-node cluster, meaning the control plane and worker roles are all on the one Docker VM.

### Troubleshooting Kubernetes Startup in Docker Desktop

- **Stuck in "starting" state**: If Kubernetes does not start (e.g., it's stuck in "starting" state for a long time), try restarting Docker Desktop. Sometimes resetting the Kubernetes cluster (via the Docker Desktop GUI -> Kubernetes -> "Reset cluster") can resolve issues if the state is corrupted.

- **Insufficient resources**: Ensure your Docker resources (CPU/memory) are sufficient. Docker Desktop settings allow you to allocate resources. Kubernetes in Docker needs at least ~2 CPUs and 2GB RAM to function smoothly [1]. If it's been given too little memory, it might not schedule the internal pods.

- **WSL2 issues on Windows**: If using WSL2, make sure the Kubernetes context is pointing to the Docker Desktop's Kubernetes and not trying to use some other context. Also, check that WSL2 has the needed updates (Docker's documentation lists some specific Windows version requirements).

- **Connection issues**: If kubectl commands hang or refuse to connect, check that Docker Desktop's Kubernetes is showing as running. It may help to run `docker info` and see if Kubernetes is enabled.

- **Image pull problems**: Sometimes you might encounter image pull issues (e.g., the internal "pause" image can't be fetched due to network). Ensure that Docker can pull images from the internet. If you are behind a proxy, configure Docker's proxy settings so Kubernetes can pull required images.

- **Firewall restrictions**: On Windows, the Kubernetes cluster network might be blocked by local firewall. Typically, Docker handles this, but if you have third-party firewall software, ensure the Docker VM's network connections are allowed.

- **Version compatibility**: The kubectl CLI gets configured automatically by Docker Desktop. If you have a separate kubectl installed, ensure it's the same version range as the Kubernetes server (Docker Desktop often uses a specific Kubernetes version). You can always check versions with `kubectl version --short`. In general, minor version skew of +1/-1 is supported by kubectl.

Once you have `kubectl get nodes` showing the node, you are ready to deploy applications on this local cluster.

## References

[1] Kubernetes.io. "Minikube Requirements." [https://minikube.sigs.k8s.io/docs/start/](https://minikube.sigs.k8s.io/docs/start/)
