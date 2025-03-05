# Load Testing for HPA

This directory contains configuration files and scripts for load testing the Sparta Node.js application to demonstrate the Horizontal Pod Autoscaler (HPA) functionality.

## Files

- `load-test.yml`: Configuration for one-time and continuous load testing
- `test-scripts.sh`: Interactive shell script for running tests and monitoring results

## Load Testing Options

### One-time Apache Bench Test (Job)

The `load-test.yml` file includes a Kubernetes Job configuration that runs Apache Bench to generate a one-time load test:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: load-generator-job
spec:
  template:
    metadata:
      labels:
        app: load-generator
    spec:
      containers:
      - name: load-generator
        image: devth/alpine-bench
        args:
        - "-n"  # Number of requests
        - "1000"
        - "-c"  # Concurrency
        - "20"
        - "http://sparta-node-service:3000"
      restartPolicy: Never
  backoffLimit: 1
```

### Continuous Load Generator (Deployment)

The `load-test.yml` file also includes a Deployment configuration for continuous load testing:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: continuous-load-generator
spec:
  replicas: 3
  selector:
    matchLabels:
      app: continuous-load-generator
  template:
    metadata:
      labels:
        app: continuous-load-generator
    spec:
      containers:
      - name: load-generator
        image: busybox
        command: ["/bin/sh", "-c"]
        args:
        - while true; do
            wget -q -O- http://sparta-node-service:3000;
            sleep 0.01;
          done
```

## Interactive Test Script

The `test-scripts.sh` file provides an interactive way to run the load tests and monitor the results. It includes:

- Options for running one-time or continuous load tests
- Monitoring of HPA status
- Verification of metrics-server installation
- Detailed output of test results

## Usage

### Using the Load Test YAML

To run a one-time Apache Bench test:

```bash
kubectl apply -f load-test.yml
kubectl logs job/load-generator-job
```

To run a continuous load test:

```bash
kubectl apply -f load-test.yml
kubectl logs -f deployment/continuous-load-generator
```

To monitor the HPA during the test:

```bash
kubectl get hpa sparta-node-hpa -w
```

### Using the Test Script

The test script provides an interactive interface for running the tests:

```bash
./test-scripts.sh
```

Then select option 1 to test the HPA, and choose between one-time or continuous load testing.

## Notes

- The HPA requires the metrics-server to be running in the cluster
- The continuous load generator creates 3 replicas to generate sufficient load
- The test script checks for the presence of the metrics-server and provides installation instructions if it's not found
