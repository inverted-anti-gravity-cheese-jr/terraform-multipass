# Terraform Multipass Kubernetes Module

A self-contained Terraform module for creating and managing Kubernetes clusters using Multipass and MicroK8s. **No external providers needed!** Uses only Terraform's built-in `null` provider.

## Features

✅ **No external dependencies** - Uses only built-in Terraform providers  
✅ **Multi-node clusters** - Nodes with same `cluster_name` automatically form a cluster  
✅ **MicroK8s** - Lightweight Kubernetes distribution  
✅ **Self-contained** - All logic in module, no external scripts needed  
✅ **Backward compatible** - Existing configurations work unchanged

## Quick Start

### Single Node (Original Behavior)

```hcl
module "k8s_node" {
  source = "git::https://github.com/inverted-anti-gravity-cheese-jr/terraform-multipass.git"

  node_name      = "my-node"
  node_cpu       = 2
  node_mem       = "4G"
  multipass_image = "25.04"
  addons         = ["cert-manager", "dashboard"]
}
```

### Multi-Node Cluster

```hcl
# First node - creates cluster
module "k8s_cluster" {
  source = "git::https://github.com/inverted-anti-gravity-cheese-jr/terraform-multipass.git"

  node_name    = "prod-node-1"
  node_cpu     = 2
  node_mem     = "4G"
  multipass_image = "25.04"
  cluster_name = "production"  # Same cluster_name = same cluster
  addons       = ["cert-manager", "dashboard"]
}

# Second node - joins cluster
module "k8s_worker_1" {
  source = "git::https://github.com/inverted-anti-gravity-cheese-jr/terraform-multipass.git"

  node_name    = "prod-node-2"
  node_cpu     = 2
  node_mem     = "4G"
  multipass_image = "25.04"
  cluster_name = "production"  # Joins existing cluster
  addons       = []  # Addons only needed on first node

  depends_on = [module.k8s_cluster]
}
```

## Variables

| Variable | Description | Type | Required | Default |
|----------|-------------|------|----------|---------|
| `node_name` | Name of the VM/node | string | ✅ | - |
| `node_cpu` | CPU cores for VM | number | ✅ | - |
| `node_mem` | Memory for VM (e.g., "4G") | string | ✅ | - |
| `multipass_image` | Multipass image (use `multipass find`) | string | ❌ | "" |
| `addons` | MicroK8s addons to enable | list(string) | ❌ | `["cert-manager", "dashboard", "ingress", "prometheus"]` |
| `cluster_name` | Cluster name for multi-node clusters | string | ❌ | "" (creates independent cluster) |

## Outputs

| Output | Description |
|--------|-------------|
| `serverIp` | IP address of the node |
| `kubeconfServerName` | Kubernetes API server URL |
| `kubeconfCaData` | CA certificate data (sensitive) |
| `kubeconfUser` | Username for kubeconfig |
| `kubeconfUserCaData` | User CA certificate (sensitive) |
| `kubeconfUserKeyData` | User private key (sensitive) |

## How It Works

### Provider Architecture

- Uses Terraform's built-in `null` provider (no installation needed)
- Uses `local-exec` provisioners to run shell scripts
- Cluster data persisted to local files for state management

### Multi-Node Clusters

1. **First node** with a `cluster_name` creates a new MicroK8s cluster
2. **Subsequent nodes** with same `cluster_name` automatically join via `microk8s join`
3. All nodes form a single Kubernetes cluster

### Cleanup

```bash
terraform destroy
```

## Architecture

```
Terraform Configuration
  ↓ (uses module)
Terraform Multipass Module
  ├─ main.tf (null provider + local-exec)
  ├─ variables.tf (input variables)
  ├─ outputs.tf (output values)
  └─ scripts/
      ├─ create_cluster.sh (creates VM + cluster)
      ├─ read_cluster.sh (reads cluster state)
      └─ delete_cluster.sh (cleans up)
```

## Comparison: Old vs New

### Before (Required External Provider)
```hcl
terraform {
  required_providers {
    shell = {
      source = "scottwinkler/shell"
      version = "1.7.7"
    }
  }
}

resource "shell_script" "kubernetes_node" { ... }
```

### After (Self-Contained)
```hcl
terraform {
  required_providers {
    null = {
      source = "hashicorp/null"
      version = ">= 3.0.0"
    }
  }
}

resource "null_resource" "kubernetes_node" {
  provisioner "local-exec" { when = create }  # Creates cluster
  provisioner "local-exec" { when = destroy } # Deletes cluster
}
```

## Examples

See `examples/multi-node-cluster/` for a complete working example.

## Troubleshooting

**Error: "Invalid reference from destroy provisioner"**
- Cause: Using `source = "git::..."` loads old code from GitHub
- Fix: Use `source = "./"` for local testing or push changes to GitHub

**Error: "Invalid 'when' keyword"**
- Cause: Old code in `.terraform/modules/`
- Fix: Clear cache: `rm -rf .terraform/`

**Node not joining cluster**
- Check: All nodes have same `cluster_name`
- Check: Network connectivity between nodes
- Check: `microk8s status` on all nodes

## Notes

- Addons only needed on first node (control plane)
- MicroK8s handles cluster state replication automatically
- Cluster data files stored in module directory (`.cluster_data_*.json`)
- Sensitive outputs automatically marked as sensitive

## License

MIT License - Free to use and modify

---

**Need help?** Check the examples or open an issue on GitHub.
