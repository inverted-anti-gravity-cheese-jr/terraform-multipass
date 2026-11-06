#!/bin/sh

check_if_installed() {
    command -v $1 >/dev/null || { echo "Warning, '$1' not found. Please install it."; exit 1 ; }
}

check_if_installed multipass

# Delete the VM
multipass delete --purge ${NODE_NAME}

# Remove cluster data file if it exists
if [ -n "${CLUSTER_DATA_FILE}" ] && [ -f "${CLUSTER_DATA_FILE}" ]; then
    rm -f "${CLUSTER_DATA_FILE}"
fi
