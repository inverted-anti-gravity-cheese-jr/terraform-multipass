# Multi-Node Kubernetes Cluster Example

This example demonstrates how to create a multi-node Kubernetes cluster using the terraform-multipass module.

## Overview

This configuration creates a 3-node Kubernetes cluster where:
- The first node creates the initial cluster
- The second and third nodes join the existing cluster automatically

## Usage

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Apply the configuration:
   ```bash
   terraform apply
   ```

3. Access your cluster using the kubeconfig from any node

## Cluster Structure

- **Cluster Name**: `production-cluster`
- **Nodes**:
  - `prod-k8s-node-1` (control plane + worker)
  - `prod-k8s-node-2` (worker)
  - `prod-k8s-node-3` (worker)

## Variables

- `cluster_name`: Identifies which cluster nodes should join (same value = same cluster)
- `node_name`: Unique name for each VM
- `node_cpu`: CPU allocation per node
- `node_mem`: Memory allocation per node
- `addons`: Only needed on the first node that creates the cluster

## Cleanup

```bash
terraform destroy
```

## Notes

- All nodes must use the same `cluster_name` to form a single cluster
- The first node with a given `cluster_name` creates the cluster
- Subsequent nodes with the same `cluster_name` automatically join the cluster
- Addons are only installed on the first node (control plane)
