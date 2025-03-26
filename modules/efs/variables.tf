variable "namespace" {
  type = string
}

variable "security_group_nfs_id" {
  type = list(string)
}

variable "az_list" {
  type = list(string)
}

variable "private_ingress_subnet_id" {
  type = list(string)
}

