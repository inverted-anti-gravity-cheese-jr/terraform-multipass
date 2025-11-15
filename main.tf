terraform {
    required_providers {
        shell = {
        source = "scottwinkler/shell"
        version = "1.7.7"
        }
    }
}

locals {
  kubernetes_addons = join(" ", var.addons)
}

resource "shell_script" "kubernetes_node" {
    lifecycle_commands {
        create = file("${path.module}/scripts/create_cluster.sh")
        read   = file("${path.module}/scripts/read_cluster.sh")
        delete = file("${path.module}/scripts/delete_cluster.sh")
    }

    environment = {
        NODE_NAME = var.node_name
        NODE_MEM = var.node_mem
        NODE_CPU = var.node_cpu
        MULTIPASS_IMAGE = var.multipass_image
        ADDONS = local.kubernetes_addons
    }
}

output "serverIp" {
    value = resource.shell_script.kubernetes_node.output["serverIp"]
}

output "kubeconfServerName" {
    value = resource.shell_script.kubernetes_node.output["serverName"]
}

output "kubeconfCaData" {
    value = resource.shell_script.kubernetes_node.output["caData"]
}

output "kubeconfUser" {
    value = resource.shell_script.kubernetes_node.output["userName"]
}

output "kubeconfUserCaData" {
    value = resource.shell_script.kubernetes_node.output["userCaData"]
}

output "kubeconfUserKeyData" {
    value = resource.shell_script.kubernetes_node.output["userKeyData"]
}
