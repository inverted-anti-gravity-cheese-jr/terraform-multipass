variable "node_name" {
  description = "The name of the Kubernetes node."
  type        = string
}

variable "node_mem" {
  description = "The memory allocation for the Kubernetes node."
  type        = string
}

variable "node_cpu" {
  description = "The CPU allocation for the Kubernetes node."
  type        = number
}

variable "multipass_image" {
  description = "The Multipass image to use for the Kubernetes node."
  type        = string
  default     = ""
}

variable "addons" {
  description = "A list of addons to install on the Kubernetes node."
  type        = list(string)
  default     = [ "cert-manager", "dashboard", "ingress", "prometheus" ]
}
