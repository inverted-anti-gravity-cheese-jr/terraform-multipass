terraform {
    required_providers {
        null = {
            source = "hashicorp/null"
            version = ">= 3.0.0"
        }
    }
}

locals {
  kubernetes_addons = join(" ", var.addons)
  cluster_data_file = "${path.module}/.cluster_data_${var.node_name}.json"
}

resource "null_resource" "kubernetes_node" {
    triggers = {
        node_name = var.node_name
        cluster_name = var.cluster_name
        always_run = timestamp()
    }

    lifecycle {
        ignore_changes = [triggers["always_run"]]
    }

    provisioner "local-exec" {
        when    = create
        command = <<EOT
            ${path.module}/scripts/create_cluster.sh
        EOT
        environment = {
            NODE_NAME = var.node_name
            NODE_MEM = var.node_mem
            NODE_CPU = var.node_cpu
            MULTIPASS_IMAGE = var.multipass_image
            ADDONS = local.kubernetes_addons
            CLUSTER_NAME = var.cluster_name
            CLUSTER_DATA_FILE = local.cluster_data_file
        }
    }

    provisioner "local-exec" {
        when    = destroy
        command = <<EOT
            ${path.module}/scripts/delete_cluster.sh
        EOT
        environment = {
            NODE_NAME = self.triggers.node_name
            CLUSTER_DATA_FILE = local.cluster_data_file
        }
    }

    provisioner "local-exec" {
        when    = read
        command = <<EOT
            ${path.module}/scripts/read_cluster.sh
        EOT
        environment = {
            NODE_NAME = var.node_name
            CLUSTER_DATA_FILE = local.cluster_data_file
        }
    }
}

# Read cluster data from file
locals {
  cluster_data = jsondecode(fileexists(local.cluster_data_file) ? file(local.cluster_data_file) : "{}")
}

output "serverIp" {
    value = lookup(local.cluster_data, "serverIp", "")
}

output "kubeconfServerName" {
    value = lookup(local.cluster_data, "serverName", "")
}

output "kubeconfCaData" {
    value = lookup(local.cluster_data, "caData", "")
    sensitive = true
}

output "kubeconfUser" {
    value = lookup(local.cluster_data, "userName", "")
}

output "kubeconfUserCaData" {
    value = lookup(local.cluster_data, "userCaData", "")
    sensitive = true
}

output "kubeconfUserKeyData" {
    value = lookup(local.cluster_data, "userKeyData", "")
    sensitive = true
}
