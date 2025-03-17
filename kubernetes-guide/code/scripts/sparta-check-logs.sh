#!/bin/bash
# Script to check logs of Sparta app and database pods

# Source configuration
source ../config/config.env
REMOTE_SERVER="${REMOTE_USER}@${REMOTE_SERVER_IP}"

# Exit on error
set -e

echo "Retrieving logs from Sparta app and database pods..."

# Check if we can connect to the remote server
echo "Checking connection to remote server..."
ssh -o ConnectTimeout=5 $REMOTE_SERVER "echo Connection successful" || {
  echo "Error: Cannot connect to remote server. Please check the server address and your SSH configuration."
  exit 1
}

# Check logs of all sparta node pods
echo "=================================================="
echo "LOGS FROM SPARTA APP PODS:"
echo "=================================================="
ssh $REMOTE_SERVER "
  PODS=\$(kubectl get pods -l app=sparta-node -o jsonpath='{.items[*].metadata.name}')
  for POD in \$PODS; do
    echo \"\\n--------------------------------------------------\"
    echo \"Pod: \$POD\"
    echo \"--------------------------------------------------\"
    echo \"Init container logs (if available):\"
    kubectl logs \$POD -c wait-for-mongodb 2>/dev/null || echo \"No init container logs available\"
    echo \"\\nMain container logs:\"
    kubectl logs \$POD -c sparta-app
    echo \"\\nEnvironment variables:\"
    kubectl exec \$POD -c sparta-app -- env | grep -E 'DB_HOST|EXECUTE_NPM_INSTALL'
  done
"

# Check logs of database pod
echo "=================================================="
echo "LOGS FROM MONGODB POD:"
echo "=================================================="
ssh $REMOTE_SERVER "
  DB_POD=\$(kubectl get pods -l app=sparta-db -o jsonpath='{.items[0].metadata.name}')
  echo \"Pod: \$DB_POD\"
  kubectl logs \$DB_POD
  
  echo \"\\nChecking MongoDB status:\"
  kubectl exec \$DB_POD -- mongosh --eval 'db.stats()'
  
  echo \"\\nChecking existing collections:\"
  kubectl exec \$DB_POD -- mongosh --eval 'db.getMongo().getDBNames(); use posts; db.getCollectionNames()'
"

# Check network connectivity
echo "=================================================="
echo "CHECKING NETWORK CONNECTIVITY:"
echo "=================================================="
ssh $REMOTE_SERVER "
  APP_POD=\$(kubectl get pods -l app=sparta-node -o jsonpath='{.items[0].metadata.name}')
  echo \"Network connectivity from app pod to MongoDB:\"
  kubectl exec \$APP_POD -c sparta-app -- curl -s --connect-timeout 5 sparta-db-service:27017 || echo \"Connection failed, but this is normal for MongoDB raw TCP\"
  
  echo \"\\nTesting DNS resolution from app pod:\"
  kubectl exec \$APP_POD -c sparta-app -- nslookup sparta-db-service
"

echo "Log retrieval completed."
