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


# Get kubeconfig
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
