#!/bin/sh

check_if_installed() {
    command -v $1 >/dev/null || { echo "Warning, '$1' not found. Please install it."; exit 1 ; }
}

exec_in_vm() {
    multipass exec ${NODE_NAME} -- sh -c "$*"
}

get_kube_config() {
    exec_in_vm "sudo microk8s kubectl config view --raw | yq '$1'"
}

check_if_installed multipass
check_if_installed jq

# Check if we should join an existing cluster
if [ -n "${CLUSTER_NAME}" ]; then
    # Find existing nodes in the same cluster
    EXISTING_NODES=$(multipass list --format json | jq -r ".list[] | select(.name != \"${NODE_NAME}\" and .name | startswith(\"${CLUSTER_NAME}-\")) | .name")
    
    if [ -n "$EXISTING_NODES" ]; then
        # Join existing cluster
        FIRST_NODE=$(echo "$EXISTING_NODES" | head -n 1)
        FIRST_NODE_IP=$(multipass info --format json $FIRST_NODE | jq -r ".info."$FIRST_NODE".ipv4")
        
        echo "Joining node ${NODE_NAME} to existing cluster via node ${FIRST_NODE} (${FIRST_NODE_IP})"
        
        # Launch VM
        multipass launch --name ${NODE_NAME} --memory ${NODE_MEM} --cpus ${NODE_CPU} ${MULTIPASS_IMAGE}
        
        # Install dependencies
        exec_in_vm sudo apt update
        exec_in_vm sudo apt install -y jq yq
        
        # Install MicroK8s
        exec_in_vm sudo snap install microk8s --classic
        
        # Get join token from existing cluster and join
        JOIN_TOKEN=$(exec_in_vm "sudo microk8s add-node --token-only 2>/dev/null || echo ''")
        if [ -z "$JOIN_TOKEN" ]; then
            # If token command fails, generate one
            JOIN_TOKEN=$(exec_in_vm "sudo microk8s kubectl create token microk8s-user -n kube-system --duration=8760h")
        fi
        
        # Join the cluster
        exec_in_vm "sudo microk8s join ${FIRST_NODE_IP}:25000/${JOIN_TOKEN} --worker"
        
        # Wait for node to be ready
        exec_in_vm "sudo microk8s status --wait-ready"
        
        # Enable addons (only if not empty)
        if [ -n "$ADDONS" ]; then
            exec_in_vm sudo microk8s enable $ADDONS
        fi
    else
        # Create new cluster (first node in cluster)
        echo "Creating new cluster with node ${NODE_NAME}"
        multipass launch --name ${NODE_NAME} --memory ${NODE_MEM} --cpus ${NODE_CPU} ${MULTIPASS_IMAGE}
        
        exec_in_vm sudo apt update
        exec_in_vm sudo apt install -y jq yq
        exec_in_vm sudo snap install microk8s --classic
        if [ -n "$ADDONS" ]; then
            exec_in_vm sudo microk8s enable $ADDONS
        fi
    fi
else
    # Original behavior: create independent cluster
    multipass launch --name ${NODE_NAME} --memory ${NODE_MEM} --cpus ${NODE_CPU} ${MULTIPASS_IMAGE}
    
    exec_in_vm sudo apt install -y jq yq
    exec_in_vm sudo snap install microk8s --classic
    if [ -n "$ADDONS" ]; then
        exec_in_vm sudo microk8s enable $ADDONS
    fi
fi

SERVER_IP="$(multipass info --format json $NODE_NAME | jq ".info.\"$NODE_NAME\".ipv4")"
KUBECONF_SERVER_NAME="$(get_kube_config '.clusters[0].cluster.server')"
KUBECONF_CA_DATA="$(get_kube_config '.clusters[0].cluster."certificate-authority-data"')"
KUBECONF_USER="$(get_kube_config '.users[0].name')"
KUBECONF_USER_CA="$(get_kube_config '.users[0].user."client-certificate-data"')"
KUBECONF_USER_KEY="$(get_kube_config '.users[0].user."client-key-data"')"

# Write cluster data to file
cat > "${CLUSTER_DATA_FILE}" <<EOF
{
  "serverIp": $SERVER_IP,
  "serverName": $KUBECONF_SERVER_NAME,
  "caData": $KUBECONF_CA_DATA,
  "userName": $KUBECONF_USER,
  "userCaData": $KUBECONF_USER_CA,
  "userKeyData": $KUBECONF_USER_KEY
}
EOF
