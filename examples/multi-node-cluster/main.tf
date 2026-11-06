module "k8s_cluster" {
  source = "git::https://github.com/inverted-anti-gravity-cheese-jr/terraform-multipass.git"

  # First node - creates the cluster
  node_name      = "prod-k8s-node-1"
  node_cpu       = 2
  node_mem       = "4G"
  multipass_image = "25.04"
  cluster_name   = "production-cluster"
  addons         = [ "cert-manager", "dashboard", "ingress" ]
}

module "k8s_cluster_worker_1" {
  source = "git::https://github.com/inverted-anti-gravity-cheese-jr/terraform-multipass.git"

  # Second node - joins the cluster
  node_name      = "prod-k8s-node-2"
  node_cpu       = 2
  node_mem       = "4G"
  multipass_image = "25.04"
  cluster_name   = "production-cluster"
  addons         = [] # Addons only needed on first node

  depends_on = [module.k8s_cluster]
}

module "k8s_cluster_worker_2" {
  source = "git::https://github.com/inverted-anti-gravity-cheese-jr/terraform-multipass.git"

  # Third node - joins the cluster
  node_name      = "prod-k8s-node-3"
  node_cpu       = 2
  node_mem       = "4G"
  multipass_image = "25.04"
  cluster_name   = "production-cluster"
  addons         = [] # Addons only needed on first node

  depends_on = [module.k8s_cluster_worker_1]
}

# Output the cluster information
output "cluster_nodes" {
  value = {
    node1_ip   = module.k8s_cluster.serverIp
    node1_name = module.k8s_cluster.kubeconfServerName
    node2_ip   = module.k8s_cluster_worker_1.serverIp
    node2_name = module.k8s_cluster_worker_1.kubeconfServerName
    node3_ip   = module.k8s_cluster_worker_2.serverIp
    node3_name = module.k8s_cluster_worker_2.kubeconfServerName
  }
}
