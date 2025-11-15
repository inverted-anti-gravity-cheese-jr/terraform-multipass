# Kubernetes Node Setup
This repo provides a Terraform (OpenTofu) module to create, read, and delete a Kubernetes nodes using multipass.

# How to use it?
## Basic example

```terraform
module "test_node" {
  source = "git::https://github.com/inverted-anti-gravity-cheese-jr/terraform-multipass.git"

  node_name = "test-node-1"
  node_cpu = 1
  node_mem = "1G"
  multipass_image = "25.04"
  addons = [ "cert-manager", "dashboard", "ingress", "prometheus" ]
}
```

## Variables

| Variable | Description   | Type    | Default Value          | Required?  | Example         |
|----------|---------------|---------|-----------------------|-----------|---------------------------------|
| node_name | The name of a Kubernetes node (multipass VM name). |  string   |  none |   Yes |  "test-node" |
| node_cpu | CPU allocation for the k8s Node | number | none | Yes | 1 |
| node_mem | Memory allocation to be allocated on a particular machine (e.g., “4096m”). | string |  none | Yes | "2G" |
| multipass_image | The Multipass image that is used for the Kubernetes node such as Ubuntu, Fedora etc. Use `multipass find` to find available images. | string | (empty) | No | `25.04` |
| addons | A list of additional tools or services to be installed on a particular machine. |  array | `["cert-manager", "dashboard","ingress" ,  "prometheus"]` | No | `[“nginx”, ‘pause’]` |
