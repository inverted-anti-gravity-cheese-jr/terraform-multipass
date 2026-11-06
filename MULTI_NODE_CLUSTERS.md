# Multi-Node Kubernetes Cluster Support

This document describes the new multi-node cluster functionality added to the terraform-multipass module.

## Overview

The module now supports creating multi-node Kubernetes clusters where nodes can automatically join existing clusters. This is achieved using the new `cluster_name` variable.

## Changes Made

### 1. New Variable: `cluster_name`

Added to `variables.tf`:

```hcl
variable "cluster_name" {
  description = "The name of the Kubernetes cluster. Nodes with the same cluster_name will form a multi-node cluster. If empty, each node is independent."
  type        = string
  default     = ""
}
```

### 2. Updated `main.tf`

Added `CLUSTER_NAME` to the environment variables passed to the shell script:

```hcl
resource "shell_script" "kubernetes_node" {
    # ... lifecycle_commands ...
    
    environment = {
        NODE_NAME = var.node_name
        NODE_MEM = var.node_mem
        NODE_CPU = var.node_cpu
        MULTIPASS_IMAGE = var.multipass_image
        ADDONS = local.kubernetes_addons
        CLUSTER_NAME = var.cluster_name
    }
}
```

### 3. Updated `scripts/create_cluster.sh`

Enhanced the script to support cluster joining:

- **Without `cluster_name`**: Creates independent clusters (original behavior)
- **With `cluster_name`**: 
  - First node with a given `cluster_name` creates a new cluster
  - Subsequent nodes with the same `cluster_name` automatically join the existing cluster

The script:
1. Checks if `CLUSTER_NAME` is provided
2. If yes, searches for existing nodes in the same cluster
3. If found, joins the cluster using MicroK8s `microk8s join` command
4. If not found, creates a new cluster

## Usage Examples

### Single Independent Cluster (Original Behavior)

```hcl
module "test_node" {
  source = "git::https://github.com/inverted-anti-gravity-cheese-jr/terraform-multipass.git"

  node_name = "test-node-1"
  node_cpu = 1
  node_mem = "1G"
  multipass_image = "25.04"
  addons = [ "cert-manager", "dashboard" ]
}
```

### Multi-Node Cluster

```hcl
# First node - creates the cluster
module "k8s_cluster" {
  source = "git::https://github.com/inverted-anti-gravity-cheese-jr/terraform-multipass.git"

  node_name      = "prod-k8s-node-1"
  node_cpu       = 2
  node_mem       = "4G"
  multipass_image = "25.04"
  cluster_name   = "production-cluster"
  addons         = [ "cert-manager", "dashboard", "ingress" ]
}

# Second node - joins the cluster
module "k8s_cluster_worker_1" {
  source = "git::https://github.com/inverted-anti-gravity-cheese-jr/terraform-multipass.git"

  node_name      = "prod-k8s-node-2"
  node_cpu       = 2
  node_mem       = "4G"
  multipass_image = "25.04"
  cluster_name   = "production-cluster"
  addons         = [] # Addons only needed on first node

  depends_on = [module.k8s_cluster]
}

# Third node - joins the cluster
module "k8s_cluster_worker_2" {
  source = "git::https://github.com/inverted-anti-gravity-cheese-jr/terraform-multipass.git"

  node_name      = "prod-k8s-node-3"
  node_cpu       = 2
  node_mem       = "4G"
  multipass_image = "25.04"
  cluster_name   = "production-cluster"
  addons         = [] # Addons only needed on first node

  depends_on = [module.k8s_cluster_worker_1]
}
```

## How It Works

### Cluster Formation Logic

1. **Node Discovery**: The script uses `multipass list` to find existing nodes with the same `cluster_name` prefix
2. **First Node**: When no existing nodes are found, it creates a new MicroK8s cluster
3. **Subsequent Nodes**: When existing nodes are found:
   - Gets the IP address of the first existing node
   - Uses MicroK8s `microk8s join` command to connect to the cluster
   - Waits for the node to be ready
   - Installs addons (only needed on the first node)

### Naming Convention

Nodes in the same cluster should follow a naming pattern where the `cluster_name` is a prefix:
- `production-cluster-node-1`
- `production-cluster-node-2`
- `production-cluster-node-3`

The script automatically detects nodes that start with the `cluster_name` followed by a hyphen.

## Important Notes

1. **Addons**: Only install addons on the first node (the one that creates the cluster). Addons are automatically replicated to other nodes in the cluster.

2. **Dependencies**: When creating multiple nodes in the same cluster, use `depends_on` to ensure proper ordering.

3. **Backward Compatibility**: The feature is fully backward compatible. Existing configurations without `cluster_name` will continue to work as before.

4. **MicroK8s**: This feature relies on MicroK8s' built-in clustering capabilities via the `microk8s join` command.

## Cleanup

To destroy a multi-node cluster:

```bash
terraform destroy
```

This will remove all nodes in the cluster. Note that MicroK8s will handle cluster member removal automatically.

## Example Files

See the `examples/multi-node-cluster/` directory for a complete working example.

## Troubleshooting

### Node Not Joining Cluster

If a node fails to join:

1. Check that all nodes have the same `cluster_name`
2. Verify network connectivity between nodes
3. Check MicroK8s status on the new node: `multipass exec <node-name> -- microk8s status`
4. Check MicroK8s logs: `multipass exec <node-name> -- journalctl -u snap.microk8s.daemon-kubelite -f`

### Token Issues

If join tokens expire, the script will automatically generate new ones using:
```bash
microk8s kubectl create token microk8s-user -n kube-system --duration=8760h
```

## Technical Details

### Script Flow

```
1. Check if CLUSTER_NAME is set
2. If yes:
   a. List existing nodes with same cluster_name prefix
   b. If nodes exist:
      i. Get IP of first node
      ii. Launch new VM
      iii. Install MicroK8s
      iv. Join cluster using microk8s join
      v. Wait for ready
      vi. Install addons
   c. If no nodes exist:
      i. Launch new VM
      ii. Install MicroK8s
      iii. Enable addons
3. If no CLUSTER_NAME:
   a. Original single-node behavior
```

### MicroK8s Join Command

The script uses MicroK8s' join command:
```bash
microk8s join <ip>:25000/<token> --worker
```

This connects the new node to the existing cluster as a worker node.

## Future Enhancements

Possible future improvements:
- Support for specifying control plane vs worker nodes
- Automatic load balancer configuration for multi-node clusters
- Node labels and taints configuration
- Cluster scaling operations
