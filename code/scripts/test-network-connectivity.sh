#!/bin/bash

# Test script to check connectivity to app2-service on port 9000
# with and without minikube tunnel

# Source configuration
source ../config/config.env
VM_IP="${REMOTE_SERVER_IP}"

echo "===================================================="
echo "TESTING APP2-SERVICE CONNECTIVITY (PORT 9000)"
echo "===================================================="

# Test connectivity to app2-service without minikube tunnel
echo -e "\n===== TESTING WITHOUT MINIKUBE TUNNEL ====="

# Stop any existing tunnel
echo "Stopping any existing minikube tunnel..."
ssh ${REMOTE_USER}@$VM_IP "pkill -f 'minikube tunnel' || true"
sleep 3

# Get service information
echo -e "\nService information without tunnel:"
ssh ${REMOTE_USER}@$VM_IP "kubectl get service app2-service -o wide"

# Get minikube IP
MINIKUBE_IP=$(ssh ${REMOTE_USER}@$VM_IP "minikube ip")
echo -e "\nMinikube IP: $MINIKUBE_IP"

# Try direct NodePort access
echo -e "\nTesting NodePort access (port 30002)..."
NODE_PORT_STATUS=$(ssh ${REMOTE_USER}@$VM_IP "curl -s -o /dev/null -w '%{http_code}' http://$MINIKUBE_IP:30002 || echo 'Failed'")
if [[ "$NODE_PORT_STATUS" == "200" ]]; then
    echo "✅ NodePort access successful (HTTP $NODE_PORT_STATUS)"
else
    echo "❌ NodePort access failed (Result: $NODE_PORT_STATUS)"
fi

# Try LoadBalancer access
echo -e "\nTesting LoadBalancer access (port 9000)..."
LB_IP=$(ssh ${REMOTE_USER}@$VM_IP "kubectl get service app2-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo ''")

if [[ -z "$LB_IP" ]]; then
    echo "❌ No LoadBalancer IP assigned (expected without tunnel)"
    LB_STATUS="Failed (No IP)"
else
    LB_STATUS=$(ssh ${REMOTE_USER}@$VM_IP "curl -s -o /dev/null -w '%{http_code}' http://$LB_IP:9000 || echo 'Failed'")
    if [[ "$LB_STATUS" == "200" ]]; then
        echo "✅ LoadBalancer access successful (HTTP $LB_STATUS) - This is unexpected without tunnel!"
    else
        echo "❌ LoadBalancer access failed (Result: $LB_STATUS) - This is expected without tunnel"
    fi
fi

# Try public access to the service via nginx
echo -e "\nTesting public access via nginx (port 9000) WITHOUT tunnel..."
PUBLIC_STATUS_NO_TUNNEL=$(curl -s -o /dev/null -w '%{http_code}' http://$VM_IP:9000 2>/dev/null || echo 'Failed')
if [[ "$PUBLIC_STATUS_NO_TUNNEL" == "200" ]]; then
    echo "✅ Public access successful (HTTP $PUBLIC_STATUS_NO_TUNNEL) - This is unexpected without tunnel!"
else
    echo "❌ Public access failed (Result: $PUBLIC_STATUS_NO_TUNNEL) - This is expected without tunnel"
fi

# Try ClusterIP access
echo -e "\nTesting ClusterIP access..."
CLUSTER_IP=$(ssh ${REMOTE_USER}@$VM_IP "kubectl get service app2-service -o jsonpath='{.spec.clusterIP}'")
echo "ClusterIP: $CLUSTER_IP"
CLUSTER_IP_STATUS=$(ssh ${REMOTE_USER}@$VM_IP "curl -s -o /dev/null -w '%{http_code}' http://$CLUSTER_IP:9000 || echo 'Failed'")
if [[ "$CLUSTER_IP_STATUS" == "200" ]]; then
    echo "✅ ClusterIP access successful (HTTP $CLUSTER_IP_STATUS)"
else
    echo "❌ ClusterIP access failed (Result: $CLUSTER_IP_STATUS)"
fi

# Now test with minikube tunnel
echo -e "\n===== TESTING WITH MINIKUBE TUNNEL ====="

# Start minikube tunnel
echo "Starting minikube tunnel..."
ssh ${REMOTE_USER}@$VM_IP "nohup minikube tunnel > minikube_tunnel.log 2>&1 &"
echo "Waiting for tunnel to initialize..."
sleep 10

# Get service information again
echo -e "\nService information with tunnel running:"
ssh ${REMOTE_USER}@$VM_IP "kubectl get service app2-service -o wide"

# Try LoadBalancer access again
echo -e "\nTesting LoadBalancer access with tunnel (port 9000)..."
LB_IP=$(ssh ${REMOTE_USER}@$VM_IP "kubectl get service app2-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo ''")

if [[ -z "$LB_IP" ]]; then
    echo "❌ No LoadBalancer IP assigned (unexpected with tunnel)"
    LB_STATUS="Failed (No IP)"
else
    echo "LoadBalancer IP: $LB_IP"
    LB_STATUS=$(ssh ${REMOTE_USER}@$VM_IP "curl -s -o /dev/null -w '%{http_code}' http://$LB_IP:9000 || echo 'Failed'")
    if [[ "$LB_STATUS" == "200" ]]; then
        echo "✅ LoadBalancer access successful (HTTP $LB_STATUS) - This is expected with tunnel"
    else
        echo "❌ LoadBalancer access failed (Result: $LB_STATUS) - This is unexpected with tunnel"
    fi
fi

# Try NodePort access again (should still work)
echo -e "\nTesting NodePort access with tunnel (port 30002)..."
NODE_PORT_STATUS=$(ssh ${REMOTE_USER}@$VM_IP "curl -s -o /dev/null -w '%{http_code}' http://$MINIKUBE_IP:30002 || echo 'Failed'")
if [[ "$NODE_PORT_STATUS" == "200" ]]; then
    echo "✅ NodePort access successful (HTTP $NODE_PORT_STATUS)"
else
    echo "❌ NodePort access failed (Result: $NODE_PORT_STATUS)"
fi

# Try ClusterIP access again
echo -e "\nTesting ClusterIP access with tunnel..."
CLUSTER_IP_STATUS=$(ssh ${REMOTE_USER}@$VM_IP "curl -s -o /dev/null -w '%{http_code}' http://$CLUSTER_IP:9000 || echo 'Failed'")
if [[ "$CLUSTER_IP_STATUS" == "200" ]]; then
    echo "✅ ClusterIP access successful (HTTP $CLUSTER_IP_STATUS)"
else
    echo "❌ ClusterIP access failed (Result: $CLUSTER_IP_STATUS)"
fi

# Check if we can access the LoadBalancer from the VM's public IP
echo -e "\nTesting public access to LoadBalancer via VM's nginx WITH tunnel..."
PUBLIC_STATUS=$(curl -s -o /dev/null -w '%{http_code}' http://$VM_IP:9000 2>/dev/null || echo 'Failed')
if [[ "$PUBLIC_STATUS" == "200" ]]; then
    echo "✅ Public access successful (HTTP $PUBLIC_STATUS) - This is expected with tunnel"
else
    echo "❌ Public access failed (Result: $PUBLIC_STATUS) - This is unexpected with tunnel"
fi

# Clean up - stop tunnel
echo -e "\n===== CLEANING UP ====="
echo "Stopping minikube tunnel..."
ssh ${REMOTE_USER}@$VM_IP "pkill -f 'minikube tunnel' || true"

echo -e "\n===================================================="
echo "TEST SUMMARY"
echo "===================================================="
echo "WITHOUT TUNNEL:"
echo "  - NodePort (30002): $NODE_PORT_STATUS"
echo "  - LoadBalancer (9000): $LB_STATUS"
echo "  - ClusterIP: $CLUSTER_IP_STATUS"
echo "  - Public Access (VM:9000): $PUBLIC_STATUS_NO_TUNNEL"
echo "WITH TUNNEL:"
echo "  - NodePort (30002): $NODE_PORT_STATUS"
echo "  - LoadBalancer (9000): $LB_STATUS"
echo "  - ClusterIP: $CLUSTER_IP_STATUS"
echo "  - Public Access (VM:9000): $PUBLIC_STATUS"
echo "===================================================="
echo
echo "EXPECTED BEHAVIOR:"
echo "  - Without tunnel: Public access should FAIL (nginx can't reach LoadBalancer IP)"
echo "  - With tunnel: Public access should SUCCEED (nginx can reach LoadBalancer IP)"
echo "===================================================="
