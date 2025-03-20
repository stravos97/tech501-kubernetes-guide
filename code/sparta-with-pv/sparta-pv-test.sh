#!/bin/bash

# This script contains commands for testing the HPA and PV/PVC management

# Function to display a header
function header() {
  echo "============================================"
  echo "$1"
  echo "============================================"
}

# Function to pause and wait for user input
function pause() {
  read -p "Press Enter to continue..."
}

# Test HPA functionality
function test_hpa() {
  header "Testing Horizontal Pod Autoscaler (HPA)"
  
  echo "1. Applying the deployment with resource requests..."
  kubectl apply -f sparta-deploy.yml
  
  echo "2. Applying the HPA configuration..."
  kubectl apply -f sparta-hpa.yml
  
  echo "3. Checking initial HPA status..."
  kubectl get hpa sparta-node-hpa
  
  echo "4. Checking initial pod count..."
  kubectl get pods -l app=sparta-node
  
  pause
  
  echo "5. Choose load testing method:"
  echo "   a) Run one-time Apache Bench test (Job)"
  echo "   b) Run continuous load generator (Deployment)"
  read -p "   Enter choice (a/b): " load_choice
  
  if [ "$load_choice" = "a" ]; then
    echo "Running one-time Apache Bench test..."
    # Clean up any existing job first to avoid immutable field errors
    kubectl delete job load-generator-job 2>/dev/null || true
    
    kubectl apply -f load-test.yml
    echo "Waiting for job to complete..."
    kubectl wait --for=condition=complete job/load-generator-job --timeout=60s || echo "Job still running, continuing..."
    
    echo "Apache Bench results:"
    kubectl logs job/load-generator-job
    
    # Clean up the job
    echo "Cleaning up the job..."
    kubectl delete job load-generator-job
  else
    echo "Running continuous load generator..."
    # Clean up any existing deployment first
    kubectl delete deployment continuous-load-generator 2>/dev/null || true
    
    kubectl apply -f load-test.yml
    echo "Continuous load generator deployed with 3 replicas for higher load."
    echo "Use this command to see logs:"
    echo "kubectl logs -f deployment/continuous-load-generator"
    
    # Check if metrics-server is running in different namespaces
    echo "Checking if metrics-server is installed..."
    if kubectl get deployment metrics-server -n kube-system 2>/dev/null; then
      echo "metrics-server found in kube-system namespace."
    elif kubectl get deployment metrics-server -n default 2>/dev/null; then
      echo "metrics-server found in default namespace."
    else
      echo "metrics-server not found. You need to install it for HPA to work properly."
      echo "Installation options:"
      echo "1. If you're using Minikube, enable metrics-server with:"
      echo "   minikube addons enable metrics-server"
      echo "2. For other Kubernetes distributions, install with:"
      echo "   kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"
    fi
    
    # Check if HPA can access metrics
    echo "Checking if HPA can access metrics (this may take a minute)..."
    sleep 10
    kubectl get hpa sparta-node-hpa
  fi
  
  echo "6. Monitoring HPA status (press Ctrl+C to stop watching)..."
  kubectl get hpa sparta-node-hpa -w
}

# Test PV/PVC management
function test_pv_pvc() {
  header "Testing PV/PVC Management with Data Retention"
  
  # Check if PV and PVC exist
  echo "Checking if PV and PVC exist..."
  if ! kubectl get pv sparta-db-pv &>/dev/null; then
    echo "Creating PV and PVC..."
    kubectl apply -f pv.yml
    sleep 2
  else
    echo "PV sparta-db-pv already exists."
  fi
  
  if ! kubectl get pvc sparta-db-pvc &>/dev/null; then
    echo "Creating PVC..."
    kubectl apply -f pv.yml
    sleep 2
  else
    echo "PVC sparta-db-pvc already exists."
  fi
  
  # Check if MongoDB deployment exists
  if ! kubectl get deployment sparta-db-deployment &>/dev/null; then
    echo "Creating MongoDB deployment..."
    kubectl apply -f sparta-deploy.yml
    echo "Waiting for MongoDB pod to be ready..."
    kubectl wait --for=condition=ready pod -l app=sparta-db --timeout=120s || echo "Timeout waiting for MongoDB pod"
  fi
  
  echo "1. Creating some test data in MongoDB..."
  POD_NAME=$(kubectl get pods -l app=sparta-db -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  
  if [ -z "$POD_NAME" ]; then
    echo "Error: No MongoDB pod found. Make sure the deployment is running."
    echo "You can check the status with: kubectl get pods -l app=sparta-db"
    pause
    return
  fi
  
  echo "Pod name: $POD_NAME"
  echo "You can manually create test data using:"
  echo "kubectl exec -it $POD_NAME -- mongo"
  echo "Then in the mongo shell:"
  echo "use posts"
  echo "db.posts.insert({title: 'Test Post', body: 'This is a test post'})"
  echo "db.posts.find()"
  
  # Optionally create test data automatically
  echo "Would you like to automatically create test data? (y/n)"
  read -p "Enter choice: " create_data
  
  if [ "$create_data" = "y" ]; then
    echo "Creating test data automatically..."
    kubectl exec -it $POD_NAME -- mongosh --eval "use posts; db.posts.insert({title: \"Test Post\", body: \"This is a test post created at $(date)\"}); db.posts.find();"
  fi
  
  pause
  
  echo "2. Scaling down the MongoDB deployment..."
  kubectl scale deployment sparta-db-deployment --replicas=0
  
  echo "3. Waiting for pod to terminate..."
  kubectl wait --for=delete pod -l app=sparta-db --timeout=60s || echo "Timeout waiting for pod to terminate"
  
  echo "4. Deleting the PVC..."
  kubectl delete pvc sparta-db-pvc
  
  echo "5. Verifying the PV still exists and checking its status..."
  kubectl get pv sparta-db-pv -o wide
  
  # Check PV status
  PV_STATUS=$(kubectl get pv sparta-db-pv -o jsonpath='{.status.phase}')
  echo "PV status: $PV_STATUS"
  if [ "$PV_STATUS" = "Released" ]; then
    echo "PV is in Released state as expected. Data is retained."
  else
    echo "Warning: PV is not in Released state. This may indicate an issue with the reclaim policy."
  fi
  
  pause
  
  echo "6. Recreating the PVC with the same configuration..."
  kubectl apply -f pvc-recreate.yml
  
  echo "7. Scaling up the MongoDB deployment..."
  kubectl scale deployment sparta-db-deployment --replicas=1
  
  echo "8. Waiting for pod to be ready..."
  kubectl wait --for=condition=ready pod -l app=sparta-db --timeout=60s || echo "Timeout waiting for pod to be ready"
  
  echo "9. Verifying the data is still accessible..."
  NEW_POD_NAME=$(kubectl get pods -l app=sparta-db -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  
  if [ -z "$NEW_POD_NAME" ]; then
    echo "Error: No MongoDB pod found after scaling up. Check for errors with:"
    echo "kubectl get pods -l app=sparta-db"
    echo "kubectl describe pod -l app=sparta-db"
    pause
    return
  fi
  
  echo "New pod name: $NEW_POD_NAME"
  echo "You can manually verify the data using:"
  echo "kubectl exec -it $NEW_POD_NAME -- mongosh"
  echo "Then in the mongo shell:"
  echo "use posts"
  echo "db.posts.find()"
  
  # Optionally verify data automatically
  echo "Would you like to automatically verify the data? (y/n)"
  read -p "Enter choice: " verify_data
  
  if [ "$verify_data" = "y" ]; then
    echo "Verifying data automatically..."
    kubectl exec -it $NEW_POD_NAME -- mongosh --eval "use posts; db.posts.find();"
  fi
}

# Main menu
function main_menu() {
  clear
  header "Kubernetes HPA and PV/PVC Management Test Scripts"
  
  echo "1. Test Horizontal Pod Autoscaler (HPA)"
  echo "2. Test PV/PVC Management with Data Retention"
  echo "3. Exit"
  
  read -p "Enter your choice (1-3): " choice
  
  case $choice in
    1) test_hpa ;;
    2) test_pv_pvc ;;
    3) exit 0 ;;
    *) echo "Invalid choice. Please try again." ;;
  esac
  
  pause
  main_menu
}

# Start the script
main_menu
