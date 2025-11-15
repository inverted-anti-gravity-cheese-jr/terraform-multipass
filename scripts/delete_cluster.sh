#!/bin/sh

check_if_installed() {
    command -v $1 >/dev/null || { echo "Warning, '$1' not found. Please install it."; exit 1 ; }
}

check_if_installed multipass

multipass delete --purge ${NODE_NAME}
