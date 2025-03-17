# Metrics Server

This directory contains Kubernetes Metrics Server configuration files.

## Files

- `metrics-server.yaml`: Standard metrics server deployment configuration
- `metrics-server-fixed.yaml`: Modified metrics server configuration with the `--kubelet-insecure-tls` flag added

## Differences

The main difference between the two files is that `metrics-server-fixed.yaml` includes the `--kubelet-insecure-tls` argument, which is often needed in development environments (like Minikube) to bypass TLS verification issues.

```diff
  args:
  - --cert-dir=/tmp
  - --secure-port=10250
  - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
  - --kubelet-use-node-status-port
  - --metric-resolution=15s
+ - --kubelet-insecure-tls
```

## Usage

For production environments, use the standard configuration:

```bash
kubectl apply -f metrics-server.yaml
```

For development environments or when experiencing TLS issues, use the fixed version:

```bash
kubectl apply -f metrics-server-fixed.yaml
```

## Notes

The Metrics Server is required for the Horizontal Pod Autoscaler (HPA) to function properly, as it provides the CPU and memory metrics that the HPA uses to make scaling decisions.
